#!/usr/bin/env bash
# install-hooks.sh — install the shared git hooks into a target repo.
#
# Usage:
#   # from inside the target repo, pointing at a local agent-standards clone:
#   /path/to/agent-standards/scripts/install-hooks.sh
#
#   # or specify the target repo explicitly:
#   /path/to/agent-standards/scripts/install-hooks.sh /path/to/target-repo
#
# It copies hooks/* into the target repo's .git/hooks/ and makes them
# executable. Re-running is safe (idempotent) — it overwrites the managed hooks.
#
# The pre-push hook runs the target repo's ./.agent-verify script (if present),
# so a failing build is caught locally before it reaches CI.

set -euo pipefail

STANDARDS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-$(pwd)}"

if [ ! -d "$TARGET/.git" ]; then
  echo "✗ $TARGET is not a git repository (no .git directory)" >&2
  exit 1
fi

HOOKS_SRC="$STANDARDS_ROOT/hooks"
HOOKS_DST="$TARGET/.git/hooks"
mkdir -p "$HOOKS_DST"

for hook in "$HOOKS_SRC"/*; do
  name="$(basename "$hook")"
  cp "$hook" "$HOOKS_DST/$name"
  chmod +x "$HOOKS_DST/$name"
  echo "✓ installed $name → $HOOKS_DST/$name"
done

if [ -f "$TARGET/.agent-verify" ]; then
  echo "✓ found .agent-verify — the pre-push gate is active"
else
  echo "⚠ no .agent-verify in $TARGET — the pre-push hook will no-op until you add one"
  echo "  (put the project's verification commands there; see AGENTS.md Step 3)"
fi
