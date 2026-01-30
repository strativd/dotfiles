#!/bin/sh

set -e

echo "Updating Ollama models..."
if command -v ollama >/dev/null 2>&1; then
  ollama pull qwen3:14b || true
  ollama pull qwen3-coder || true
  ollama pull deepseek-coder:33b-instruct || true
  ollama pull codellama:7b || true
else
  echo "ollama not found; skipping model updates."
fi

echo ""
echo "Updating OpenCode..."
if command -v opencode >/dev/null 2>&1; then
  opencode upgrade || true
else
  echo "opencode not found; skipping OpenCode update."
fi

echo ""
echo "Done."
