#!/usr/bin/env bash
# Verifies the Ollama endpoint is reachable and returns model list.
# Works for both localhost and ngrok URLs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

BASE_URL=$(bash "$SCRIPT_DIR/get-url.sh" "${1:+$1}")

printf 'Verifying Ollama endpoint at %s...\n' "$BASE_URL"

if ! curl -sS --max-time 10 "${BASE_URL}/models" | head -c 800; then
  printf '\nFAIL: GET %s/models failed\n' "$BASE_URL" >&2
  printf 'Ensure Ollama is running and the URL is correct.\n' >&2
  exit 1
fi

printf '\n\nOK: endpoint verified at %s\n' "$BASE_URL"