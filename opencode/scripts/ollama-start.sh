#!/bin/sh

set -e

usage() {
  cat <<'EOF'
Usage:
  start-ollama.sh [--background] [--warm]

Environment:
  OLLAMA_KEEP_ALIVE       How long to keep models loaded (default: 30m)
  OLLAMA_CONTEXT_LENGTH   Default context length for served models (default: 32768)
  OLLAMA_HOST             Bind host:port (default: 127.0.0.1:11434)
  OLLAMA_WARMUP_MODELS    Space-separated models to warm

Examples:
  # Foreground server with keepalive + 32K context
  OLLAMA_KEEP_ALIVE=30m OLLAMA_CONTEXT_LENGTH=32768 ./start-ollama.sh

  # Background server + warm kimi-k2.5:cloud
  ./start-ollama.sh --background --warm
EOF
}

BACKGROUND=0
WARM=0

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
    --background)
      BACKGROUND=1
      ;;
    --warm)
      WARM=1
      BACKGROUND=1
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 1
      ;;
  esac
done

KEEP_ALIVE="${OLLAMA_KEEP_ALIVE:-30m}"
CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-64000}"
HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
WARMUP_MODELS="${OLLAMA_WARMUP_MODELS:-kimi-k2.5:cloud}"
PORT="${HOST##*:}"

ollama_up() {
  curl -fsS "http://$HOST/api/version" >/dev/null 2>&1
}

listen_pid() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$PORT" -sTCP:LISTEN -t 2>/dev/null | head -n 1
  fi
}

wait_for_port_free() {
  # Wait up to ~10s for the listener to go away.
  i=0
  while [ "$i" -lt 10 ]; do
    pid="$(listen_pid || true)"
    if [ -z "$pid" ]; then
      return 0
    fi
    # If it's already serving HTTP, just keep using it.
    if ollama_up; then
      return 0
    fi
    i=$((i + 1))
    sleep 1
  done
  return 1
}

echo "Starting Ollama..."
echo "  OLLAMA_HOST=$HOST"
echo "  OLLAMA_CONTEXT_LENGTH=$CONTEXT_LENGTH"
echo "  OLLAMA_KEEP_ALIVE=$KEEP_ALIVE"

# If Ollama is already running and reachable, reuse it.
if ollama_up; then
  echo "Ollama already running at http://$HOST (reusing existing server)."

  if [ "$WARM" -eq 1 ]; then
    echo "Warming models (loads into memory): $WARMUP_MODELS"
    for model in $WARMUP_MODELS; do
      echo "  warm: $model"
      ollama run "$model" --think=false --hidethinking --keepalive "$KEEP_ALIVE" "OK" >/dev/null
    done
    echo "Warmup complete."
  fi

  exit 0
fi

# Avoid two servers fighting over the same port.
if command -v brew >/dev/null 2>&1; then
  if brew services list 2>/dev/null | awk '$1=="ollama" && $2!="stopped" {found=1} END{exit !found}'; then
    echo "Stopping brew service: ollama"
    brew services stop ollama >/dev/null 2>&1 || true
    wait_for_port_free || true
  fi
fi

if [ "$BACKGROUND" -eq 1 ]; then
  # If something is still bound to the port but it's not Ollama, bail with a helpful hint.
  pid="$(listen_pid || true)"
  if [ -n "$pid" ] && ! ollama_up; then
    echo "Port $PORT is in use by pid=$pid, but Ollama is not responding on http://$HOST." >&2
    echo "Try: lsof -nP -iTCP:$PORT -sTCP:LISTEN" >&2
    exit 1
  fi

  env \
    OLLAMA_HOST="$HOST" \
    OLLAMA_CONTEXT_LENGTH="$CONTEXT_LENGTH" \
    OLLAMA_KEEP_ALIVE="$KEEP_ALIVE" \
    ollama serve >/tmp/ollama-serve.log 2>&1 &
  PID="$!"
  echo "Ollama running in background (pid=$PID). Logs: /tmp/ollama-serve.log"

  # Wait until the HTTP server responds.
  i=0
  while [ "$i" -lt 60 ]; do
    if curl -fsS "http://$HOST/api/version" >/dev/null 2>&1; then
      break
    fi
    i=$((i + 1))
    sleep 1
  done

  if ! curl -fsS "http://$HOST/api/version" >/dev/null 2>&1; then
    echo "Ollama did not become ready within 60s. See /tmp/ollama-serve.log" >&2
    exit 1
  fi

  if [ "$WARM" -eq 1 ]; then
    echo "Warming models (loads into memory): $WARMUP_MODELS"
    for model in $WARMUP_MODELS; do
      echo "  warm: $model"
      # NOTE: flags must come after MODEL (and are safest before the prompt).
      ollama run "$model" --think=false --hidethinking --keepalive "$KEEP_ALIVE" "OK" >/dev/null
    done
    echo "Warmup complete."
  fi

  exit 0
fi

pid="$(listen_pid || true)"
if [ -n "$pid" ] && ! ollama_up; then
  echo "Port $PORT is in use by pid=$pid, but Ollama is not responding on http://$HOST." >&2
  echo "Try: lsof -nP -iTCP:$PORT -sTCP:LISTEN" >&2
  exit 1
fi

exec env \
  OLLAMA_HOST="$HOST" \
  OLLAMA_CONTEXT_LENGTH="$CONTEXT_LENGTH" \
  OLLAMA_KEEP_ALIVE="$KEEP_ALIVE" \
  ollama serve

