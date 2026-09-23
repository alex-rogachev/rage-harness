#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "pathname"
require "open3"
require "time"

force = ARGV.delete("--force")
target = File.expand_path(ARGV.shift || Dir.pwd)
abort "Usage: ruby install.rb [--force] /absolute/path/to/rage" unless ARGV.empty?

required = %w[ARCHITECTURE.md CONTRIBUTING.md rage.gemspec .git]
missing = required.reject { |entry| File.exist?(File.join(target, entry)) }
unless missing.empty?
  abort "Target does not look like a Rage checkout; missing: #{missing.join(", ")}"
end

payload = File.expand_path("payload", __dir__)
abort "Missing installer payload at #{payload}" unless Dir.exist?(payload)

files = Dir.glob(File.join(payload, "**", "*"), File::FNM_DOTMATCH)
  .reject { |path| %w[. ..].include?(File.basename(path)) || File.directory?(path) }

obsolete = %w[
  .codex/bin/feature_state.rb
  .codex/hooks/completion_gate.rb
  .codex/hooks/phase_write_guard.rb
  .codex/hooks/session_resume.rb
  .codex/hooks/specification_state_guard.rb
  .codex/hooks/support.rb
]
obsolete_existing = obsolete.select { |relative| File.file?(File.join(target, relative)) }

conflicts = files.each_with_object([]) do |source, found|
  relative = Pathname.new(source).relative_path_from(Pathname.new(payload)).to_s
  destination = File.join(target, relative)
  found << relative if File.file?(destination) && File.binread(destination) != File.binread(source)
end

if conflicts.any? && !force
  abort <<~MESSAGE
    Refusing to overwrite differing local files:
    #{conflicts.map { |path| "  - #{path}" }.join("\n")}

    Merge them manually, or rerun with --force only if replacement is intentional.
  MESSAGE
end

if conflicts.any? || obsolete_existing.any?
  backup = File.join(target, ".codex", "harness-backups", "#{Time.now.utc.strftime('%Y%m%dT%H%M%S')}-#{Process.pid}")
  (conflicts + obsolete_existing).uniq.each do |relative|
    destination = File.join(backup, relative)
    FileUtils.mkdir_p(File.dirname(destination))
    FileUtils.cp(File.join(target, relative), destination)
  end
  puts "Saved replaced harness files to #{backup}."
end

files.each do |source|
  relative = Pathname.new(source).relative_path_from(Pathname.new(payload)).to_s
  destination = File.join(target, relative)
  FileUtils.mkdir_p(File.dirname(destination))
  FileUtils.cp(source, destination)
end

obsolete_existing.each { |relative| FileUtils.rm_f(File.join(target, relative)) }

git_path, git_error, git_result = Open3.capture3("git", "-C", target, "rev-parse", "--git-path", "info/exclude")
abort "Cannot locate local Git excludes: #{git_error}" unless git_result.success?
exclude_path = File.expand_path(git_path.strip, target)
FileUtils.mkdir_p(File.dirname(exclude_path))
existing = File.exist?(exclude_path) ? File.read(exclude_path) : ""
patterns = ["/.agents/", "/.codex/", "/AGENTS.local.md"]
missing_patterns = patterns.reject { |pattern| existing.lines.map(&:strip).include?(pattern) }

if missing_patterns.any?
  addition = +""
  addition << "\n" unless existing.empty? || existing.end_with?("\n\n")
  addition << "# Local Codex harness and separate Rage specification checkout.\n"
  addition << missing_patterns.join("\n")
  addition << "\n"
  File.open(exclude_path, "a") { |file| file.write(addition) }
end

puts "Installed #{files.length} harness files into #{target}."
puts "Updated #{exclude_path}." if missing_patterns.any?
puts "Next: run ruby .codex/bin/spec_workflow.rb setup from Rage and read .codex/WORKFLOW_REFERENCE.md."
