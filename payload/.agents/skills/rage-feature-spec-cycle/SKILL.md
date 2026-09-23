---
name: rage-feature-spec-cycle
description: Create, refine, or explicitly judge Rage feature specifications, tasks, and ADRs in rage-rb-fans/rage-feature-specs.
---

# Rage feature specification cycle

The source of truth is https://github.com/rage-rb-fans/rage-feature-specs on `main`, checked out at `.codex/specs-repository/` inside Rage.

## Start or resume

From the Rage root, set up and synchronize a clean checkout:

```bash
ruby .codex/bin/spec_workflow.rb setup
ruby .codex/bin/spec_workflow.rb sync
```

For a new feature, run `spec_workflow.rb create <feature-slug> "<title>"`. For an existing task, the user or coordinator must name its repository-relative path, for example `features/example/tasks/02-work.md`.

If synchronization finds local edits or divergence, preserve them and report that they are unpublished. Never reset or discard work to make the gate pass.

Use the Specification Author for substantive drafting. It must read the specification repository's `AGENTS.md`, the named task, its parent `spec.md`, linked ADRs, and Rage's architecture and contribution guidance.

## Task lifecycle

Parent specifications have no status. Each task owns its lifecycle:

```text
draft → ready-for-development → done
```

- `draft`: requirements are still being developed or amended.
- `ready-for-development`: the published task is explicitly approved for implementation.
- `done`: implementation merged and the task contains completed criteria and Result links.

Draft and edit only in `.codex/specs-repository/`. Optional local review or gap reports belong under its gitignored `.workflow/evidence/<feature>/<task>/` directory. Do not create workflow state in the Rage repository.

After a drafting pass, report unresolved questions. A finished pass does not change task status, authorize publication, or authorize implementation.

## Explicit judgment

Run `rage_specification_judge` only when the user explicitly requests it. Save any report under `.workflow/evidence/`; verdicts are advisory and do not change task status.

## Approval and publication

Changing a task from `draft` to `ready-for-development` requires explicit user approval. Committing and pushing that change requires separate explicit publication authorization unless the user grants both together.

Publish with Git operating on `.codex/specs-repository/`; never stage specification files in Rage. After publication, confirm the exact canonical task and commit:

```bash
ruby .codex/bin/spec_workflow.rb check-ready features/SLUG/tasks/TASK.md
```

Implementation remains a separate explicit user action.
