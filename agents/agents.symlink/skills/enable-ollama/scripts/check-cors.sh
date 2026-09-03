#!/usr/bin/env bash
# Checks that OLLAMA_ORIGINS=* is set for the running Ollama process.
# This is required for browser-based clients (Cursor) and ngrok.
set -euo pipefail

# Check current shell environment
if [[ "${OLLAMA_ORIGINS:-}" == "*" ]]; then
  printf 'OK: OLLAMA_ORIGINS=* set in current shell\n'
  exit 0
fi

# On macOS, check the launchd environment if Ollama was started via .app
if [[ "$(uname -s)" == "Darwin" ]]; then
  LAUNCHD_ORIGINS=$(launchctl getenv OLLAMA_ORIGINS 2>/dev/null || true)
  if [[ "$LAUNCHD_ORIGINS" == "*" ]]; then
    printf 'OK: OLLAMA_ORIGINS=* set via launchctl\n'
    exit 0
  fi
fi

printf 'WARN: OLLAMA_ORIGINS is not set to "*"\n' >&2
printf 'CORS errors may occur with browser clients or ngrok.\n' >&2
printf 'Fix: export OLLAMA_ORIGINS="*" and restart Ollama\n' >&2
printf '  macOS app: launchctl setenv OLLAMA_ORIGINS "*"\n' >&2
exit 1