---
name: rage-implement-approved-feature
description: Implement a selected Rage task from the approved published feature-specs repository revision, with RSpec coverage and explicit gap handling.
---

# Implement an approved Rage task

Use after an explicit implementation request. The source of truth is https://github.com/rage-rb-fans/rage-feature-specs on main, checked out at .codex/specs-repository/.

Run `ruby .codex/bin/feature_state.rb status`, then `ruby .codex/bin/feature_state.rb begin-implementation`.
The gate fetches main and requires: a clean matching checkout; feature status implementation; selected task status todo; local approval bound to that task and the unchanged Markdown context.
Offline or divergent state must be resolved before implementation starts.

Use rage_core_implementer for the selected task, following the efficient handoff instructions in AGENTS.local.md. The implementer must read the specification repository's AGENTS.md, the complete parent spec.md, selected task, and every ADR linked by either, plus Rage's architecture/contribution guidance, relevant code, and neighboring RSpec examples. The coordinator checks the gate and resulting diff/evidence without duplicating the implementation. One task is the default implementation scope; include related changes only when necessary.

Preserve Rage's lean happy path, boot-time computation, feature isolation, Ruby 3.3.0 compatibility, public API and Fiber/Iodine semantics. Trace task acceptance criteria and applicable feature criteria to code/tests. Add required YARD and changelog changes, and run the task's Verification commands plus focused Rage tests.

## Gaps and upstream changes

Do not edit canonical specifications during implementation. When a material requirement is missing or conflicting, stop and preserve code. Write the impact, options and recommendation under .codex/features/<slug>/evidence/, then run:

```bash
ruby .codex/bin/feature_state.rb report-gap <report-path>
```

Await the user's choice:
- Amend: reopen locally, revise canonical feature/task/ADR documents through the authoring workflow, publish when requested, then sync and obtain approval of the revised main version.
- Constrain or defer within the existing approved requirements: record the user's direction in local evidence and resume. Significant durable decisions belong in the specs repository through an authorized amendment.
- A change to observable behavior, API, acceptance criteria, errors, security, concurrency, persistence, compatibility or scope requires reapproval.

Judge runs remain explicit-only. Never automatically rerun it.
If upstream changes invalidate the context digest, inspect the new documents and reapprove; never silently adopt new requirements.

## Handoff

Report implementation, task/feature coverage, verification evidence and pending checks. Use $rage-contribution-check for final local verification.
Local verified does not mark the remote task or feature done. Only after implementation is merged, and when requested, update task Result links, task status/criteria, and the parent task checklist. Feature done also requires every task and feature criterion to be verified.
