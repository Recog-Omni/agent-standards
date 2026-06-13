# agent-standards — Recog-Omni

Single source of truth for the AI agent behavior contract and agent-file templates shared across all Recog-Omni repos.

## The model

Every Recog-Omni repo follows the same three-layer pattern:

| Layer | Lives in | Synced? |
|-------|----------|---------|
| **Behavior contract** — role, quality bar, issue workflow, definition of done | `.context/06-agent-behavior.md` in each repo | ✅ from `shared/06-agent-behavior.md` here |
| **Stack contract** — rules shared by every repo on the same tech stack (e.g. KMP) | `.context/06-stack-<stack>.md` in each repo with a `stack:` field | ✅ from `shared/stacks/<stack>.md` here |
| **Canonical agent contract** — context index, verification commands, quick reference, gotchas | `AGENTS.md` in each repo | Bootstrapped from template, then project-owned |
| **Project knowledge** — overview, stack, architecture, conventions, data, testing, deployment | `.context/01–05, 07+` in each repo | Project-owned |

Tool entry files (`CLAUDE.md`, `GEMINI.md`, `HERMES.md`, `.github/copilot-instructions.md`) are **thin pointers** to AGENTS.md plus tool-specific notes only. Codex and most modern tools (Cursor, Windsurf, Zed) read `AGENTS.md` natively, so there is no CODEX.md. Nothing shared is duplicated per tool — that is what prevents drift.

The shared contract is deliberately **stack-agnostic**: it never names a build tool or framework. Each repo's verification commands live in its own `AGENTS.md` (Step 3), which the contract points to.

## What lives here

```
agent-standards/
├── shared/
│   ├── 06-agent-behavior.md             ← The behavior contract — edit this, nowhere else
│   └── stacks/
│       └── kmp.md                       ← KMP stack contract (Dispatchers, expect/actual, K/N gotchas)
├── templates/
│   ├── AGENTS.md.template               ← Canonical cross-tool contract
│   ├── CLAUDE.md.template               ← Thin pointer (imports AGENTS.md via @AGENTS.md)
│   ├── GEMINI.md.template               ← Thin pointer + Gemini notes
│   ├── HERMES.md.template               ← Thin pointer + Superpowers skills
│   └── copilot-instructions.md.template ← Inline rules + pointer
├── hooks/
│   └── pre-push                         ← Local verification gate (runs a repo's .agent-verify)
├── scripts/
│   ├── bootstrap.sh                     ← Onboard a new repo
│   ├── sync.sh                          ← Manual sync (when Actions is unavailable)
│   └── install-hooks.sh                 ← Install the shared git hooks into a repo
├── projects.yml                         ← Registry of synced repos (single source for the workflow matrix)
└── .github/workflows/
    └── sync-to-projects.yml             ← Auto-opens PRs when the contract changes
```

## How the sync works

1. Edit `shared/06-agent-behavior.md` (or a stack contract under `shared/stacks/`) and merge to `main`.
2. The `sync-to-projects` workflow fires automatically, reads the registry from `projects.yml`, and opens a PR in each listed repo with the updated contract at `.context/06-agent-behavior.md` — plus `.context/06-stack-<stack>.md` for repos that declare a `stack:` field.
3. Review and merge each PR. Everything else in each project (AGENTS.md, quick-ref, gotchas) is **not touched** — it stays project-specific.

To sync without Actions (or for an immediate one-off):

```bash
./scripts/sync.sh                      # all registered repos
./scripts/sync.sh Recog-Omni/wheresmyjunk   # one repo
```

## Local verification gate (pre-push hook)

While hosted CI minutes are limited and iOS builds run on self-hosted runners, the first line of defense is local: a `pre-push` git hook that runs the repo's verification commands before a push completes, so a broken commit never reaches CI.

**Per developer, per repo, once:**

```bash
# from inside the target repo
/path/to/agent-standards/scripts/install-hooks.sh
```

The hook runs the repo's `./.agent-verify` script — a short shell script holding that project's verification commands (the same ones in its `AGENTS.md` Step 3). A repo with no `.agent-verify` is unaffected (the hook no-ops). Emergency bypass: `git push --no-verify`.

Each repo owns its `.agent-verify`. Example for a KMP repo:

```bash
#!/usr/bin/env bash
set -e
./gradlew :composeApp:compileDebugKotlinAndroid
./gradlew :composeApp:compileKotlinIosSimulatorArm64
```

Hooks live in `.git/hooks/` and are **not** version-controlled, so each clone installs them once. The hook script itself is maintained here in `hooks/` — re-run `install-hooks.sh` to pick up updates.

## Onboarding a new repo

```bash
# From the root of this repo
./scripts/bootstrap.sh Recog-Omni/new-repo "Project Name" "One-line description" [stack]
```

This copies the behavior contract (plus the stack contract when `[stack]` is given, e.g. `kmp`), generates `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `HERMES.md`, and `.github/copilot-instructions.md` from templates, and opens a PR in the target repo.

Then:
1. Fill in the `<!-- PROJECT-SPECIFIC -->` sections (verification commands, quick reference, gotchas)
2. Create the remaining `.context/` files for the project
3. Add the repo to `projects.yml` — the sync workflow matrix is generated from it, so this is the only place to register a repo

## Governance rules

- **Contract changes happen here.** Never edit `.context/06-agent-behavior.md` or `.context/06-stack-*.md` in a project repo — the next sync will overwrite them. Anything project-specific belongs in the project's `AGENTS.md` or other `.context/` files.
- **Stack contracts hold rules shared by a tech stack, not by one project.** A rule true for every KMP repo (e.g. no `Dispatchers.IO` in `commonMain`) goes in `shared/stacks/kmp.md`; a rule about one project's modules or libraries stays in that project.
- **Knowledge changes happen in the project.** Architecture, conventions, gotchas → the project's `.context/`; never duplicated into tool entry files.
- **Reference implementation:** [Recog-Omni/wheresmyjunk](https://github.com/Recog-Omni/wheresmyjunk) — see its `AGENTS.md`, `.context/`, and `docs/` for the pattern fully applied.

## Required secret

The sync workflow needs a PAT with `contents: write` and `pull-requests: write` on all target repos.

1. Create a [fine-grained PAT](https://github.com/settings/tokens?type=beta) or classic PAT with `repo` scope
2. Add it as `SYNC_PAT` in [agent-standards repository secrets](https://github.com/Recog-Omni/agent-standards/settings/secrets/actions)
