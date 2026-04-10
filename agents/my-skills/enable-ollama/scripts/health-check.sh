#!/usr/bin/env bash
# End-to-end health check: install → daemon → model → CORS → /v1 endpoint.
# Runs all checks in sequence, fails fast on first failure.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

printf '=== Ollama Health Check ===\n\n'

printf '1. Checking ollama install...\n'
if ! bash "$SCRIPT_DIR/check-install.sh"; then
  exit 1
fi

printf '\n2. Checking daemon...\n'
if ! bash "$SCRIPT_DIR/check-daemon.sh"; then
  exit 1
fi

printf '\n3. Pulling/verifying model...\n'
if ! bash "$SCRIPT_DIR/pull-model.sh"; then
  exit 1
fi

printf '\n4. Checking CORS...\n'
bash "$SCRIPT_DIR/check-cors.sh" || true  # Warning only, don't fail

printf '\n5. Checking OpenAI-compatible endpoint...\n'
BASE="${OLLAMA_HOST:-http://127.0.0.1:11434}"
if curl -sS --max-time 10 "${BASE}/v1/models" | head -c 800; then
  printf '\n\nOK: Ollama health check passed\n'
  printf 'Endpoint: %s/v1\n' "$BASE"
else
  printf '\nFAIL: GET %s/v1/models failed\n' "$BASE" >&2
  exit 1
fi