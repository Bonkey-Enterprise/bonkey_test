#!/usr/bin/env bash
set -euo pipefail

# >>> CHANGE THIS <<<
PRIVATE_REPO_URL="https://github.com/Bonkey-Enterprise/BonkeyWonkers.git"

WORKDIR="$HOME/interview_sandbox"
TMPDIR="$(mktemp -d)"

echo "→ Cloning private repo into: $TMPDIR"
git clone --depth=1 "$PRIVATE_REPO_URL" "$TMPDIR/_src"

echo "→ Copying contents into sandbox: $WORKDIR"
mkdir -p "$WORKDIR"
# Copy EVERYTHING from the private repo into the sandbox (no filters)
cp -a "$TMPDIR/_src/." "$WORKDIR/"

# Optional: remove Git metadata so nothing is tracked
rm -rf "$WORKDIR/.git"

echo "✅ Done. Sandbox now contains:"
ls -la "$WORKDIR" | sed -n '1,50p'
