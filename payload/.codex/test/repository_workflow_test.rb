# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "open3"
require "yaml"

class RepositoryWorkflowTest < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir("rage-repository-test-")
    @root = File.join(@tmp, "rage")
    @remote = File.join(@tmp, "remote.git")
    @publisher = File.join(@tmp, "publisher")
    @repo = File.join(@root, ".codex/specs-repository")
    FileUtils.mkdir_p(File.join(@root, ".codex"))
    FileUtils.cp_r(File.expand_path("../bin", __dir__), File.join(@root, ".codex/bin"))

    git(@tmp, "init", "--bare", @remote)
    git(@tmp, "clone", @remote, @publisher)
    git(@publisher, "checkout", "-b", "main")
    git(@publisher, "config", "user.name", "Harness Fixture")
    git(@publisher, "config", "user.email", "fixture@example.invalid")
    write("AGENTS.md", "Repository instructions\n")
    write("templates/feature.md", "---\ntitle: Feature name\n---\n# Feature name\n")
    write("templates/task.md", "---\nstatus: draft\n---\n")
    write("templates/adr.md", "---\nstatus: proposed\n---\n")
    write("features/example/spec.md", "---\ntitle: Example\n---\nFeature\n")
    write("features/example/tasks/01-ready.md", "---\nstatus: ready-for-development\n---\nReady\n")
    write("features/example/tasks/02-draft.md", "---\nstatus: draft\n---\nDraft\n")
    write("features/example/tasks/03-done.md", "---\nstatus: done\n---\nDone\n")
    publish
    command("setup")
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def git(directory, *args)
    output, error, status = Open3.capture3("git", "-C", directory, *args)
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

  def invoke(script, args = [])
    runner = 'require "./.codex/bin/spec_repository"; SpecRepository.send(:remove_const, :URL); SpecRepository.const_set(:URL, ARGV.shift); require File.expand_path(ARGV.shift); SpecWorkflow.new.run(ARGV)'
    Open3.capture3("ruby", "-e", runner, @remote, script, *args, chdir: @root)
  end

  def command(*args, success: true)
    output, error, result = invoke(".codex/bin/spec_workflow.rb", args)
    assert_equal success, result.success?, "#{args.inspect}: #{output} #{error}"
    output + error
  end

  def test_ready_task_passes_published_gate_without_parent_status
    output = command("check-ready", "features/example/tasks/01-ready.md")
    data = YAML.safe_load(output, aliases: false)
    assert_equal "ready-for-development", data["task_status"]
    assert_equal git(@repo, "rev-parse", "HEAD").strip, data["specification_commit"]
    refute File.exist?(File.join(@root, ".codex/features"))
  end

  def test_draft_and_done_tasks_do_not_pass_ready_gate
    assert_includes command("check-ready", "features/example/tasks/02-draft.md", success: false), "got: draft"
    assert_includes command("check-ready", "features/example/tasks/03-done.md", success: false), "got: done"
  end

  def test_status_reports_task_and_checkout_without_local_state
    data = YAML.safe_load(command("status", "features/example/tasks/02-draft.md"), aliases: false)
    assert_equal "features/example/tasks/02-draft.md", data["task"]
    assert_equal "draft", data["task_status"]
    assert_equal "", data["checkout_changes"]
  end

  def test_changed_published_task_is_used_after_sync
    write("features/example/tasks/02-draft.md", "---\nstatus: ready-for-development\n---\nReady now\n")
    publish
    output = command("check-ready", "features/example/tasks/02-draft.md")
    assert_includes output, "ready-for-development"
  end

  def test_dirty_checkout_and_unavailable_remote_block_ready_check
    file = File.join(@repo, "features/example/tasks/01-ready.md")
    File.write(file, "Local draft\n")
    assert_includes command("check-ready", "features/example/tasks/01-ready.md", success: false), "local changes"
    assert_equal "Local draft\n", File.read(file)

    File.write(file, File.read(File.join(@publisher, "features/example/tasks/01-ready.md")))
    FileUtils.mv(@remote, @remote + "-unavailable")
    assert_includes command("sync", success: false), "fetch failed"
  end

  def test_create_uses_feature_template_without_local_state
    command("create", "new-feature", "Title: quoted")
    text = File.read(File.join(@repo, "features/new-feature/spec.md"))
    assert_includes text, 'title: "Title: quoted"'
    refute_includes text, "status:"
    refute File.exist?(File.join(@root, ".codex/features"))
  end

  def test_task_path_must_be_repository_relative_and_canonical
    assert_includes command("status", "01-ready.md", success: false), "repository-relative task path"
    assert_includes command("status", "features/example/spec.md", success: false), "repository-relative task path"
  end
end
