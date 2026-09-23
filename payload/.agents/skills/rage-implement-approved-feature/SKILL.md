---
name: rage-implement-approved-feature
description: Implement one named ready-for-development Rage task from the published feature-specs repository, with RSpec coverage and explicit gap handling.
---

# Implement a ready-for-development Rage task

Use only after the user explicitly requests implementation and provides or confirms a repository-relative task path.

From the Rage root, run:

```bash
ruby .codex/bin/spec_workflow.rb check-ready features/SLUG/tasks/TASK.md
```

The gate fetches `main` and requires a clean published specification checkout and task status `ready-for-development`. Retain the reported specification commit in the implementation handoff.

Use `rage_core_implementer` for the named task. It must read the specification repository's `AGENTS.md`, complete task, parent `spec.md`, every ADR linked by either, Rage's architecture/contribution guidance, relevant code, and neighboring RSpec examples.

Implement the smallest defensible change scoped to that task. Preserve Rage's lean happy path, boot-time computation, feature isolation, Ruby 3.3.0 compatibility, public API, and Fiber/Iodine semantics. Trace acceptance criteria to code and tests, add required YARD and changelog updates, and run the task's verification commands plus focused Rage tests.

## Gaps and drift

Do not edit specification documents while implementing. For a material gap, stop and preserve the code. Record the affected requirements, impact, options, and recommendation under `.codex/specs-repository/.workflow/evidence/`, then await the user's decision.

An amendment returns the task to `draft`. Revise and publish it as `ready-for-development`, then rerun `check-ready` before resuming. A constraint or deferral within unchanged requirements may resume after recording the user's direction. Significant durable decisions belong in an ADR.

Before final handoff, rerun `check-ready`. If its specification commit differs from the implementation handoff, inspect the published changes and obtain renewed user direction rather than silently adopting them.

Report implementation, task and parent-criterion coverage, exact verification evidence, skipped checks, and unresolved risks. Use `$rage-contribution-check` for final local verification. Do not mark the task `done`; that happens only after merge.
