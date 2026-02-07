#!/bin/sh

set -e

echo "Updating Ollama models..."
if command -v ollama >/dev/null 2>&1; then
  ollama pull glm-4.7-flash:latest || true
  ollama pull glm-ocr:latest || true
  # Cloud-backed models (glm-4.7:cloud, kimi-k2.5:cloud) use upstream; no pull needed
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
