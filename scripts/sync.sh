#!/usr/bin/env bash
# sync.sh — manually sync the shared contracts to every repo in projects.yml
#
# Syncs:
#   shared/06-agent-behavior.md        → .context/06-agent-behavior.md   (all repos)
#   shared/stacks/<stack>.md           → .context/06-stack-<stack>.md    (repos with a stack: field)
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

# Parse "repo stack" pairs from projects.yml (stack may be empty)
PAIRS=$(awk '
  $1=="-" && $2=="repo:" { if (repo != "") print repo, stack; repo=$3; stack="" }
  $1=="stack:"           { stack=$2 }
  END                    { if (repo != "") print repo, stack }
' projects.yml)

if [ $# -ge 1 ]; then
  PAIRS=$(echo "$PAIRS" | awk -v r="$1" '$1==r')
  [ -n "$PAIRS" ] || { echo "✗ $1 is not in projects.yml"; exit 1; }
fi

SRC_SHA=$(git rev-parse --short HEAD)
BRANCH="chore/sync-agent-standards-$SRC_SHA"
ROOT=$(pwd)

echo "$PAIRS" | while read -r REPO STACK; do
  echo "→ Syncing $REPO${STACK:+ (stack: $STACK)}"
  TMP=$(mktemp -d)
  gh repo clone "$REPO" "$TMP/target" -- --depth=1 --quiet
  cd "$TMP/target"
  git checkout -qb "$BRANCH"

  mkdir -p .context
  cp "$ROOT/shared/06-agent-behavior.md" .context/06-agent-behavior.md
  if [ -n "$STACK" ]; then
    if [ -f "$ROOT/shared/stacks/$STACK.md" ]; then
      cp "$ROOT/shared/stacks/$STACK.md" ".context/06-stack-$STACK.md"
    else
      echo "  ✗ shared/stacks/$STACK.md does not exist — skipping stack file"
    fi
  fi
  git add .context/

  if git diff --cached --quiet; then
    echo "  ✓ already up to date"
  else
    git commit -qm "chore: sync agent contracts from agent-standards" \
               -m "Source commit: $SRC_SHA" \
               -m "https://github.com/Recog-Omni/agent-standards"
    git push -q origin "$BRANCH"

    EXISTING=$(gh pr list --head "$BRANCH" --json number --jq '.[0].number' 2>/dev/null || echo "")
    if [ -n "$EXISTING" ]; then
      echo "  ✓ PR #$EXISTING already exists"
    else
      gh pr create \
        --title "chore: sync agent contracts" \
        --body "Automated sync of the shared agent contracts (\`.context/06-agent-behavior.md\`${STACK:+ and \`.context/06-stack-$STACK.md\`}) from [Recog-Omni/agent-standards](https://github.com/Recog-Omni/agent-standards) (source commit \`$SRC_SHA\`). Run manually via \`scripts/sync.sh\`." \
        --head "$BRANCH"
      echo "  ✓ PR opened"
    fi
  fi

  cd "$ROOT"
  rm -rf "$TMP"
done
