# frozen_string_literal: true
require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "open3"
require "json"
require "yaml"

class RepositoryWorkflowTest < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir("rage-repository-test-")
    @root = File.join(@tmp, "rage")
    @remote = File.join(@tmp, "remote.git")
    @publisher = File.join(@tmp, "publisher")
    @repo = File.join(@root, ".codex/specs-repository")
    FileUtils.mkdir_p(File.join(@root, ".codex"))
    %w[bin hooks].each { |dir| FileUtils.cp_r(File.expand_path("../#{dir}", __dir__), File.join(@root, ".codex", dir)) }
    git(@tmp, "init", "--bare", @remote)
    git(@tmp, "clone", @remote, @publisher)
    git(@publisher, "checkout", "-b", "main")
    git(@publisher, "config", "user.name", "Harness Fixture")
    git(@publisher, "config", "user.email", "fixture@example.invalid")
    write("AGENTS.md", "Repository instructions\n")
    write("templates/feature.md", "---\ntitle: Feature name\nstatus: draft\n---\n# Feature name\n")
    write("templates/task.md", "---\nstatus: todo\n---\n")
    write("templates/adr.md", "---\nstatus: proposed\n---\n")
    write("features/example/spec.md", "---\nstatus: implementation\n---\nFeature\n")
    write("features/example/tasks/01-work.md", "---\nstatus: todo\n---\nWork\n")
    write("features/example/adr/001-choice.md", "---\nstatus: accepted\n---\nChoice\n")
    publish
    command("setup")
    command("activate", "example")
    command("select-task", "01-work.md")
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def git(dir, *args)
    output, error, status = Open3.capture3("git", "-C", dir, *args)
    raise error unless status.success?
    output
  end

  def write(path, text)
    target = File.join(@publisher, path)
    FileUtils.mkdir_p(File.dirname(target))
    File.write(target, text)
  end

  def publish
    git(@publisher, "add", ".")
    git(@publisher, "commit", "-m", "Fixture revision")
    git(@publisher, "push", "origin", "main")
  end

  # Substitute a local bare remote only in each test process. Production code
  # always uses the fixed GitHub source; fetch/fast-forward are real Git calls.
  def invoke(script, args = [], input = "")
    runner = 'require "./.codex/bin/spec_repository"; SpecRepository.send(:remove_const, :URL); SpecRepository.const_set(:URL, ARGV.shift); script = ARGV.shift; if script.end_with?("feature_state.rb"); require File.expand_path(script); FeatureState.new.run(ARGV); else; load script; end'
    Open3.capture3("ruby", "-e", runner, @remote, script, *args, stdin_data: input, chdir: @root)
  end

  def command(*args, success: true)
    output, error, result = invoke(".codex/bin/feature_state.rb", args)
    assert_equal success, result.success?, "#{args.inspect}: #{output} #{error}"
    output + error
  end

  def state
    YAML.safe_load(File.read(File.join(@root, ".codex/features/example/state.yml")))
  end

  def hook(name, path)
    input = {"cwd" => @root, "hook_event_name" => "PreToolUse", "tool_name" => "apply_patch",
      "tool_input" => {"command" => "*** Begin Patch\n*** Update File: #{path}\n@@\n-a\n+b\n*** End Patch\n"}}
    output, error, result = invoke(".codex/hooks/#{name}.rb", [], JSON.generate(input))
    assert result.success?, error
    JSON.parse(output)
  end

  def test_lifecycle_and_gap_does_not_change_canonical_status
    command("approve")
    command("begin-implementation")
    assert_equal "implementing", state["phase"]
    report = File.join(@root, ".codex/features/example/evidence/gap.md")
    File.write(report, "Missing requirement\n")
    command("report-gap", report)
    command("verify", success: false)
    assert_equal "deny", hook("phase_write_guard", "lib/rage.rb").dig("hookSpecificOutput", "permissionDecision")
    command("resume")
    command("verify")
    assert_equal "verified", state["phase"]
    assert_equal "", git(@repo, "status", "--porcelain").strip
    assert_includes File.read(File.join(@repo, "features/example/tasks/01-work.md")), "status: todo"
    command("reopen", "Record merged implementation evidence")
    assert_equal "01-work.md", state.dig("last_verification", "task")
  end

  def test_upstream_adr_change_invalidates_approval
    command("approve")
    write("features/example/adr/001-choice.md", "---\nstatus: accepted\n---\nRevised choice\n")
    publish
    assert_includes command("begin-implementation", success: false), "changed"
    assert_equal "approved", state["phase"]
    command("reopen", "Inspect revised ADR")
    command("refresh")
    command("approve")
    command("begin-implementation")
  end

  def test_draft_and_done_task_cannot_be_implemented
    write("features/example/spec.md", "---\nstatus: draft\n---\nFeature\n")
    publish
    assert_includes command("approve", success: false), "status: implementation"
    write("features/example/spec.md", "---\nstatus: implementation\n---\nFeature\n")
    write("features/example/tasks/01-work.md", "---\nstatus: done\n---\nWork\n")
    publish
    assert_includes command("approve", success: false), "not todo"
  end

  def test_dirty_checkout_and_unavailable_remote_are_not_overwritten
    command("approve")
    file = File.join(@repo, "features/example/tasks/01-work.md")
    File.write(file, "Local draft\n")
    assert_includes command("begin-implementation", success: false), "local changes"
    assert_equal "Local draft\n", File.read(file)
    command("reopen")
    # After saving the draft separately and restoring the fixture content,
    # a missing remote must not produce an offline implementation approval.
    File.write(file, File.read(File.join(@publisher, "features/example/tasks/01-work.md")))
    FileUtils.mv(@remote, @remote + "-unavailable")
    assert_includes command("sync", success: false), "fetch failed"
  end

  def test_hooks_protect_tasks_and_allow_canonical_drafting
    file = ".codex/specs-repository/features/example/tasks/01-work.md"
    assert_equal({}, hook("phase_write_guard", file))
    assert_equal "deny", hook("phase_write_guard", "lib/rage.rb").dig("hookSpecificOutput", "permissionDecision")
    command("approve")
    command("begin-implementation")
    assert_equal "deny", hook("phase_write_guard", file).dig("hookSpecificOutput", "permissionDecision")
    File.write(File.join(@repo, file.delete_prefix(".codex/specs-repository/")), "Changed task\n")
    assert_equal "deny", hook("specification_state_guard", "lib/rage.rb").dig("hookSpecificOutput", "permissionDecision")
    input = {"cwd" => @root, "hook_event_name" => "PreToolUse", "tool_name" => "Bash",
      "tool_input" => {"command" => "ruby .codex/bin/feature_state.rb reopen inspect-changes"}}
    output, error, result = invoke(".codex/hooks/specification_state_guard.rb", [], JSON.generate(input))
    assert result.success?, error
    assert_equal({}, JSON.parse(output), "Stale approval must not block recovery commands")
  end

  def test_create_uses_remote_template_and_legacy_state_is_preserved
    command("create", "new-feature", "Title: quoted")
    text = File.read(File.join(@repo, "features/new-feature/spec.md"))
    assert_includes text, 'title: "Title: quoted"'
    refute File.exist?(File.join(@root, ".codex/features/new-feature/SPEC.md"))
    legacy = File.join(@root, ".codex/features/legacy/state.yml")
    FileUtils.mkdir_p(File.dirname(legacy))
    File.write(legacy, "version: 1\n")
    assert_includes command("create", "legacy", success: false), "Legacy"
    refute File.exist?(File.join(@repo, "features/legacy"))
    assert_equal "version: 1\n", File.read(legacy)
  end
end
