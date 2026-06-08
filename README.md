# agent-standards — Recog-Omni

Single source of truth for the AI agent behavior contract shared across all Recog-Omni repos.

## What lives here

```
agent-standards/
├── shared/
│   └── 06-agent-behavior.md        ← The behavior contract — edit this, nowhere else
├── templates/
│   ├── AGENTS.md.template           ← Cross-tool agent index
│   ├── GEMINI.md.template
│   ├── CODEX.md.template
│   ├── HERMES.md.template
│   └── copilot-instructions.md.template
├── scripts/
│   └── bootstrap.sh                 ← Onboard a new repo
├── projects.yml                     ← Registry of synced repos
└── .github/workflows/
    └── sync-to-projects.yml         ← Auto-opens PRs when contract changes
```

## How the sync works

1. Edit `shared/06-agent-behavior.md` and merge to `main`.
2. The `sync-to-projects` workflow fires automatically and opens a PR in each repo listed in the matrix with the updated file at `.context/06-agent-behavior.md`.
3. Review and merge each PR. The rest of each project's agent files (quick-ref, gotchas) are **not touched** — they stay project-specific.

## What is synced vs. what stays per-project

| Synced from this repo | Stays in each project repo |
|-----------------------|---------------------------|
| `.context/06-agent-behavior.md` (role, quality bar, definition of done) | `.context/01–05, 07–08` (project overview, stack, architecture, DB, testing, deployment) |
| | `AGENTS.md`, `GEMINI.md`, `CODEX.md`, `HERMES.md` (project quick-ref, gotchas) |
| | `CLAUDE.md` (Claude-specific deep context) |
| | `.github/copilot-instructions.md` |

## Onboarding a new repo

```bash
# From the root of this repo
./scripts/bootstrap.sh Recog-Omni/new-repo "Project Name" "One-line description"
```

This will:
1. Copy `shared/06-agent-behavior.md` to `.context/` in the target repo
2. Generate starter `AGENTS.md`, `GEMINI.md`, `CODEX.md`, `HERMES.md` from templates
3. Open a PR in the target repo

Then fill in the `<!-- PROJECT-SPECIFIC -->` sections in each generated file.

After bootstrap, add the repo to:
- `projects.yml` (so future syncs include it)
- The `matrix` in `.github/workflows/sync-to-projects.yml`

## Required secret

The sync workflow needs a PAT with `contents: write` and `pull-requests: write` on all target repos.

1. Create a [fine-grained PAT](https://github.com/settings/tokens?type=beta) or classic PAT with `repo` scope
2. Add it as `SYNC_PAT` in [agent-standards repository secrets](https://github.com/Recog-Omni/agent-standards/settings/secrets/actions)
