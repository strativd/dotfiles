# OpenCode Configuration

Local AI coding assistant setup using [OpenCode](https://opencode.ai) with [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) plugin for agent-based development.

## Overview

This directory contains configuration files and helper scripts for running OpenCode with local Ollama models on Apple Silicon. The setup uses a multi-agent architecture with specialized models for different task types.

## Quick Start

```bash
# Install configuration (symlinks to ~/.config/opencode/)
dot --install

# Start Ollama server
olstart --warm

# Launch OpenCode
opencode
```

## File Structure

| File                  | Purpose                                                |
| --------------------- | ------------------------------------------------------ |
| `opencode.json`       | Main OpenCode configuration (models, providers, tools) |
| `oh-my-opencode.json` | Agent routing and category model assignments           |
| `commands/`           | Custom prompt commands for OpenCode                    |
| `scripts/`            | Helper scripts for Ollama operations                   |

## Configuration

See the actual JSON files for current settings:

- **`opencode.json`** - Provider configuration, model definitions, tool permissions, compaction settings
- **`oh-my-opencode.json`** - Agent-to-model routing and category assignments

## Shell Aliases

Source: `aliases.zsh` (automatically loaded)

| Alias     | Description                                 |
| --------- | ------------------------------------------- |
| `ol`      | Shorthand for `ollama`                      |
| `olstart` | Start Ollama server with optimized settings |
| `olstop`  | Stop Ollama service                         |

### olstart Options

```bash
# Foreground with defaults
olstart

# Background daemon + warmup primary model
olstart --background --warm
```

**Environment variables** (see script for defaults):

- `OLLAMA_HOST` - Bind address
- `OLLAMA_CONTEXT_LENGTH` - Context window size
- `OLLAMA_KEEP_ALIVE` - Model cache duration
- `OLLAMA_WARMUP_MODELS` - Models to preload

## Helper Scripts

All scripts support `--help` for usage details.

### ollama-start.sh

Starts Ollama server with proper context length and keepalive settings.

### ollama-perf.sh

System diagnostics showing GPU usage, memory consumption, and Ollama status.

### ollama-update.sh

Pulls latest model versions and updates OpenCode CLI.

### install.sh

Symlinks configuration files to `~/.config/opencode/`.

## Custom Commands

Place `.md` files in `commands/` to create reusable prompts. Files are automatically available as `/<filename>` in OpenCode.

## Requirements

- macOS (Apple Silicon optimized)
- [Ollama](https://ollama.ai) installed
- [OpenCode](https://opencode.ai) CLI installed
- 32GB+ RAM recommended for larger models

## Troubleshooting

### Ollama won't start

```bash
# Check if port 11434 is in use
lsof -nP -iTCP:11434 -sTCP:LISTEN

# Kill existing process and restart
kill $(lsof -t -i:11434) && olstart
```

### Models loading slowly

```bash
# Check GPU vs CPU offloading
ollama ps

# View performance metrics
./scripts/ollama-perf.sh
```

### OpenCode can't connect

1. Verify Ollama: `curl http://localhost:11434/api/version`
2. Check config links: `ls -la ~/.config/opencode/`
3. Restart OpenCode in new shell session

## See Also

- [OpenCode Documentation](https://opencode.ai)
- [oh-my-opencode Plugin](https://github.com/code-yeongyu/oh-my-opencode)
- [Ollama Documentation](https://github.com/ollama/ollama)
