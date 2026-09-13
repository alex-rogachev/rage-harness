#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "support"

RageHarnessHook.input
active = RageHarnessHook.active
unless active
  RageHarnessHook.allow
  exit
end

state = active.fetch(:state)
review = state.fetch("review", {})
review_text = if review["verdict"]
  fresh = review["reviewed_sha256"] == active.fetch(:digest) && !review["stale"]
  "#{review.fetch("verdict")} (#{fresh ? "current" : "stale"})"
else
  "not run"
end
approval = state.dig("approval", "approved_sha256") == active.fetch(:digest) ? "current" : "none or stale"
gap = state.dig("implementation", "paused_for_spec_gap") ? "paused for user resolution" : "none"

RageHarnessHook.context(
  "SessionStart",
  "Rage specs source: #{SpecRepository::URL}. Active feature: #{active.fetch(:slug)}. Local phase: #{state.fetch("phase")}. Task: #{state['task'] || 'none'}. " \
    "Specification: #{RageHarnessHook.relative(active.fetch(:spec_path))}. Current SHA-256: #{active.fetch(:digest)}. " \
    "Judge metadata: #{review_text}. Approval: #{approval}. Specification gap: #{gap}. " \
    "Run the Specification Judge only when the current user explicitly requests it. Follow AGENTS.local.md and the phase workflow before editing."
)
