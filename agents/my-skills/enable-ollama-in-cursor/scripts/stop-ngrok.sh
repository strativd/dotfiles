#!/usr/bin/env bash
# Stops ngrok tunnel and cleans up state file.
set -euo pipefail

STATE_FILE="$HOME/.cursor/ollama-models"

pkill -f "ngrok http 11434" 2>/dev/null || true
pkill ngrok 2>/dev/null || true

if [[ -f "$STATE_FILE" ]]; then
  rm "$STATE_FILE"
  printf 'OK: ngrok stopped, state file removed\n'
else
  printf 'OK: ngrok stopped (no state file to clean)\n'
fi