#!/usr/bin/env bash
# sync.sh — manually sync shared/06-agent-behavior.md to every repo in projects.yml
#
# Same effect as .github/workflows/sync-to-projects.yml, run from a local machine.
# Useful when GitHub Actions is unavailable or for an immediate one-off sync.
#
# Usage:
#   ./scripts/sync.sh            # sync all registered repos
#   ./scripts/sync.sh org/repo   # sync a single repo
#
# Requirements:
#   - gh CLI authenticated with write access to the target repos
#   - Run from anywhere inside the agent-standards repo

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

if [ $# -ge 1 ]; then
  REPOS="$1"
else
  REPOS=$(grep -E '^[[:space:]]+- repo:' projects.yml | awk '{print $3}')
fi

SRC_SHA=$(git rev-parse --short HEAD)
BRANCH="chore/sync-agent-behavior-$(date +%Y%m%d)"
ROOT=$(pwd)

for REPO in $REPOS; do
  echo "→ Syncing $REPO"
  TMP=$(mktemp -d)
  gh repo clone "$REPO" "$TMP/target" -- --depth=1 --quiet
  cd "$TMP/target"
  git checkout -qb "$BRANCH"

  mkdir -p .context
  cp "$ROOT/shared/06-agent-behavior.md" .context/06-agent-behavior.md
  git add .context/06-agent-behavior.md

  if git diff --cached --quiet; then
    echo "  ✓ already up to date"
  else
    git commit -qm "chore: sync agent behavior contract from agent-standards

Source commit: $SRC_SHA
https://github.com/Recog-Omni/agent-standards"
    git push -q origin "$BRANCH"

    EXISTING=$(gh pr list --head "$BRANCH" --json number --jq '.[0].number' 2>/dev/null || echo "")
    if [ -n "$EXISTING" ]; then
      echo "  ✓ PR #$EXISTING already exists"
    else
      gh pr create \
        --title "chore: sync agent behavior contract" \
        --body "Automated sync of \`.context/06-agent-behavior.md\` from [Recog-Omni/agent-standards](https://github.com/Recog-Omni/agent-standards) (source commit \`$SRC_SHA\`). Run manually via \`scripts/sync.sh\`." \
        --head "$BRANCH"
      echo "  ✓ PR opened"
    fi
  fi

  cd "$ROOT"
  rm -rf "$TMP"
done
