#!/usr/bin/env bash
set -euo pipefail

readonly TARGET_REPOSITORY="neetosignapis/neeto-sign-api"
readonly TARGET_BRANCH="main"
readonly TARGET_URL="https://github.com/${TARGET_REPOSITORY}.git"
readonly DOCUMENTATION_URL="https://apidocs.neetosign.com/getting-started/introduction"

if (( $# != 2 )); then
  echo "This is an internal helper. Run 'yarn docs:publish' instead." >&2
  exit 2
fi

readonly publish_worktree="$1"
readonly source_commit="$2"

if [[ -z "${GITHUB_PAT:-}" ]]; then
  echo "GITHUB_PAT was not injected by 1Password." >&2
  exit 1
fi

if [[ "$GITHUB_PAT" == op://* ]]; then
  echo "GITHUB_PAT is still a 1Password reference. Run 'yarn docs:publish'." >&2
  exit 1
fi

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Run this command from the neeto-sign-api repository." >&2
  exit 1
}

if [[ ! -d "$publish_worktree" ]]; then
  echo "The isolated publishing worktree no longer exists." >&2
  exit 1
fi

if [[ "$(git -C "$publish_worktree" rev-parse --verify "HEAD^{commit}")" != "$source_commit" ]]; then
  echo "The validated worktree changed unexpectedly." >&2
  exit 1
fi

export GIT_ASKPASS="$repo_root/scripts/git_askpass.sh"
export GIT_TERMINAL_PROMPT=0
unset GIT_TRACE GIT_TRACE2 GIT_TRACE_PACKET GIT_TRACE_PERFORMANCE GIT_TRACE_SETUP GIT_CURL_VERBOSE

git_with_askpass() {
  git -c credential.helper= "$@"
}

echo "Reading the current ${TARGET_REPOSITORY}:${TARGET_BRANCH} revision..."
target_commit=$(git_with_askpass ls-remote "$TARGET_URL" "refs/heads/$TARGET_BRANCH" | awk 'NR == 1 { print $1 }')

echo "Publishing $source_commit to ${TARGET_REPOSITORY}:${TARGET_BRANCH}..."
if [[ -n "$target_commit" ]]; then
  git_with_askpass -C "$publish_worktree" push \
    "--force-with-lease=refs/heads/${TARGET_BRANCH}:${target_commit}" \
    "$TARGET_URL" "${source_commit}:refs/heads/$TARGET_BRANCH"
else
  git_with_askpass -C "$publish_worktree" push \
    "$TARGET_URL" "${source_commit}:refs/heads/$TARGET_BRANCH"
fi

published_commit=$(git_with_askpass ls-remote "$TARGET_URL" "refs/heads/$TARGET_BRANCH" | awk 'NR == 1 { print $1 }')
if [[ "$published_commit" != "$source_commit" ]]; then
  echo "Publish verification failed: target is at ${published_commit:-<missing>}, expected $source_commit." >&2
  exit 1
fi

echo "Published commit $source_commit successfully."
echo "Mintlify deployment URL: $DOCUMENTATION_URL"
