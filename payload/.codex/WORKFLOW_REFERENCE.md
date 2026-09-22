# Workflow command reference

Use this reference when running the state helper or recovering interrupted work.
The [repository README](../../README.md) is available in the harness source clone;
after installation, use https://github.com/alex-rogachev/rage-harness#readme for the
user guide. Mandatory agent rules are in Rage's `AGENTS.local.md`.

## Paths and command conventions

Run every command below from the **Rage checkout root**, not the harness source
clone or nested specification checkout. Replace uppercase placeholders before use.

```bash
ruby .codex/bin/feature_state.rb COMMAND
```

The helper uses these paths relative to Rage:

| Path | Contents |
| --- | --- |
| `.codex/specs-repository/features/SLUG/` | Feature spec.md, tasks/ and adr/ in the separate specs Git repository |
| `.codex/features/current` | One active feature slug for this Rage checkout |
| `.codex/features/SLUG/state.yml` | Local task, phase, approval, review and verification metadata |
| `.codex/features/SLUG/evidence/` | Local review, gap and check reports |

Only one feature is active per Rage checkout. Avoid concurrent feature workflows
in that checkout; switching the pointer changes which feature its hooks enforce.

## Commands

| Command and arguments | Purpose and conditions |
| --- | --- |
| `setup` | Clone the fixed specs remote if absent; otherwise validate the existing checkout. |
| `sync` | Fetch origin/main and fast-forward a clean specs main branch; reject unpublished commits or divergence. |
| `create SLUG "TITLE"` | Create a feature from its repository template if absent, initialize local state, and activate it. |
| `activate SLUG` | Select an existing feature; preserve any existing version-2 local state. |
| `current` | Print the active feature slug. |
| `status` | Show local state, selected task status, current document hash, checkout commit and changes. Does not fetch. |
| `select-task FILE.md` | Select an existing task filename under the active feature's tasks/ directory. Requires local draft; clears approval and review. |
| `refresh` | Recompute the inspected Markdown hash during draft and update review staleness. Does not fetch. |
| `record-review VERDICT REPORT` | Record ready, revisions_required or blocked with the current document hash. Never approves work. |
| `approve` | From draft, approve the selected todo task against the inspected, published specification context. |
| `begin-implementation` | Move approved to implementing after checking the current published specification. |
| `report-gap REPORT` | Pause implementing and record a gap report. |
| `resume` | Resume a paused implementation after the user's decision, with unchanged approved context. |
| `verify` | Move implementing to verified after rechecking the published specification. Refuses a paused gap. |
| `reopen "REASON"` | Return to draft, clear approval, unpause implementation and preserve prior verification as last_verification. |

REPORT must be an existing file under the active feature's evidence/ directory.
Use a Rage-relative or absolute path. The commands do not authenticate human
intent: approval, implementation, gap resolution and publication still require
the user instructions specified in AGENTS.local.md.

## Approval sequence

After the agreed specification and task are published on main, activate the
feature and inspect the synced documents:

```bash
ruby .codex/bin/feature_state.rb sync
ruby .codex/bin/feature_state.rb activate SLUG
ruby .codex/bin/feature_state.rb select-task FILE.md
ruby .codex/bin/feature_state.rb refresh
```

The selection/refresh steps require local draft; reopen an existing later-phase
workflow only with user direction. After explicit approval of this revision:

```bash
ruby .codex/bin/feature_state.rb approve
```

After the user separately requests implementation:

```bash
ruby .codex/bin/feature_state.rb begin-implementation
```

After the contribution-check skill has completed all required verification:

```bash
ruby .codex/bin/feature_state.rb verify
```

The helper does not run tests or validate a verification report. It records a
workflow checkpoint, so the agent must provide actual check evidence first.

## State and synchronization

Local phase is `draft → approved → implementing → verified`. Reopening returns
to draft. Judgment leaves the phase unchanged; a gap is a pause within implementing.

The specification repository uses task statuses `todo / done`; parent feature
specifications have no lifecycle status. Local phase does not overwrite those
documents or prove that implementation merged.

Approval records the selected task, source commit and SHA-256 of all Markdown
files in the specification repository, including instructions and shared ADRs.
An unrelated Markdown change can therefore require reapproval. Approval checks
compare the document hash and selected task; the stored commit identifies the
approval revision, rather than requiring every future HEAD to have that SHA.

`approve`, `begin-implementation`, `resume` and `verify` fetch main and reject a
dirty checkout, unpublished changes, unsuitable statuses or changed required
context. Hooks check local content without fetching. Offline drafting is possible
after setup, but implementation gates require a successful fetch.

## Recover from a gap or changed specification

1. Keep existing work. During implementation, write a gap report under evidence/
   and call `report-gap REPORT`.
2. Await the user's choice. For an amendment, use `reopen "REASON"`, then return
   to the authoring workflow. Publish only when requested, sync, inspect, and
   repeat the approval sequence before continuing implementation.
3. If the user constrains or defers behavior within the unchanged requirements,
   record that direction in evidence and use `resume`.
4. Run the judge again only if explicitly requested.

If sync fails because a draft is dirty or divergent, preserve it and resolve the
Git state with the user. Do not reset or discard files merely to pass the gate.

## Record merged work or select another task

After merge, use `reopen "Record merged implementation evidence"` before an
explicitly requested specification update. Add task Result links and completion
criteria according to the specs repository's AGENTS.md. The previous local
checkpoint remains in last_verification. Reopening itself publishes nothing.

For another task, reopen locally, select it, inspect/refresh the synced documents,
and obtain fresh approval. Do not reuse another task's approval.

## Upgrade from private specifications

Version-1 local state is rejected rather than silently reused. Stop active agents
and back up old feature directories outside `.codex/features/` before migration.
Reconcile their SPEC.md and decisions.md into the canonical repository's
spec.md/tasks/adr/ structure without overwriting published requirements.

Publish only when requested. After preserving and migrating a legacy feature,
move its old local directory into your backup, activate the canonical feature,
and obtain fresh local approval. Old approvals do not transfer.

## Reference-file rename in existing installations

This reference replaces `HARNESS.md`. The installer copies new files but does not
delete obsolete ones. After upgrading, check an old `.codex/HARNESS.md` for local
notes, preserve anything needed outside the harness folders, and remove that old
reference manually. All maintained links now point to WORKFLOW_REFERENCE.md.

## Hook troubleshooting

Confirm Codex starts at the Rage root and loads project configuration. Hook
commands resolve their scripts from the current Git root; starting inside the
nested specification repository can resolve the wrong location. Review /hooks
after installation or upgrades, and verify behavior in a disposable workflow.

Hooks are limited guardrails, not filesystem isolation. During draft, the shell
guard allows explicitly authorized specification publication through `git add`,
`git commit`, and `git push` only when Git targets `.codex/specs-repository/`.
It blocks equivalent Rage code changes and pushes. Use the specification checkout
as the command working directory or pass it with `git -C`; do not bypass the guard
or broaden sandbox permissions to publish.
