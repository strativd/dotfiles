#!/usr/bin/env bash
# Checks that ollama CLI is installed and reports version.
set -euo pipefail

if ! command -v ollama >/dev/null 2>&1; then
  printf 'FAIL: ollama not found in PATH\n' >&2
  printf 'Install from https://ollama.com/\n' >&2
  exit 1
fi

VERSION=$(ollama --version 2>/dev/null || echo "unknown")
printf 'OK: ollama found — %s\n' "$VERSION"