# Rage harness

A personal Codex harness for contributing to the Rage framework itself, not for
building applications with Rage. This is an independent contributor project.

Clone this repository outside your Rage checkout, then run the installer below.
For sandbox images, pin a commit of this repository and run its installer after
cloning Rage. Do not bake feature documents, approvals, credentials, or session
history into an image.

The feature specification source of truth is [rage-rb-fans/rage-feature-specs](https://github.com/rage-rb-fans/rage-feature-specs), published main.
The harness stays local to your Rage checkout. It creates a separate specification Git checkout at `.codex/specs-repository/`, outside Rage's tracked files.

## Install or upgrade

Extract this bundle outside your Rage checkout:

```bash
ruby install.rb /absolute/path/to/rage
```

For an existing installation, review the listed conflicts, then use `--force` to replace the harness files. The installer backs up differing files under .codex/harness-backups/ before replacing them. It preserves existing specification checkouts, local feature state and evidence.

From your Rage checkout, initialize the source:

```bash
ruby .codex/bin/feature_state.rb setup
ruby .codex/bin/feature_state.rb sync
```

Restart the Codex project task and review the changed hooks through /hooks.
The installer excludes /.agents/, /.codex/, and /AGENTS.local.md through Git's local info/exclude.

## Use

Ask: `Use $rage-feature-spec-cycle to refine feature <slug> from the specification repository.`
Existing features use `activate <slug>`; new ones use `create <slug> "<title>"`.
Author canonical spec.md, task files and ADRs using that repository's templates. Ask explicitly for the Specification Judge whenever you want review.

When the agreed feature has status implementation on published main, select its todo task and explicitly approve the current revision before requesting implementation.
Approval binds the task, source commit and all Markdown context. Dirty, offline, unpublished or changed specifications cannot pass the implementation gate.
Local verification does not mark remote documents done: that requires merged implementation evidence.

The same three skills and three agents remain available. Ruby 3.3.0 is still the framework compatibility baseline.
Reasoning defaults: coordinator and Core Implementer use medium; Specification Author and the explicitly requested Specification Judge use high. Agents inherit your selected model. Focused handoffs avoid duplicated work; approval and verification gates are unchanged. Start a new project task to load these settings. Isolation changes are deferred.
Full commands, publishing/gap workflow and legacy migration are in [HARNESS.md](payload/.codex/HARNESS.md).

## Legacy documents

Version-1 private specifications and approvals are not imported automatically. Preserve them, reconcile documents into the source repository's feature/task/ADR structure, then activate the canonical feature with fresh local state and approval. See the migration procedure in HARNESS.md before replacing an active workflow.

## Validation

The Ruby regression suite exercises the workflow against a disposable local Git remote:

```bash
ruby .codex/test/repository_workflow_test.rb
```

The source repository was inspected at e3d88cf0e1cfc3b8d50ef91c49ac6b87215113ef. The upgrade does not modify or publish its existing documents.
