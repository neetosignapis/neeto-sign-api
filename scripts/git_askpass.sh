#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  *Username*)
    printf '%s\n' "x-access-token"
    ;;
  *Password*)
    if [[ -z "${GITHUB_PAT:-}" ]]; then
      echo "GITHUB_PAT is not available." >&2
      exit 1
    fi

    printf '%s\n' "$GITHUB_PAT"
    ;;
  *)
    echo "Unexpected Git credential prompt." >&2
    exit 1
    ;;
esac
