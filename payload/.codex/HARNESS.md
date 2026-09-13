# Rage specification repository harness

Canonical source: https://github.com/rage-rb-fans/rage-feature-specs (published main).
The harness lives locally in Rage. Specifications live in a separate Git checkout at `.codex/specs-repository/`, excluded from Rage by .git/info/exclude. Commit specification changes in that checkout when publication is requested.

## Setup and selection

From the Rage root:

```bash
ruby .codex/bin/feature_state.rb setup
ruby .codex/bin/feature_state.rb sync
ruby .codex/bin/feature_state.rb activate deferred-dead-letter-queue
ruby .codex/bin/feature_state.rb status
```

The inspected dead-letter-queue feature is draft and its first task is already done. Do not reimplement that task. Inspect current statuses after syncing.

For a new feature use `create <slug> "<title>"`. This creates features/<slug>/spec.md from the source repository's template. Create tasks and ADRs from that repository's templates as needed. All authoring is iterative; the judge runs only on explicit request.

## Documents and state

Read .codex/specs-repository/AGENTS.md and follow its structure:
- features/<slug>/spec.md: canonical feature document.
- features/<slug>/tasks/*.md: self-contained implementation units.
- features/<slug>/adr/*.md: significant decisions.
- .codex/features/<slug>/state.yml in Rage: local execution metadata.
- .codex/features/<slug>/evidence/ in Rage: local judge, gap, and verification reports.

Canonical feature status is draft, implementation, or done. Tasks are todo or done.
Local execution still uses draft → approved → implementing → verified, recording the selected task and source revision. This local phase never overrides canonical status.

## Typical prompts

1. Use $rage-feature-spec-cycle to refine feature <slug> using the specification repository.
2. Refine task <filename> and explain its Fiber cleanup behavior.
3. Run the Specification Judge on the current feature and task.
4. I approve this revision. Prepare its status for implementation.
5. Publish these specification changes. (Only when you want a commit/push or PR workflow.)
6. Once the agreed revision is on main, sync, select <task-file.md>, and approve it locally.
7. Use $rage-implement-approved-feature to implement the selected task.
8. Use $rage-contribution-check to verify it.

Local command sequence after canonical approval is published:
```bash
ruby .codex/bin/feature_state.rb sync
ruby .codex/bin/feature_state.rb select-task 02-example-task.md
ruby .codex/bin/feature_state.rb refresh
ruby .codex/bin/feature_state.rb approve
ruby .codex/bin/feature_state.rb begin-implementation
```

Read and approve the actual synced revision before approve. These commands do not authenticate user intent; the agent must have the corresponding user instruction.
An existing implementation status on main is repository approval, but the user still chooses and authorizes the task to implement.

## Synchronization and drift

setup clones the configured GitHub repository. sync fetches origin/main and fast-forwards only a clean main checkout; it never discards local edits, resolves conflicts, resets branches, or pushes.
approve, begin-implementation, resume and verify fetch main themselves and reject unavailable network, dirty checkout, unpublished commits, incorrect statuses, or changed approval context.
Draft work may continue offline, explicitly labeled unpublished; implementation gates require a successful fetch.

Approval stores the selected task, source commit, and SHA-256 of all Markdown files, including instructions and shared ADRs. This is intentionally conservative: an unrelated Markdown change also requires inspection and reapproval. File changes/additions/deletions invalidate the hash. Hooks inspect local files without making network calls; upstream changes are discovered on sync and at workflow gates.

## Gaps and completion

Report a gap under local evidence/, run report-gap <report>, and wait for the user.
For an amendment: reopen locally, revise canonical feature/task/ADR documents, publish when requested, sync and approve the new revision.
For a constraint or deferral that fits existing requirements: record evidence and resume.
A judge rerun always needs an explicit request.

verify marks only the selected task locally verified. It does not change remote status, check off criteria or claim a merge.
After implementation is merged, a requested specification update adds the task's Result links, changes its status to done, and updates the parent checklist. Feature done requires all tasks and feature criteria to be complete.
Run reopen "Record merged implementation evidence" before those document edits. This opens the local editing gate and retains the prior checkpoint as last_verification; it does not change canonical status.
Before implementing another task, reopen locally, select it, inspect/refresh the synced context and approve.

## Upgrade from private specifications

The installer preserves .codex/features/ and existing documents. Version-1 state is deliberately rejected, not silently reused as approval.
If private features exist, first make a backup outside .codex/features/. Reconcile their SPEC.md and decisions.md with the canonical repository, adapting them into spec.md, tasks and ADRs without overwriting existing published requirements. Publish only when requested.
After preserving and migrating a legacy feature, move its version-1 local directory to your backup, activate the canonical feature, and obtain fresh approval. Old approvals cannot transfer.
Do not install with an active implementation without first recording its state and stopping its agent.

## Reasoning and token use

The project coordinator defaults to medium reasoning. Specification Author and Specification Judge use high; Core Implementer uses medium. These are reasoning-effort settings, not model selections: the agents inherit your chosen model. See [official subagent configuration](https://learn.chatgpt.com/docs/agent-configuration/subagents).

AGENTS.local.md defines focused handoffs, author reuse across iterations, and concise evidence reports. Required source reading, approval gates, and verification remain mandatory. The judge still runs only on explicit request.

Start a new Rage project task to load the updated configuration. An explicit session/UI reasoning override may supersede the coordinator default; select medium there if needed. Custom agent files set their own effort. Configuration validation does not prove runtime loading; check the spawned agent's settings in the new task. No token-savings percentage is assumed.

Filesystem and network isolation settings are unchanged by this update.

## Activation and limits

Restart the project task after installation and review changed hooks through /hooks. The three skills and three custom agents retain their names.
The source checkout is inside Rage's workspace so normal project filesystem access can cover it.
Hooks are workflow guardrails, not a security sandbox: they cover apply_patch paths and common shell writes, not every tool or shell expression.
No existing canonical feature was edited or published by this harness upgrade.
