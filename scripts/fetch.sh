#!/usr/bin/env bash
set -euo pipefail

# ---------- CONFIG ----------
ORG="Bonkey-Enterprise"
REPO="BonkeyWonkers"
DEST="/workspaces/$(basename "$PWD")/test"
CACHE_DIR="${HOME}/.cache/interview_bootstrap"
LOGGED_FLAG="${CACHE_DIR}/gh_logged_in"
REFRESHED_FLAG="${CACHE_DIR}/gh_refreshed"
# ----------------------------

mkdir -p "${CACHE_DIR}"

# Ensure GitHub CLI is present
if ! command -v gh >/dev/null 2>&1; then
  echo "❌ GitHub CLI (gh) is not installed in this Codespace."
  echo "   Please install it or add the devcontainer feature: ghcr.io/devcontainers/features/github-cli:1"
  exit 1
fi

# Avoid Codespaces' repo-scoped token being used by gh
if [[ -n "${GITHUB_TOKEN-}" || -n "${GH_TOKEN-}" ]]; then
  echo "ℹ️ Detected GITHUB_TOKEN/GH_TOKEN in env (repo-scoped). Unsetting so you can auth as yourself…"
  unset GITHUB_TOKEN GH_TOKEN
fi

# Login ONCE per user/session (cached)
if [[ ! -f "${LOGGED_FLAG}" ]]; then
  if ! gh auth status -h github.com >/dev/null 2>&1; then
    echo "→ You are not logged in to GitHub CLI. Launching web auth…"
    gh auth login -h github.com --web --git-protocol https
  fi
  touch "${LOGGED_FLAG}"
fi

# Refresh scopes ONCE per user/session (cached)
if [[ ! -f "${REFRESHED_FLAG}" ]]; then
  echo "→ Ensuring required scopes (repo, read:org)…"
  # This will also prompt to authorize SSO if your org requires it
  gh auth refresh -h github.com -s repo -s read:org || true
  touch "${REFRESHED_FLAG}"
fi

# Verify access to private repo before doing anything
if ! gh repo view "${ORG}/${REPO}" >/dev/null 2>&1; then
  cat <<EOF
❌ Cannot access ${ORG}/${REPO}.
   • Make sure you've been added as an Outside Collaborator (Read) on that private repo.
   • If your org uses SSO, authorize GitHub CLI when prompted.
EOF
  exit 1
fi

# If DEST exists, confirm re-install
if [[ -d "${DEST}" ]] && [[ -n "$(ls -A "${DEST}" 2>/dev/null || true)" ]]; then
  echo "🔁 Destination already exists: ${DEST}"
  read -r -p "Re-install (overwrite contents)? [y/N] " ans
  case "${ans:-N}" in
    y|Y|yes|YES)
      echo "→ Clearing ${DEST}…"
      rm -rf "${DEST:?}/"* "${DEST}"/.[!.]* "${DEST}"/..?* 2>/dev/null || true
      ;;
    *)
      echo "↩️  Skipping re-install. Nothing changed."
      exit 0
      ;;
  esac
fi

TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "${TMPDIR}"; }
trap cleanup EXIT

echo "→ Cloning ${ORG}/${REPO}…"
gh repo clone "${ORG}/${REPO}" "${TMPDIR}/_src" -- --depth=1

echo "→ Copying into ${DEST}"
mkdir -p "${DEST}"
cp -a "${TMPDIR}/_src/." "${DEST}/"

# Keep workspace commit-free
rm -rf "${DEST}/.git" || true

# Record provenance for debugging
COMMIT_HASH="$(git -C "${TMPDIR}/_src" rev-parse --short HEAD 2>/dev/null || echo unknown)"
printf "source_repo=%s/%s\ncommit=%s\ndate=%s\n" \
  "${ORG}" "${REPO}" "${COMMIT_HASH}" "$(date -Is)" > "${DEST}/.installed"

echo "✅ Done. Contents of ${DEST}:"
ls -la "${DEST}" | sed -n '1,60p'
