# Rage harness

Rage harness configures Codex for contributing to the **Rage framework itself**.
It supports a specification-driven workflow: you develop a feature document over
several conversations, request an independent review when useful, and authorize
implementation only after you are satisfied with the specification. This is an
independent contributor project, not an official Rage tool.

The harness supplies three kinds of tools. **Agents** perform specialized work,
**skills** describe reusable procedures, and **hooks** check actions against the
current workflow state. It does not install Ruby or provide an isolated execution
environment; those belong to your development setup or sandbox.

## How the pieces fit together

Your work is split across three repositories, each with a different purpose:

| Repository | Purpose |
| --- | --- |
| Your Rage checkout | Framework code, RSpec tests, and contribution documentation. |
| [rage-feature-specs](https://github.com/rage-rb-fans/rage-feature-specs) | Authoritative feature specifications, implementation tasks, and architectural decisions. |
| `rage-harness` (this repository) | The agent definitions, skills, hooks, and installer that support the workflow. |

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
    ├── hooks/                     # Installed workflow hooks
    ├── features/                  # Created as you work: approvals and evidence
    └── specs-repository/           # Nested feature-specs checkout
        ├── .git/                  # Separate specification Git history/remotes
        └── features/              # Feature documents, tasks, and ADRs
```

The installer adds `/.agents/`, `/.codex/`, and `/AGENTS.local.md` to the Rage
checkout's local Git exclude file (`<rage>/.git/info/exclude` in a regular clone).
This works like `.gitignore`, but does not change Rage's tracked `.gitignore`.
Rage's Git repository therefore ignores the installed harness, the nested
specification checkout, and local approval/evidence files.

Rage does not track the specification files. They are tracked by the separate Git
repository at `<rage>/.codex/specs-repository/`, which has its own history and
remote. Framework changes go to your Rage fork; specification changes go to
`rage-rb-fans/rage-feature-specs`. Neither belongs in `rage-harness`.

Files under `<rage>/.codex/features/` record local approvals and review evidence;
they do not contain the authoritative feature documents. Git exclusions prevent
new files from being added normally, but do not untrack files already committed
or provide any security protection.

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
ruby .codex/bin/feature_state.rb setup
ruby .codex/bin/feature_state.rb sync
```

### 4. Load the harness in Codex

Start a new Codex task with `<rage>` as its working directory so it loads the
project configuration, and review the installed hooks through `/hooks`. In a
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
Finishing a conversation does not approve the feature or trigger implementation.

For an existing feature, give its slug (the directory name under
`<rage>/.codex/specs-repository/features/`) and the change you want:

> Use $rage-feature-spec-cycle to refine feature [slug]. Focus on cancellation and Fiber cleanup.

### 2. Request a review when you want one

When you want another assessment, ask explicitly:

> Run the Specification Judge on this feature and its proposed tasks.

The judge checks requirements, logic, security, architecture, and applicable
Fiber/Iodine risks. It is read-only and runs only on request. Its verdict is advice
for you and the author; even a positive verdict does not approve implementation.

### 3. Publish and approve the agreed specification

Once you are satisfied, ask the author to prepare the specification for
implementation. There are two separate approval steps:

1. Publish the agreed documents with feature status `implementation` to the
   specification repository's `main` branch. Ask explicitly for publication;
   drafting or reviewing a document does not authorize a commit or push.
2. Sync that published revision into the specification checkout, select a `todo`
   task, and explicitly approve it locally before asking for implementation.

Approval records the task, the specification repository's source commit, and a
fingerprint of all Markdown files in that repository. If that context changes,
the new revision must be inspected and reapproved. Implementation requires a
clean, published specification checkout and a successful fetch; unpublished or
offline drafting can continue, but cannot pass the implementation gate.

Publishing requires write access to the specification remote. If your sandbox
has no GitHub write credentials, export the changes and publish them from your
Mac, then sync inside the sandbox. The exact helper commands are in
[the workflow reference](payload/.codex/HARNESS.md#typical-prompts).

### 4. Implement the selected task

After approval, request implementation:

> Use $rage-implement-approved-feature to implement the selected approved task.

The Core Implementer changes Rage code and tests for that task. If it discovers
a material gap in the requirements, it pauses and explains the decision needed.
You can request a specification amendment and reapprove the published revision;
the implementer must not silently invent requirements or rewrite the specification.

### 5. Verify and publish the contribution

Ask for `$rage-contribution-check` to review coverage and verification evidence.
Local verification records that the selected task has been checked; it does not
publish code or mean that a contribution has merged. Publishing Rage code is a
separate, explicitly requested action.

After the implementation merges, request an update to the specification repository
to record the result and mark the completed task `done`. The feature becomes
`done` only when all its tasks and acceptance criteria are complete.

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

Hooks provide workflow guardrails, not a security sandbox. Filesystem isolation,
network policy, and access to credentials must be configured separately.

## Upgrade an installation

Stop any active implementation agent before upgrading. Update the `rage-harness`
source clone to the revision you want, then run its installer against the same
Rage checkout. Updating the source clone alone does not update installed files.
If files differ, it stops and lists the conflicts. Review those differences before
merging your customizations or choosing to rerun with `--force`.

Forced replacement backs up differing files under
`<rage>/.codex/harness-backups/` and preserves the specification checkout, feature
state, and evidence. Start a new
Codex task after upgrading. For an older version-1 private-specification workflow,
follow the [migration instructions](payload/.codex/HARNESS.md#upgrade-from-private-specifications)
first; old approvals are not transferred automatically.

## Test the harness

From the root of the **rage-harness source clone** (not the Rage checkout), run:

```bash
ruby payload/.codex/test/repository_workflow_test.rb
```

The regression suite uses a disposable local Git remote to exercise the workflow;
it does not publish to GitHub. Passing it does not replace checking that your Codex
installation loads the agents and hooks correctly.

See [HARNESS.md](payload/.codex/HARNESS.md) for the complete command reference,
state transitions, and specification-gap procedures.
