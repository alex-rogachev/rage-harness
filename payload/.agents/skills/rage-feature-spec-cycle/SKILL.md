---
name: rage-feature-spec-cycle
description: Create, refine, or explicitly judge Rage feature specifications, tasks, and ADRs in rage-rb-fans/rage-feature-specs.
---

# Rage feature specification cycle

The source of truth is https://github.com/rage-rb-fans/rage-feature-specs on main.
Use its actual files through the checkout at `.codex/specs-repository/` inside the Rage checkout.

## Start or resume

Run from the Rage root:

```bash
ruby .codex/bin/feature_state.rb setup
ruby .codex/bin/feature_state.rb sync
ruby .codex/bin/feature_state.rb activate <feature-slug>
ruby .codex/bin/feature_state.rb status
```

For a new feature, use `create <feature-slug> "<title>"` instead of activate.
Sync before starting a new iteration on a clean main checkout. If there are local edits or a feature branch, inspect them and continue that draft without discarding work. Report that it is unpublished. Never reset or overwrite divergent drafts to make sync pass.

Use the Specification Author for the requested iteration, following the efficient handoff instructions in AGENTS.local.md. The author must read the specification repository's AGENTS.md, parent `features/<slug>/spec.md`, relevant complete task documents and every linked ADR, plus Rage's ARCHITECTURE.md, CONTRIBUTING.md, and CODE_OF_CONDUCT.md. The coordinator inspects routing state and verifies the resulting diff; it need not duplicate the author's full investigation.

## Iterative authoring

Edit the active feature under `.codex/specs-repository/features/<slug>/`. Use the repository's templates/feature.md, templates/task.md, and templates/adr.md; do not generate another authoritative document under .codex/features/.
Parent feature specifications have no lifecycle status. Task status is todo or done, so each small, reviewable task can move through approval and implementation independently. Preserve existing IDs, links, task and ADR statuses, and merged evidence unless the user asks to change them.

Develop observable behavior and acceptance criteria over as many iterations as the user needs. Break implementation into self-contained tasks; record significant decisions in ADRs. Address applicable security, lifecycle, compatibility, performance, Fiber/Iodine and race risks. Do not invent consequential unresolved requirements.
Do not edit Rage implementation while locally drafting.

After a pass, run `feature_state.rb refresh` and report unresolved questions. A finished pass does not imply approval.
Commit, push, or open a specifications PR only when the user requests publication. Use Git in the specification checkout; never stage its files in Rage. During draft, the shell guard permits only `git add`, `git commit`, and `git push` when their working directory is the specification checkout. Use that checkout as the command working directory or pass it explicitly with `git -C .codex/specs-repository ...`.

## Explicit judgment

Run rage_specification_judge only when the current user explicitly requests it. Give it the source checkout, parent feature, selected task(s), linked ADRs, and original requirements.
Save its report locally under `.codex/features/<slug>/evidence/` and record it:

```bash
ruby .codex/bin/feature_state.rb record-review ready <report-path>
```

Verdicts are ready, revisions_required, or blocked; none changes phase or grants approval.
Any Markdown change in the specification repository invalidates the recorded review.

## Approval and implementation handoff

Explicit user approval applies to one selected task and the specification context inspected with it. Publishing agreed document changes is a separate action unless already requested.
Implementation consumes the published main revision: once the agreed documents are on main, sync, read the revision, select the task, and refresh:

```bash
ruby .codex/bin/feature_state.rb select-task <task-filename.md>
ruby .codex/bin/feature_state.rb refresh
ruby .codex/bin/feature_state.rb approve
```

Run approve only with explicit user approval of that revision. The command requires a selected published todo task, records the commit and a digest of all Markdown context, and does not modify canonical documents.
Do not begin implementation until requested.
