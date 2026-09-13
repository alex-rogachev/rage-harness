#!/usr/bin/env ruby
# frozen_string_literal: true

require "time"
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
event = input["hook_event_name"]

if phase == "draft"
  if event == "Stop"
    previous_digest = state["spec_sha256"]
    review_was_stale = state.dig("review", "stale")
    state["spec_sha256"] = active.fetch(:digest)
    if state.dig("review", "reviewed_sha256") && state.dig("review", "reviewed_sha256") != active.fetch(:digest)
      state["review"]["stale"] = true
    end
    if previous_digest != active.fetch(:digest) || review_was_stale != state.dig("review", "stale")
      state["updated_at"] = Time.now.utc.iso8601
      RageHarnessHook.write_state(active)
    end
  end
  RageHarnessHook.allow
  exit
end

approved_digest = state.dig("approval", "approved_sha256")
valid = approved_digest && approved_digest == active.fetch(:digest)
unless valid
  reason = "Canonical specification context no longer matches approval. Stop implementation, inspect changes, reopen locally, and approve the published revision again."
  if event == "PreToolUse"
    RageHarnessHook.deny(reason)
  elsif input["stop_hook_active"]
    RageHarnessHook.allow
  else
    puts({"decision" => "block", "reason" => reason}.to_json)
  end
  exit
end

RageHarnessHook.allow
