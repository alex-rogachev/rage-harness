# frozen_string_literal: true

require "digest"
require "json"
require "yaml"
require "shellwords"
require_relative "../bin/spec_repository"

module RageHarnessHook
  ROOT = File.expand_path("../..", __dir__)
  FEATURES_DIR = File.join(ROOT, ".codex", "features")
  CURRENT_PATH = File.join(FEATURES_DIR, "current")

  module_function

  def input
    JSON.parse($stdin.read)
  rescue JSON::ParserError => error
    warn "invalid hook input: #{error.message}"
    exit 1
  end

  def active
    return nil unless File.file?(CURRENT_PATH)

    slug = File.read(CURRENT_PATH).strip
    raise "Invalid active feature pointer" unless /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/.match?(slug)

    directory = File.join(FEATURES_DIR, slug)
    state_path = File.join(directory, "state.yml")
    state = YAML.safe_load(File.read(state_path), aliases: false) || {}
    raise "Legacy local state: migrate using WORKFLOW_REFERENCE.md" unless state["version"] == 2
    repository = SpecRepository.new(ROOT)
    spec_directory = repository.feature(slug)
    spec_path = File.join(spec_directory, "spec.md")
    raise "Missing canonical specification" unless File.file?(spec_path)
    {
      slug: slug,
      directory: directory,
      state_path: state_path,
      spec_path: spec_path,
      spec_directory: spec_directory,
      repository: repository,
      state: state,
      digest: repository.digest
    }
  rescue StandardError => error
    warn "Rage specification state unavailable: #{error.message}. Repair or migrate local state before continuing."
    exit 2
  end

  # Only standalone helper invocations bypass the editing gates; shell chains
  # and substitutions are not helper commands.
  def helper_call?(input)
    return false unless input["tool_name"] == "Bash"
    command = input.fetch("tool_input", {}).fetch("command", "")
    return false if command.match?(/[;&|><`\n$]/)
    words = Shellwords.split(command)
    words.length >= 3 && File.basename(words[0]) == "ruby" &&
      canonical_path(File.expand_path(words[1], input["cwd"] || ROOT)) == canonical_path(File.join(ROOT, ".codex/bin/feature_state.rb"))
  rescue ArgumentError
    false
  end

  def atomic_write(path, content)
    temporary = "#{path}.tmp-#{Process.pid}"
    File.write(temporary, content)
    File.rename(temporary, path)
  ensure
    File.delete(temporary) if temporary && File.exist?(temporary)
  end

  def write_state(active)
    atomic_write(active.fetch(:state_path), YAML.dump(active.fetch(:state)))
  end

  def deny(reason)
    puts JSON.generate(
      "hookSpecificOutput" => {
        "hookEventName" => "PreToolUse",
        "permissionDecision" => "deny",
        "permissionDecisionReason" => reason
      }
    )
  end

  def context(event, text)
    puts JSON.generate(
      "hookSpecificOutput" => {
        "hookEventName" => event,
        "additionalContext" => text
      }
    )
  end

  def allow
    puts "{}"
  end

  def inside?(path, directory)
    expanded_path = canonical_path(path)
    expanded_directory = canonical_path(directory)
    expanded_path == expanded_directory || expanded_path.start_with?("#{expanded_directory}#{File::SEPARATOR}")
  end

  def canonical_path(path)
    expanded = File.expand_path(path, ROOT)
    return File.realpath(expanded) if File.exist?(expanded)
    File.join(canonical_path(File.dirname(expanded)), File.basename(expanded))
  end

  def relative(path)
    File.expand_path(path).delete_prefix("#{ROOT}#{File::SEPARATOR}")
  end
end
