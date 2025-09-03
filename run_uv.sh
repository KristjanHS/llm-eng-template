#!/usr/bin/env bash
set -euo pipefail

if ! command -v uv >/dev/null 2>&1; then
  echo "uv not found. Install from https://astral.sh/uv" >&2
  exit 1
fi

# Create or reuse .venv, then sync dev+test groups
uv sync --group test

# Quick sanity print
uv run python -V
echo "Env ready. Use: 'uv run <cmd>' or '.venv/bin/<cmd>'." 
