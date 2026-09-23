# Rage framework contribution rules

These instructions apply to this Rage checkout, not to applications built with Rage.
Read `.codex/WORKFLOW_REFERENCE.md` when using specification workflow commands.

## Framework constraints

- Read ARCHITECTURE.md, CONTRIBUTING.md, and CODE_OF_CONDUCT.md before architectural or contributor-facing decisions. Inspect relevant source, neighboring tests, helpers, and history.
- Preserve the lean happy path, boot-time computation, unused-feature isolation, public API compatibility, idiomatic Ruby, and Fiber/Iodine semantics.
- Ruby **3.3.0 is the minimum** declared by rage.gemspec. Do not rely on newer-only behavior unless the feature explicitly changes that requirement.
- Make the smallest defensible change, with appropriate RSpec coverage, YARD documentation and changelog updates. Run targeted checks followed by applicable broader checks; report skipped or unavailable checks honestly.
- Keep reviews constructive and evidence-based. Do not commit, push, publish, or open a PR without an explicit user request.

## Specification and approval boundaries

- The authoritative specifications are published on main at https://github.com/rage-rb-fans/rage-feature-specs. Work in this checkout's `.codex/specs-repository/`; read its AGENTS.md and use its feature/task/ADR templates.
- Keep specification documents and task lifecycle state in that repository. Optional local reports belong in its gitignored `.workflow/evidence/` directory. Keep the installed harness and specification checkout locally excluded from Rage's Git tracking.
- Tasks move through `draft → ready-for-development → done`; parent specifications have no status. Use the Specification Author for user-directed drafting iterations. An iteration does not imply readiness or approval. Do not edit Rage source or RSpec files while drafting a task.
- Invoke the read-only Specification Judge **only on explicit user request**. Its verdict is advisory; it cannot approve work.
- Only the user can authorize changing a task to `ready-for-development`, publishing specifications, and starting implementation. These are separate actions.
- Implement one explicitly named `ready-for-development` task through the Core Implementer. Run `spec_workflow.rb check-ready TASK_PATH` immediately before implementation; it requires a clean published `main` and reports the exact specification commit.
- Do not edit the specification during implementation. If its published commit changes, inspect the changes and obtain renewed user direction before continuing. Mark a task `done` only after implementation merges and its Result and criteria contain evidence.

## Gaps

- Stop at uncovered material behavior, preserve existing work, and report the affected requirements, impact, options and recommendation under `.codex/specs-repository/.workflow/evidence/`. Wait for the user's decision.
- A change affecting behavior, API, criteria, errors, security, concurrency, persistence, performance guarantees, compatibility, scope or non-goals returns the task to `draft`; amend and publish it as `ready-for-development` again before resuming.
- A constraint or deferral within existing requirements may resume after the user's direction is recorded. Significant decisions belong in ADRs. Never invoke the judge automatically during recovery.

## Efficient delegation

- Coordinator and implementer use medium reasoning; author and explicitly requested judge use high. Specialists inherit the selected model.
- Delegate substantive work once. The coordinator checks gates and resulting diffs/evidence instead of repeating the specialist's investigation.
- Hand off the current request, original requirements, accepted decisions, feature/task paths, specification commit, linked ADRs and relevant code/evidence pointers. Paths and summaries do not replace the worker's required full-document reading.
- Reuse the author for iterations on the same feature when available; recheck changed context. Start a fresh handoff when the feature, role or approved revision changes.
- Return concise changes, decisions/coverage, unresolved issues and exact check results; keep long logs in evidence. Reuse check evidence only if code, dependencies and environment are unchanged.
- If medium-effort implementation repeatedly stalls, explain the evidence and propose targeted higher-effort help. Do not silently change settings, requirements or invoke the judge. Never claim token savings without measurements.
