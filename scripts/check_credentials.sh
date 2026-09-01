#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${GITHUB_PAT:-}" ]]; then
  echo "GITHUB_PAT was not resolved by 1Password." >&2
  exit 1
fi

if [[ "$GITHUB_PAT" == op://* ]]; then
  echo "GITHUB_PAT is still an unresolved 1Password reference." >&2
  exit 1
fi

echo "1Password CLI access and publishing credential are configured."
