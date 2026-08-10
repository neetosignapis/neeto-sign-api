#!/usr/bin/env bash
set -euo pipefail

if ! output=$(yarn check:links 2>&1); then
  echo "$output"
  echo "ERROR: broken links detected. Fix them before merging." >&2
  exit 1
fi

echo "$output"
echo "No broken links."
