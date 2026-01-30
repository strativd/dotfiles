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

### opencode.json

Core OpenCode settings:

- **Provider**: Ollama (local) at `http://localhost:11434/v1`
- **Primary Model**: `kimi-k2.5:cloud` - 32B reasoning model (general tasks)
- **Small Model**: `codellama:7b` - Fast responses for simple queries
- **Available Models**:
  - `qwen3:14b` - General tasks
  - `qwen3-coder` - Long-context coding
  - `deepseek-coder:33b-instruct` - Code review/debugging
  - `codellama:7b` - Fast fallback

Features enabled: file operations, bash execution, auto-compaction, file watching.

### oh-my-opencode.json

Agent and category routing:

| Agent/Category       | Model             | Use Case                 |
| -------------------- | ----------------- | ------------------------ |
| `sisyphus`           | `kimi-k2.5:cloud` | Main orchestrator        |
| `oracle`             | `kimi-k2.5:cloud` | Deep analysis, debugging |
| `explore`            | `kimi-k2.5:cloud` | Codebase search          |
| `librarian`          | `kimi-k2.5:cloud` | Documentation lookup     |
| `multimodal-looker`  | `big-pickle`      | Image/document analysis  |
| `quick`              | `codellama:7b`    | Fast responses           |
| `visual-engineering` | `kimi-k2.5:cloud` | UI/frontend work         |
| `ultrabrain`         | `kimi-k2.5:cloud` | Complex architecture     |

## Shell Aliases

Add to your shell (already loaded via `aliases.zsh`):

| Alias     | Command                                      | Description              |
| --------- | -------------------------------------------- | ------------------------ |
| `ol`      | `ollama`                                     | Shorthand for Ollama CLI |
| `olstart` | `$DOTFILES/opencode/scripts/ollama-start.sh` | Start Ollama server      |
| `olstop`  | `brew services stop ollama`                  | Stop Ollama service      |

### olstart Options

```bash
# Foreground with defaults (64K context, 30m keepalive)
olstart

# Background daemon + warmup primary model
olstart --background --warm

# Custom settings
OLLAMA_CONTEXT_LENGTH=32768 OLLAMA_KEEP_ALIVE=1h olstart
```

## Helper Scripts

All scripts are in `scripts/`:

### ollama-start.sh

Starts Ollama server with proper context length and keepalive settings.

**Environment Variables:**

- `OLLAMA_HOST` - Bind address (default: `127.0.0.1:11434`)
- `OLLAMA_CONTEXT_LENGTH` - Token context window (default: `64000`)
- `OLLAMA_KEEP_ALIVE` - Model unload timeout (default: `30m`)
- `OLLAMA_WARMUP_MODELS` - Models to preload (default: `kimi-k2.5:cloud`)

### ollama-perf.sh

System diagnostics for AI workloads:

```bash
# Show GPU usage, memory, and Ollama status
./scripts/ollama-perf.sh
```

Displays:

- GPU power metrics (macOS)
- Top memory consumers
- Installed Ollama models
- Currently running models
- OpenCode version

### ollama-update.sh

Update all models and OpenCode:

```bash
# Pull latest model versions and upgrade OpenCode
./scripts/ollama-update.sh
```

Updates:

- `qwen3:14b`
- `qwen3-coder`
- `deepseek-coder:33b-instruct`
- `codellama:7b`
- OpenCode CLI

### install.sh

Symlinks configuration to `~/.config/opencode/`:

```bash
# Run via dot command
dot --install

# Or directly
./install.sh
```

Creates links:

- `opencode.json` → `~/.config/opencode/opencode.json`
- `oh-my-opencode.json` → `~/.config/opencode/oh-my-opencode.json`
- `commands/` → `~/.config/opencode/commands/`

## Custom Commands

Place `.md` files in `commands/` to create reusable prompts:

- `review.md` - Commit/branch review prompt

Commands appear in OpenCode as `/review` (based on filename).

## Requirements

- macOS (Apple Silicon optimized)
- [Ollama](https://ollama.ai) installed
- [OpenCode](https://opencode.ai) CLI installed
- 32GB+ RAM recommended for larger models

## Model Recommendations

For M2 Pro with 32GB RAM:

1. **Primary**: `kimi-k2.5:cloud` - Best balance of capability and speed
2. **Coding**: `qwen3-coder` - Long context for large files
3. **Review**: `deepseek-coder:33b-instruct` - Thorough code analysis
4. **Quick**: `codellama:7b` - Fast responses, low memory

Pull models:

```bash
ollama pull kimi-k2.5:cloud
ollama pull qwen3-coder
ollama pull deepseek-coder:33b-instruct
ollama pull codellama:7b
```

## Troubleshooting

### Ollama won't start

```bash
# Check if port 11434 is in use
lsof -nP -iTCP:11434 -sTCP:LISTEN

# Kill existing process
kill $(lsof -t -i:11434)

# Restart
olstart
```

### Models loading slowly

```bash
# Check GPU vs CPU offloading
ollama ps

# View performance metrics
./scripts/ollama-perf.sh
```

### OpenCode can't connect

1. Verify Ollama is running: `curl http://localhost:11434/api/version`
2. Check config is linked: `ls -la ~/.config/opencode/`
3. Restart OpenCode in new shell session

## See Also

- [OpenCode Documentation](https://opencode.ai)
- [oh-my-opencode Plugin](https://github.com/code-yeongyu/oh-my-opencode)
- [Ollama Documentation](https://github.com/ollama/ollama)
