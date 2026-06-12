# agent-standards — Recog-Omni

Single source of truth for the AI agent behavior contract and agent-file templates shared across all Recog-Omni repos.

## The model

Every Recog-Omni repo follows the same three-layer pattern:

| Layer | Lives in | Synced? |
|-------|----------|---------|
| **Behavior contract** — role, quality bar, issue workflow, definition of done | `.context/06-agent-behavior.md` in each repo | ✅ from `shared/06-agent-behavior.md` here |
| **Canonical agent contract** — context index, verification commands, quick reference, gotchas | `AGENTS.md` in each repo | Bootstrapped from template, then project-owned |
| **Project knowledge** — overview, stack, architecture, conventions, data, testing, deployment | `.context/01–05, 07+` in each repo | Project-owned |

Tool entry files (`CLAUDE.md`, `GEMINI.md`, `HERMES.md`, `.github/copilot-instructions.md`) are **thin pointers** to AGENTS.md plus tool-specific notes only. Codex and most modern tools (Cursor, Windsurf, Zed) read `AGENTS.md` natively, so there is no CODEX.md. Nothing shared is duplicated per tool — that is what prevents drift.

The shared contract is deliberately **stack-agnostic**: it never names a build tool or framework. Each repo's verification commands live in its own `AGENTS.md` (Step 3), which the contract points to.

## What lives here

```
agent-standards/
├── shared/
│   └── 06-agent-behavior.md             ← The behavior contract — edit this, nowhere else
├── templates/
│   ├── AGENTS.md.template               ← Canonical cross-tool contract
│   ├── CLAUDE.md.template               ← Thin pointer (imports AGENTS.md via @AGENTS.md)
│   ├── GEMINI.md.template               ← Thin pointer + Gemini notes
│   ├── HERMES.md.template               ← Thin pointer + Superpowers skills
│   └── copilot-instructions.md.template ← Inline rules + pointer
├── scripts/
│   ├── bootstrap.sh                     ← Onboard a new repo
│   └── sync.sh                          ← Manual sync (when Actions is unavailable)
├── projects.yml                         ← Registry of synced repos (single source for the workflow matrix)
└── .github/workflows/
    └── sync-to-projects.yml             ← Auto-opens PRs when the contract changes
```

## How the sync works

1. Edit `shared/06-agent-behavior.md` and merge to `main`.
2. The `sync-to-projects` workflow fires automatically, reads the registry from `projects.yml`, and opens a PR in each listed repo with the updated file at `.context/06-agent-behavior.md`.
3. Review and merge each PR. Everything else in each project (AGENTS.md, quick-ref, gotchas) is **not touched** — it stays project-specific.

To sync without Actions (or for an immediate one-off):

```bash
./scripts/sync.sh                      # all registered repos
./scripts/sync.sh Recog-Omni/wheresmyjunk   # one repo
```

## Onboarding a new repo

```bash
# From the root of this repo
./scripts/bootstrap.sh Recog-Omni/new-repo "Project Name" "One-line description"
```

This copies the behavior contract, generates `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `HERMES.md`, and `.github/copilot-instructions.md` from templates, and opens a PR in the target repo.

Then:
1. Fill in the `<!-- PROJECT-SPECIFIC -->` sections (verification commands, quick reference, gotchas)
2. Create the remaining `.context/` files for the project
3. Add the repo to `projects.yml` — the sync workflow matrix is generated from it, so this is the only place to register a repo

## Governance rules

- **Contract changes happen here.** Never edit `.context/06-agent-behavior.md` in a project repo — the next sync will overwrite it. Anything project-specific belongs in the project's `AGENTS.md` or other `.context/` files.
- **Knowledge changes happen in the project.** Architecture, conventions, gotchas → the project's `.context/`; never duplicated into tool entry files.
- **Reference implementation:** [Recog-Omni/wheresmyjunk](https://github.com/Recog-Omni/wheresmyjunk) — see its `AGENTS.md`, `.context/`, and `docs/` for the pattern fully applied.

## Required secret

The sync workflow needs a PAT with `contents: write` and `pull-requests: write` on all target repos.

1. Create a [fine-grained PAT](https://github.com/settings/tokens?type=beta) or classic PAT with `repo` scope
2. Add it as `SYNC_PAT` in [agent-standards repository secrets](https://github.com/Recog-Omni/agent-standards/settings/secrets/actions)
