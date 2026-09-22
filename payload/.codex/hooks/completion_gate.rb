#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "support"

input = RageHarnessHook.input
active = RageHarnessHook.active
unless active
  RageHarnessHook.allow
  exit
end

if input["stop_hook_active"] || active.dig(:state, "implementation", "paused_for_spec_gap")
  RageHarnessHook.allow
  exit
end

phase = active.dig(:state, "phase")
message = input["last_assistant_message"].to_s.downcase
negated = message.match?(/\b(?:not|isn't|is not|hasn't|has not)\s+(?:yet\s+)?(?:fully\s+)?(?:approved|complete|completed|done|implemented|verified)\b/) ||
  message.match?(/\b(?:verification|checks?)\s+(?:is|are)?\s*(?:pending|incomplete|not run|not complete)\b/)

claims_approval = message.match?(/\b(?:specification|feature spec)\s+(?:is\s+)?approved\b/)
claims_completion = message.match?(/\b(?:feature|work|task|implementation)\s+(?:is\s+)?(?:complete|completed|done|verified)\b/) ||
  message.match?(/\b(?:fully\s+)?implemented\b/) ||
  message.match?(/\ball (?:required )?(?:checks|tests) (?:pass|passed)\b/)

reason = if phase == "draft" && claims_approval && !negated
  "The selected task has not been approved locally. Revise the response so it does not claim approval; only the user can approve it."
elsif phase == "implementing" && claims_completion && !negated
  "The feature is not in verified state. Run $rage-contribution-check and record verification, or revise the response to state precisely what remains unverified."
end

if reason
  puts({"decision" => "block", "reason" => reason}.to_json)
else
  RageHarnessHook.allow
end
