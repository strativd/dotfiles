#!/usr/bin/env bash
# Starts ngrok tunnel to Ollama, captures forwarding URL, writes state file.
# Idempotent — if ngrok is already forwarding :11434, reads existing URL.
set -euo pipefail

STATE_FILE="$HOME/.cursor/ollama-models"
MODEL="${OLLAMA_CURSOR_MODEL:-gemma4}"
NGROK_API="http://127.0.0.1:4040/api/tunnels"

if ! command -v ngrok >/dev/null 2>&1; then
  printf 'FAIL: ngrok not found. Install from https://ngrok.com/\n' >&2
  exit 1
fi

# Check if tunnel already exists
if curl -sS --max-time 3 "$NGROK_API" >/dev/null 2>&1; then
  EXISTING_URL=$(curl -sS "$NGROK_API" 2>/dev/null \
    | grep -o '"public_url":"https://[^"]*"' \
    | head -1 \
    | sed 's/"public_url":"//;s/"//')
  if [[ -n "$EXISTING_URL" ]]; then
    BASE_URL="${EXISTING_URL}/v1"
    mkdir -p "$(dirname "$STATE_FILE")"
    printf 'BASE_URL=%s\nMODEL=%s\nSTARTED=%s\n' \
      "$BASE_URL" "$MODEL" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$STATE_FILE"
    printf 'OK: ngrok tunnel already active at %s\n' "$BASE_URL"
    exit 0
  fi
fi

# Start ngrok in background
printf 'Starting ngrok tunnel on port 11434...\n'
ngrok http 11434 --host-header="localhost:11434" --log=stdout >/dev/null 2>&1 &
NGROK_PID=$!
disown

# Wait for ngrok API to become available
for i in $(seq 1 15); do
  sleep 1
  if curl -sS --max-time 2 "$NGROK_API" >/dev/null 2>&1; then
    break
  fi
  if ! kill -0 "$NGROK_PID" 2>/dev/null; then
    printf 'FAIL: ngrok process exited unexpectedly\n' >&2
    exit 1
  fi
done

# Capture forwarding URL
PUBLIC_URL=$(curl -sS "$NGROK_API" 2>/dev/null \
  | grep -o '"public_url":"https://[^"]*"' \
  | head -1 \
  | sed 's/"public_url":"//;s/"//')

if [[ -z "$PUBLIC_URL" ]]; then
  printf 'FAIL: could not capture ngrok forwarding URL\n' >&2
  exit 1
fi

BASE_URL="${PUBLIC_URL}/v1"
mkdir -p "$(dirname "$STATE_FILE")"
printf 'BASE_URL=%s\nMODEL=%s\nSTARTED=%s\n' \
  "$BASE_URL" "$MODEL" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$STATE_FILE"

printf 'OK: ngrok tunnel active\n'
printf 'BASE_URL=%s\n' "$BASE_URL"
printf 'State written to %s\n' "$STATE_FILE"