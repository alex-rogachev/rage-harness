---
name: rage-contribution-check
description: Verify a selected Rage task against its published feature specification, linked ADRs, repository conventions, and required checks.
---

# Check a Rage framework contribution

Use this skill after implementation is ready for final local review. It verifies and reports; it does not commit, push, publish, or open a pull request.

## Establish scope

Read the specification repository's AGENTS.md, canonical features/<slug>/spec.md, selected task and every linked ADR, local state.yml and evidence, and Rage's ARCHITECTURE.md, CONTRIBUTING.md, and CODE_OF_CONDUCT.md. Run the state helper's sync command and stop if the context digest changed or a gap remains unresolved. The canonical source is https://github.com/rage-rb-fans/rage-feature-specs on main.

Inspect the complete diff and map every selected-task acceptance criterion and applicable feature requirement to implementation and RSpec evidence. Preserve the source documents' existing identifiers. Flag unrelated edits, silent scope expansion, weakened tests, or unauthorized behavior.

## Review risks

Review the actual implementation for correctness, security, error handling, cleanup, public API stability, Rails compatibility, supported Ruby behavior, and optional dependency behavior. Where relevant, examine Fiber-local versus shared state, yielding and resumption, Iodine lifecycle callbacks, multi-process communication, race-like interleavings, blocking work, and request-path overhead.

Check that new abstractions are justified by observed duplication and that users who do not use the feature pay no avoidable runtime cost.

## Verify

Run the selected task's Verification instructions and relevant checks in increasing scope:

1. Targeted changed or neighboring specs, including exact file or line commands when useful.
2. `bundle exec rake`.
3. `bundle exec rubocop`.
4. `bundle exec yardoc --fail-on-warning`.
5. `bundle exec appraisal bundle install` and `bundle exec rake appraise` when Active Record extension behavior changed.
6. Relevant external or integration tests when their services and environment variables are available.

Do not describe skipped external tests as passing. State which variables or services were unavailable. Do not install new dependencies or access external services solely to complete this check without user authorization.

Confirm that user-facing methods have YARD documentation, internal callable methods use `@private` where appropriate, and new or changed behavior has an `Unreleased` changelog entry unless a maintainer-facing `skip-changelog` case clearly applies.

## Finish

Only after all required checks pass, run the following command. If required checks are unavailable, report them and leave the task unverified:

```bash
ruby .codex/bin/feature_state.rb verify
```

This verifies only the selected task locally and fetches published main again to check for specification drift. It never marks canonical documents done. After implementation is merged, an explicitly requested specs update may mark the task done, complete its Result with implementation links, and update the parent checklist.

For that requested post-merge document update, run `feature_state.rb reopen "Record merged implementation evidence"` to open the local editing gate. The previous verification is preserved as last_verification. This command does not change canonical documents or publish anything.

Report:

- overall result;
- requirement and acceptance-criterion coverage;
- findings ordered by severity with file references;
- commands run and their results;
- unavailable checks;
- remaining risks or assumptions;
- a concise, constructive PR summary.
