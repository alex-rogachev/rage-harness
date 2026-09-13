#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "support"

input = RageHarnessHook.input
if RageHarnessHook.helper_call?(input)
  RageHarnessHook.allow
  exit
end
active = RageHarnessHook.active
unless active
  RageHarnessHook.allow
  exit
end

state = active.fetch(:state)
phase = state["phase"]
unless %w[draft approved implementing verified].include?(phase)
  RageHarnessHook.deny("The active feature state is invalid. Repair state.yml before editing.")
  exit
end

tool_name = input["tool_name"].to_s
tool_input = input["tool_input"].is_a?(Hash) ? input["tool_input"] : {}
command = tool_input["command"].to_s

if tool_name == "apply_patch"
  paths = command.scan(/^\*\*\* (?:Add|Update|Delete) File: (.+)$/).flatten
  paths.concat(command.scan(/^\*\*\* Move to: (.+)$/).flatten)

  if paths.empty?
    RageHarnessHook.deny("Could not determine the files in this patch while the feature workflow is active.")
    exit
  end

  absolute_paths = paths.map { |path| File.expand_path(path.strip, input["cwd"] || RageHarnessHook::ROOT) }
  state_path = active.fetch(:state_path)
  current_path = RageHarnessHook::CURRENT_PATH

  if absolute_paths.any? { |path| path == state_path || path == current_path }
    RageHarnessHook.deny("state.yml and the active-feature pointer are managed by .codex/bin/feature_state.rb.")
    exit
  end

  case phase
  when "draft"
    unless absolute_paths.all? { |path| RageHarnessHook.inside?(path, active.fetch(:spec_directory)) || RageHarnessHook.inside?(path, File.join(active.fetch(:directory), "evidence")) }
      RageHarnessHook.deny("Draft edits belong in the active feature's canonical specification directory or local evidence directory.")
      exit
    end
  when "approved"
    evidence_dir = File.join(active.fetch(:directory), "evidence")
    unless absolute_paths.all? { |path| RageHarnessHook.inside?(path, evidence_dir) }
      RageHarnessHook.deny("The specification is approved but implementation has not started. Run the state helper only after an explicit implementation request.")
      exit
    end
  when "implementing"
    if absolute_paths.any? { |path| RageHarnessHook.inside?(path, active.fetch(:repository).path) }
      RageHarnessHook.deny("Do not edit specification repository documents during implementation. Reopen through the specification-gap workflow.")
      exit
    end
    if state.dig("implementation", "paused_for_spec_gap") && !absolute_paths.all? { |path| RageHarnessHook.inside?(path, File.join(active.fetch(:directory), "evidence")) }
      RageHarnessHook.deny("Implementation is paused for a specification gap. Record evidence and wait for the user's decision.")
      exit
    end
  when "verified"
    evidence_dir = File.join(active.fetch(:directory), "evidence")
    unless absolute_paths.all? { |path| RageHarnessHook.inside?(path, evidence_dir) }
      RageHarnessHook.deny("The active feature is verified. Reopen it explicitly before changing the specification or implementation.")
      exit
    end
  end

  RageHarnessHook.allow
  exit
end

unless tool_name == "Bash"
  RageHarnessHook.allow
  exit
end

mutating_command = command.match?(
  /(?:^|[;&|]\s*)(?:rm|mv|cp|touch|mkdir|install|ln|chmod|chown|truncate|dd|rsync)\b|\b(?:sed\s+-i|perl\s+-pi|git\s+(?:add|am|apply|checkout|clean|commit|merge|mv|rebase|reset|restore|revert|rm|switch)|bundle\s+(?:install|update)|gem\s+(?:install|update)|ruby\s+-e|python\d*\s+-c|node\s+-e|apply_patch)\b|(?:^|[^<])>{1,2}/
)

protected_reference = command.include?("specs-repository") || command.include?(RageHarnessHook.relative(active.fetch(:spec_path))) ||
  command.include?(RageHarnessHook.relative(active.fetch(:state_path))) ||
  command.include?(RageHarnessHook.relative(RageHarnessHook::CURRENT_PATH))

if phase == "implementing"
  if mutating_command && (protected_reference || state.dig("implementation", "paused_for_spec_gap"))
    RageHarnessHook.deny("The active specification and state files cannot be changed through Bash during implementation.")
  else
    RageHarnessHook.allow
  end
elsif mutating_command
  RageHarnessHook.deny("Repository-changing Bash commands are blocked while the active feature is #{phase}. Use the workflow helper or an allowed private-document patch.")
else
  RageHarnessHook.allow
end
