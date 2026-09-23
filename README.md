# Rage harness

Rage harness configures Codex for contributing to the **Rage framework itself**.
It supports a specification-driven workflow: you develop a feature document over
several conversations, request an independent review when useful, and authorize
implementation only after you are satisfied with the specification. This is an
independent contributor project, not an official Rage tool.

The harness supplies specialized **agents**, reusable **skills**, and a small
command-line gate that validates published task status. It does not install Ruby
or provide an isolated execution environment; those belong to your development
setup or sandbox.

## How the pieces fit together

This README explains installation and everyday use. The installed
`<rage>/AGENTS.local.md` contains mandatory agent rules; Codex loads it as project
context. The installed `<rage>/.codex/WORKFLOW_REFERENCE.md` is read only when
command details or recovery instructions are needed. This keeps the always-loaded
rules short without losing the operational reference.

Your work is split across three repositories, each with a different purpose:

| Repository | Purpose |
| --- | --- |
| Your Rage checkout | Framework code, RSpec tests, and contribution documentation. |
| [rage-feature-specs](https://github.com/rage-rb-fans/rage-feature-specs) | Authoritative feature specifications, implementation tasks, and architectural decisions. |
| `rage-harness` (this repository) | The agent definitions, skills, validation command, and installer that support the workflow. |

In the paths below, `<rage>` means the root of your framework checkout. After
installation and specification setup, the relevant folders look like this:

```text
rage/                              # Framework checkout (<rage>)
├── .git/                          # Framework Git history and remotes
├── lib/
├── AGENTS.local.md                # Installed harness instructions
├── .agents/
│   └── skills/                    # Reusable workflow instructions
└── .codex/
    ├── agents/                    # Author, judge, and implementer configurations
    └── specs-repository/          # Nested feature-specs checkout
        ├── .git/                  # Separate specification Git history/remotes
        ├── features/              # Feature documents, tasks, statuses, and ADRs
        └── .workflow/evidence/    # Optional local, gitignored reports
```

The installer adds `/.agents/`, `/.codex/`, and `/AGENTS.local.md` to the Rage
checkout's local Git exclude file (`<rage>/.git/info/exclude` in a regular clone).
This works like `.gitignore`, but does not change Rage's tracked `.gitignore`.
Rage's Git repository therefore ignores the installed harness and nested
specification checkout.

Rage does not track the specification files. They are tracked by the separate Git
repository at `<rage>/.codex/specs-repository/`, which has its own history and
remote. Framework changes go to your Rage fork; specification changes go to
`rage-rb-fans/rage-feature-specs`. Neither belongs in `rage-harness`.

Task lifecycle state lives directly in the specification task documents. Optional
local reports live under the specification checkout's gitignored `.workflow/`
directory; the Rage checkout has no separate feature-state directory.

## Install in a Rage checkout

### 1. Choose where Codex will run

You need an existing Rage checkout, Git, Ruby, and Codex. Rage's minimum supported
Ruby version is **3.3.0**; implementation agents must preserve that baseline.

Run all installation commands in the environment where Codex will work. If you
use a sandbox, open a shell inside it and use its Rage checkout path, such as
`/home/agent/workspace/rage`. Installing on your Mac does not install the harness
inside a separate sandbox.

### 2. Copy the harness into Rage

Clone `rage-harness` outside `<rage>` and run its installer from the
`rage-harness` directory. This source clone is separate; the installed harness
files will be copied inside `<rage>`. Replace `/absolute/path/to/rage` with the
framework checkout you want Codex to use:

```bash
git clone https://github.com/alex-rogachev/rage-harness.git
cd rage-harness
ruby install.rb /absolute/path/to/rage
```

### 3. Set up the specification repository

Run these commands from `<rage>`. `setup` creates the nested checkout at
`<rage>/.codex/specs-repository/`; `sync` updates that specification repository's
clean `main` branch without discarding local edits. It does not update Rage's branch:

```bash
cd /absolute/path/to/rage
ruby .codex/bin/spec_workflow.rb setup
ruby .codex/bin/spec_workflow.rb sync
```

### 4. Load the harness in Codex

Start a new Codex task with `<rage>` as its working directory so it loads the
project configuration. In a
sandbox, Codex itself must run there; a desktop task on your Mac does not move
inside the sandbox automatically.

A custom image can include a pinned copy of `rage-harness`, but its installer
still needs to run after the Rage checkout exists. Keep credentials, working
specifications, and approval state out of the image.

## Work on a feature

### 1. Develop the specification

Start by describing the feature and asking for the specification workflow:

> Use $rage-feature-spec-cycle to draft a specification for [feature]. Do not implement it yet.

The Specification Author develops the feature document, breaks implementation
into tasks, and records significant decisions in architectural decision records
(ADRs). You can refine these documents through as many iterations as needed.
Finishing a conversation does not approve a task or trigger implementation.

For an existing feature, give its slug (the directory name under
`<rage>/.codex/specs-repository/features/`) and the change you want:

> Use $rage-feature-spec-cycle to refine feature [slug]. Focus on cancellation and Fiber cleanup.

### 2. Request a review when you want one

When you want another assessment, ask explicitly:

> Run the Specification Judge on this feature and its proposed tasks.

The judge checks requirements, logic, security, architecture, and applicable
Fiber/Iodine risks. It is read-only and runs only on request. Its verdict is advice
for you and the author; even a positive verdict does not approve implementation.

### 3. Approve and publish one task

Parent specifications have no lifecycle status. Each task moves independently
through `draft`, `ready-for-development`, and `done`. When you approve a task,
change its status to `ready-for-development`; publish that specification change
only when explicitly requested.

Before implementation, the workflow synchronizes published `main`, checks the
named task status, and reports the exact specification commit. A dirty, divergent,
or unpublished checkout cannot pass this gate.

Publishing requires write access to the specification remote. If your sandbox
has no GitHub write credentials, export the changes and publish them from your
Mac, then sync inside the sandbox. The exact helper commands are in
[the workflow reference](payload/.codex/WORKFLOW_REFERENCE.md#workflow).

### 4. Implement the named task

After approval, request implementation:

> Use $rage-implement-approved-feature to implement features/SLUG/tasks/TASK.md.

The Core Implementer changes Rage code and tests for that task. If it discovers
a material gap in the requirements, it pauses and explains the decision needed.
You can return the task to `draft`, amend it, and publish it as
`ready-for-development` again;
the implementer must not silently invent requirements or rewrite the specification.

### 5. Verify and publish the contribution

Ask for `$rage-contribution-check` to review coverage and verification evidence.
Local verification does not change canonical task status, publish code, or mean
that a contribution has merged. Publishing Rage code is a separate, explicitly
requested action.

After the implementation merges, request an update to the specification repository
to record the result and mark the completed task `done`. The parent task checklist
can summarize progress without imposing a feature-wide implementation gate.

## Agent responsibilities and reasoning

| Role | Responsibility | Reasoning effort |
| --- | --- | --- |
| Coordinator | Route requests, check workflow gates, and inspect results. | Medium |
| Specification Author | Draft and refine feature documents and tasks. | High |
| Specification Judge | Independently review specifications on request. | High |
| Core Implementer | Implement the approved task and its tests. | Medium |

These settings control reasoning effort, not model selection: the specialist
agents inherit your chosen model. Focused handoffs reduce duplicated investigation
without skipping required reading or checks. Actual token savings are not guaranteed.

Workflow instructions are not a security sandbox. Filesystem isolation, network
policy, and access to credentials must be configured separately.

## Upgrade an installation

Stop any active implementation agent before upgrading. Update the `rage-harness`
source clone to the revision you want, then run its installer against the same
Rage checkout. Updating the source clone alone does not update installed files.
If files differ, it stops and lists the conflicts. Review those differences before
merging your customizations or choosing to rerun with `--force`.

Forced replacement backs up differing files under
`<rage>/.codex/harness-backups/` and preserves the specification checkout. It also
backs up and removes obsolete phase hooks. Start a new Codex task after upgrading.
If an old `.codex/features/` directory exists, move useful reports into the
specification checkout's `.workflow/evidence/` directory and remove the obsolete
state manually.

The installer does not remove obsolete files. If upgrading from a version with
`<rage>/.codex/HARNESS.md`, preserve any custom notes and remove that old reference
manually after confirming `WORKFLOW_REFERENCE.md` is installed.

## Test the harness

From the root of the **rage-harness source clone** (not the Rage checkout), run:

```bash
ruby payload/.codex/test/repository_workflow_test.rb
```

The regression suite uses a disposable local Git remote to exercise the workflow;
it does not publish to GitHub. Passing it does not replace checking that your Codex
installation loads the agents and skills correctly.

See [WORKFLOW_REFERENCE.md](payload/.codex/WORKFLOW_REFERENCE.md) for the complete command reference,
state transitions, and specification-gap procedures.
