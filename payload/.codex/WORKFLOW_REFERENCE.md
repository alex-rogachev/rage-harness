# Workflow command reference

The authoritative specification repository is checked out at `.codex/specs-repository/` inside Rage. It contains feature documents, task lifecycle state, ADRs, and Git history. Rage contains no separate workflow state.

Run commands from the Rage checkout root:

```bash
ruby .codex/bin/spec_workflow.rb COMMAND
```

## Paths

| Path | Contents |
| --- | --- |
| `.codex/specs-repository/features/SLUG/spec.md` | Parent requirements; no lifecycle status |
| `.codex/specs-repository/features/SLUG/tasks/TASK.md` | Task requirements and canonical status |
| `.codex/specs-repository/features/SLUG/adr/` | Durable architecture decisions |
| `.codex/specs-repository/.workflow/evidence/` | Optional local, gitignored reports |

Task status is `draft`, `ready-for-development`, or `done`.

## Commands

| Command | Purpose |
| --- | --- |
| `setup` | Clone the fixed specification remote if absent; otherwise validate it. |
| `sync` | Fetch and fast-forward a clean specification `main`; reject local changes, unpublished commits, or divergence. |
| `create SLUG "TITLE"` | Create a parent specification from the feature template. It creates no local workflow state. |
| `status TASK_PATH` | Show a named task's canonical status, checkout commit, and local changes without fetching. |
| `check-ready TASK_PATH` | Sync published `main`, require `ready-for-development`, and print the exact specification commit. |

`TASK_PATH` is repository-relative, for example:

```text
features/deferred-dead-letter-queue/tasks/02-list-dead-tasks.md
```

## Workflow

### Draft

Create or edit `spec.md`, task documents, and ADRs in the specification checkout. Parent specifications have no status. New and amended tasks use:

```yaml
---
status: draft
---
```

Optional judge and gap reports go under `.workflow/evidence/`. They are not canonical state and are not committed.

### Approve and publish

After explicit user approval, change the named task to:

```yaml
---
status: ready-for-development
---
```

Commit and push only when explicitly authorized. Approval/status change, publication, and implementation are distinct actions unless the user clearly combines them.

Before implementation:

```bash
ruby .codex/bin/spec_workflow.rb check-ready features/SLUG/tasks/TASK.md
```

The command requires a clean checkout synchronized with remote `main`. Its reported commit identifies the requirements used for the implementation handoff.

### Implement and verify

Implementation is a separate explicit request naming the task. Do not edit specifications while changing Rage code. Before final verification, rerun `check-ready`; if the reported commit changed, inspect the new revision and obtain renewed user direction.

For a material gap, preserve the implementation and record a report under `.workflow/evidence/`. An amendment changes the task back to `draft`; publish it as `ready-for-development` again before resuming.

### Record merged work

After implementation merges and only when requested, update the task's completed criteria and Result links, update the parent checklist, and change the task to:

```yaml
---
status: done
---
```

## Migration from local feature state

The old `.codex/features/` directory is no longer read. Preserve any useful review, gap, or verification reports by moving them under `.codex/specs-repository/.workflow/evidence/`; then remove the obsolete directory manually. Do not copy `state.yml` or the `current` pointer because task status now lives in canonical task documents.

The installer removes the obsolete phase hooks and `feature_state.rb` after backing them up under `.codex/harness-backups/`.
