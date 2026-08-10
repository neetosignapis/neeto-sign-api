#!/usr/bin/env bash

if [ -n "$(git status --porcelain -- ':(glob)bundled*/**')" ]; then
  echo "ERROR: bundled* is not in sync with source files."
  echo "Run 'yarn build' locally and commit the regenerated files."
  exit 1
fi

echo "bundled* is in sync."
