# Local Rage framework contribution harness

These instructions apply only to this local checkout. This repository develops the Rage framework itself.

## Source of truth

- Read `ARCHITECTURE.md`, `CONTRIBUTING.md`, and `CODE_OF_CONDUCT.md` before making architectural or contributor-facing decisions.
- Inspect the relevant source, neighboring specs, helpers, and recent history before proposing behavior.
- Preserve Rage's lean happy path, boot-time computation, feature isolation, Rails familiarity, idiomatic Ruby, and single-threaded Fiber/Iodine model.
- Rage requires Ruby 3.3.0 or newer, as declared by `spec.required_ruby_version` in `rage.gemspec`. Treat Ruby 3.3 as the minimum compatibility baseline and do not rely on behavior introduced only in newer Ruby versions unless the feature explicitly changes that requirement.
- Treat public API stability, supported Ruby versions, YARD documentation, and changelog requirements as part of the feature.

## Feature workflow

- The feature specification source of truth is https://github.com/rage-rb-fans/rage-feature-specs on main. Its working checkout is `.codex/specs-repository/`; read that repository's AGENTS.md before authoring, judging or implementing.
- Canonical documents are `features/<feature>/spec.md`, `tasks/*.md`, and linked `adr/*.md` in that checkout. Use its templates. Do not create competing specification copies under `.codex/features/`; that directory holds only local state and evidence.
- Canonical feature status is draft, implementation, or done; task status is todo or done. Implement one selected todo task only when its parent feature is implementation and the current published revision is explicitly approved locally.
- Develop the canonical documents through as many user-directed iterations as needed. Finishing an iteration does not imply readiness or approval.
- Use the Specification Author for drafting and refinement.
- Run the Specification Judge only when the current user explicitly requests judgment. Never invoke it automatically.
- The judge is read-only and advisory. It cannot approve a specification.
- Only an explicit user instruction may change a feature from `draft` to `approved`.
- Do not edit Rage source or RSpec files while the active feature is in `draft`.
- Approval records a selected task, source commit, and digest of all Markdown in the specification repository, including tasks, ADRs, and instructions. Changed context requires inspection and reapproval. Sync main before approval, implementation, and verification; never discard local edits to sync.
- Local verified is a task checkpoint. Canonical done requires merged implementation evidence, completed task Result links, and verified criteria according to the source repository's AGENTS.md.
- Do not change approved canonical documents silently. Publishing specifications requires a user request, just as publishing Rage code does.

## Reasoning and efficient handoffs

- The coordinator defaults to medium reasoning. Use the Specification Author and explicitly requested Specification Judge at high reasoning; use the Core Implementer at medium. Agent configuration sets effort, not a different model: all three inherit the selected model.
- Delegate substantive authoring or implementation once to the matching role. The coordinator routes the request, checks workflow gates, and verifies the resulting diff and evidence; it should not first perform the same full investigation or implementation.
- Give the worker the current request, original requirements and accepted decisions, active feature/task paths, source revision and local state path, linked ADRs, and relevant code/evidence pointers. Prefer paths over pasted documents or the entire conversation. The worker must read the required complete documents; a handoff summary never replaces them.
- Continue with the existing author for iterations on the same feature when available. Send the new request and changed context; recheck source state and changed documents. Use a fresh handoff when the feature, role, or approved revision changes.
- Return changed paths, decisions or requirement coverage, unresolved issues, and exact check results. Keep lengthy logs in local evidence and return paths with a concise summary. Reuse valid check evidence only when code, dependencies, and environment have not changed; never skip required checks to save tokens.
- If medium-effort implementation repeatedly stalls on a concrete technical issue, report the evidence and propose targeted higher-effort help instead of repeating the same attempt. Do not silently change settings, requirements, or invoke the judge.
- Do not claim token savings without measured usage. Keep approval, specification-gap, and verification gates intact.

## Implementation gaps

If implementation exposes behavior that the approved specification does not cover:

1. Stop at the decision point and leave existing work intact.
2. Do not edit canonical specification, task, or ADR documents during implementation.
3. Report the missing behavior, impact, affected requirements, options, and recommendation.
4. Record the proposal under the feature's `evidence/` directory if a durable report is useful.
5. Wait for the user to amend the specification, constrain the implementation, or defer the behavior.

Reopen locally and reapprove the published revision when a gap affects observable behavior, public API, acceptance criteria, errors, security, Fiber/concurrency semantics, persistence, performance guarantees, compatibility, scope, or non-goals. Amend canonical documents through the specs repository. Significant decisions belong in ADRs. Equivalent internal choices may be recorded in local evidence and continued after user direction.

## Contribution discipline

- Implementation must include appropriate RSpec coverage in Rage; canonical feature documents belong in the specs repository. Harness configuration and working state remain locally excluded from Rage.
- Prefer the smallest defensible change and avoid speculative abstraction.
- Run targeted checks first, then the applicable full-suite, RuboCop, YARD, appraisal, and external-test checks.
- Clearly distinguish checks that passed from checks that could not run because services or secrets were unavailable.
- Do not commit, push, publish, or open a pull request unless the user explicitly asks.
- Keep reviews evidence-based, constructive, and focused on the contribution rather than the contributor.
