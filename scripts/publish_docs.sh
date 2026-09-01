#!/usr/bin/env bash
set -euo pipefail

readonly SOURCE_REMOTE="origin"
readonly SOURCE_BRANCH="main"
dry_run=false
if [[ "${1:-}" == "--dry-run" ]]; then
  dry_run=true
  shift
fi

if (( $# > 0 )); then
  echo "Usage: $0 [--dry-run]" >&2
  exit 2
fi

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

require_command git
require_command yarn
require_command op

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Run this command from the neeto-sign-api repository." >&2
  exit 1
}
cd "$repo_root"

docs_publish_env_file="$repo_root/.env"
if [[ ! -f "$docs_publish_env_file" ]]; then
  echo ".env is missing from the repository." >&2
  exit 1
fi

github_pat_ref=$(sed -n 's/^GITHUB_PAT=//p' "$docs_publish_env_file" | tail -n 1)
github_pat_ref="${github_pat_ref#[\"\']}"
github_pat_ref="${github_pat_ref%[\"\']}"
if [[ "$github_pat_ref" != op://* ]]; then
  echo ".env must set GITHUB_PAT to an op:// 1Password reference, not the token itself." >&2
  exit 1
fi

unset GITHUB_PAT

if [[ "$dry_run" == true ]]; then
  echo "Checking 1Password CLI access and publishing credential..."
  op run --env-file="$docs_publish_env_file" -- \
    bash "$repo_root/scripts/check_credentials.sh"
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Note: local changes are present and will be ignored; only ${SOURCE_REMOTE}/${SOURCE_BRANCH} is published."
fi

if [[ "$(git rev-parse --is-shallow-repository)" == "true" ]]; then
  echo "Fetching the complete repository history..."
  git fetch --unshallow "$SOURCE_REMOTE"
fi

echo "Fetching ${SOURCE_REMOTE}/${SOURCE_BRANCH}..."
git fetch "$SOURCE_REMOTE" "$SOURCE_BRANCH"

source_ref="refs/remotes/${SOURCE_REMOTE}/${SOURCE_BRANCH}"
source_commit=$(git rev-parse --verify "${source_ref}^{commit}")
echo "Source commit: $source_commit"

publish_worktree=$(mktemp -d "${TMPDIR:-/tmp}/neeto-sign-api-docs-publish.XXXXXX")
worktree_added=false

cleanup() {
  if [[ "$worktree_added" == true ]]; then
    git -C "$repo_root" worktree remove --force -- "$publish_worktree" >/dev/null 2>&1 || true
  elif [[ -d "$publish_worktree" ]]; then
    rmdir "$publish_worktree" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

git worktree add --detach "$publish_worktree" "$source_ref" >/dev/null
worktree_added=true

echo "Installing dependencies for the isolated source commit..."
HUSKY=0 yarn --cwd "$publish_worktree" install --frozen-lockfile --non-interactive

echo "Building OpenAPI bundles..."
yarn --cwd "$publish_worktree" build

echo "Checking documentation links..."
(
  cd "$publish_worktree"
  bash .neetoci/scripts/check_links.sh
)

echo "Verifying generated bundles..."
(
  cd "$publish_worktree"
  bash .neetoci/scripts/validate_bundled.sh
)

if [[ "$dry_run" == true ]]; then
  echo "Validation passed. Dry run complete; nothing was published."
  exit 0
fi

echo "Validation passed. Requesting the publishing credential from 1Password..."
op run --env-file="$docs_publish_env_file" -- \
  bash "$repo_root/scripts/push_docs.sh" "$publish_worktree" "$source_commit"
