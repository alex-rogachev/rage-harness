---
name: rage-contribution-check
description: Verify a Rage implementation against one named published task, linked ADRs, repository conventions, and required checks.
---

# Check a Rage framework contribution

This skill verifies and reports. It does not commit, push, publish, open a pull request, or change task status.

## Establish scope

Run `ruby .codex/bin/spec_workflow.rb check-ready TASK_PATH`. Read the named task, its parent `spec.md`, linked ADRs, optional `.workflow/evidence/`, and Rage's architecture and contribution guidance. Confirm the reported specification commit matches the implementation handoff.

Inspect the complete Rage diff and map every task acceptance criterion and applicable parent requirement to implementation and RSpec evidence. Flag unrelated changes, silent scope expansion, weakened tests, or unauthorized behavior.

## Verify

Review correctness, security, error handling, cleanup, public API stability, Rails compatibility, supported Ruby behavior, optional dependencies, and relevant Fiber/Iodine or concurrency risks.

Run checks in increasing scope:

1. Targeted changed and neighboring specs.
2. `bundle exec rake`.
3. `bundle exec rubocop`.
4. `bundle exec yardoc --fail-on-warning`.
5. Appraisal and external checks when applicable and available.

Do not describe unavailable checks as passing. Confirm required YARD documentation and an `Unreleased` changelog entry unless a documented exception applies.

## Finish

Report the overall result, criteria coverage, findings ordered by severity, exact commands and results, unavailable checks, and remaining risks. Local verification does not change canonical status.

After implementation merges, an explicitly requested specification update may add Result links, complete criteria, update the parent checklist, and change only that task to `done`.
