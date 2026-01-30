#!/bin/sh

set -e

echo "=== AI Model Performance ==="

if command -v powermetrics >/dev/null 2>&1; then
  echo ""
  echo "GPU Power (requires sudo):"
  sudo powermetrics --samplers gpu_power -i 1000 -n 1 | grep -E "GPU|Power" || true
else
  echo ""
  echo "powermetrics not found (macOS only)."
fi

echo ""
echo "Top memory consumers:"
top -l 1 -o mem | head -10

if command -v ollama >/dev/null 2>&1; then
  echo ""
  echo "Ollama models:"
  ollama list || true

  echo ""
  echo "Ollama running models:"
  ollama ps || true
else
  echo ""
  echo "ollama not found."
fi

if command -v opencode >/dev/null 2>&1; then
  echo ""
  echo "OpenCode:"
  opencode --version || true
else
  echo ""
  echo "opencode not found."
fi
