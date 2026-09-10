# AGENTS.md - Dotfiles Repository Guide

This is a personal dotfiles management system forked from holman/dotfiles,
designed for macOS development environments with a modular, topical structure.

## Project Overview

**Type**: Personal dotfiles repository (not a traditional software project)
**Platform**: Primary macOS, Linux support
**Shell**: Zsh-based with automatic modular loading
**Architecture**: Topical organization with symlinking system

## Core Commands and Operations

### Primary Management Commands

```bash
# Main dotfiles management script (in bin/dot)
dot --help        # Show all available commands
dot --sync       # Sync dotfiles to system via symlinks
dot --install     # Run all topic install.sh scripts
dot --brew        # Install/update Homebrew and packages
dot --macos       # Set macOS system defaults
dot --start       # Complete new laptop setup
dot --edit        # Open dotfiles in $EDITOR
dot --cd          # Change directory to the dotfiles repo
dot --reload      # Reload current terminal session
```

### Installation Scripts

```bash
# Direct script execution
script/bootstrap    # Create symlinks for *.symlink files
script/install      # Run all install.sh scripts in topics
```

## File Organization and Conventions

### Directory Structure

```bash
agents/                  # Shared agent content library
  agents.symlink/        # Linked into ~/.agents
    prompts/             # Leaf-linked into ~/.agents/prompts
    commands/            # Leaf-linked into ~/.agents/commands
    skills/              # Authored skills; .link-children makes
                         # ~/.agents/skills a real dir
      .local/            # Untracked overlay skills; not committed
cursor/                  # Cursor adapter -> ~/.cursor
claude/                  # Claude adapter -> ~/.claude
pi/                      # pi adapter -> ~/.pi/agent
opencode/                # opencode adapter -> ~/.config/opencode
test/                    # Tests for the symlink engine
bin/           # Executable utilities (added to PATH)
script/        # Installation and management scripts
zsh/           # Zsh configurations (aliases, prompt, completion)
git/           # Git configuration and templates
homebrew/      # Homebrew setup and package lists
macos/         # macOS system preferences and defaults
python/        # Python development (uv)
node/          # Node.js development (nvm)
ruby/          # Ruby development setup
vim/           # Vim configuration
tmux/          # Terminal multiplexer config
functions/     # Custom shell functions
system/        # Cross-platform utilities
```

### Special File Types

- `*.symlink` - Files and directories linked into `$HOME` (extension removed,
  leading dot added). Directories are recursed into; see `README.md`.
- `*.link` - A file whose first line is the symlink target. Used for targets
  outside the repo and for renames.
- `.link-children` - Sentinel; links each child of its directory whole.
- `.local/` - Untracked overlay; bootstrap merges its children into the
  parent's target. Unsafe or machine-local directories go here, not in
  the tracked sibling list.
- `agents/agents.symlink/skills/` - Authored skills that are safe to
  publish; tracked in git
- `agents/agents.symlink/skills/.local/` - Authored skills that must not
  be committed; linked the same way, gitignored
- `~/.agents/skills/` - The shared skills runtime directory. Real
  directory in `$HOME`; authored skills (tracked and overlay) are
  symlinks into the repo, external installs and Gaia skills are real
  directories or links outside this repo.
- `*.zsh` - Zsh configuration files automatically loaded
- `path.zsh` - Loaded first for PATH setup
- `completion.zsh` - Loaded last for autocomplete setup
- `install.sh` - Installation scripts for each topic
- `README.md` - Documentation in major directories

## Code Style and Conventions

### Shell Script Patterns

```bash
# Error handling pattern
set -e  # Exit on errors

# Colored output functions (from script/bootstrap)
info() { printf "\r  [ \033[00;34m..\033[0m ] $1\n"; }
success() { printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"; }
fail() { printf "\r\033[2K [\033[0;31mFAIL\033[0m] $1\n"; exit; }

# Command existence check
if (( $+commands[git] )); then
  # git is available
fi
```

### Naming Conventions

- **Aliases**: Hierarchical system
  - Single letters: `g=git`, `l=ls`
  - Compounds: `cm=commit --message`, `co=checkout`
  - Descriptive: `pushon=push origin $(git branch-name)`
- **Functions**: Clear, action-oriented names (`git_branch()`,
  `StripWhitespace()`)
- **Variables**: Uppercase exports (`EDITOR`, `ZSH`), lowercase locals
- **Files**: Descriptive, category-specific names

### Configuration Loading Order

1. `path.zsh` files (PATH setup)
2. All other `.zsh` files (functions, aliases, settings)
3. `completion.zsh` files (autocomplete setup)
4. Initialize Zsh completion system

### Editor Standards (from .editorconfig)

- **Encoding**: UTF-8
- **Line endings**: LF
- **Indentation**: 2 spaces
- **Trailing whitespace**: Trim
- **Final newline**: Required

## Development Workflow

### Making Changes

1. Edit files in topical directories
2. Test changes in current shell session
3. Run `dot --reload` to reload configuration
4. For symlinks: use `dot --sync` after adding new `.symlink` files

### Adding New Topics

1. Create directory: `mkdir newtopic/`
2. Add configuration files as needed:
   - `newtopic/path.zsh` (for PATH additions)
   - `newtopic/config.zsh` (main configuration)
   - `newtopic/completion.zsh` (autocomplete)
   - `newtopic/install.sh` (installation script)
3. Add `newtopic/README.md` for documentation
4. Add `*.symlink` files for home directory placement

### Common Patterns

**Alias Organization** (from zsh/aliases.zsh):

```bash
### CATEGORY #######################
# Comments explain purpose
alias short='long command with parameters'
alias func='function with parameters and flags'
```

**Function Template** (from functions/README.md):

```bash
function_name() {
  # Access args: $1, $2, $3, or $@ for all
  for arg in "$@"; do
    echo "$arg"
  done
}
```

**Symlink File Pattern**:

```bash
# File: vim/vimrc.symlink
" Content will be symlinked as ~/.vimrc
set nocursorline
set background=dark
```

## Testing and Validation

### Manual Testing Approach

- No automated test suite
- Test changes in current shell session
- Verify symlinks with `ls -la ~/.<filename>`
- Check PATH additions with `echo $PATH`
- Validate command availability with `which <command>`

### Bootstrap Verification

```bash
# After running script/bootstrap
script/bootstrap  # Should show "All installed!" message
ls -la ~/.gitconfig  # Should be symlinked to dotfiles
which git  # Should resolve correctly
```

## Environment Variables

### Key Exports

- `ZSH=$DOTFILES` - Path to dotfiles repository
- `PROJECTS=~/Code` - Default projects directory
- `EDITOR` - Preferred text editor (set in ~/.localrc if needed)

### Local Configuration

- Create `~/.localrc` for machine-specific settings
- This file is sourced but not tracked in git
- Override defaults and add sensitive configs here

## Platform-Specific Considerations

### macOS

- Uses Homebrew for package management
- Applies system defaults via `macos/set-defaults.sh`
- Git credential helper: `osxkeychain`
- Keybindings for Terminal.app

### Linux

- Uses system package manager
- Git credential helper: `cache`
- Different system default applications
- Path adjustments for different locations

## Common Operations

### Adding New Aliases

```bash
# Add to appropriate section in zsh/aliases.zsh
### CUSTOM COMMANDS #######################
alias custom='original command --flags'
```

### Creating Custom Functions

```bash
# Add to functions/ or create new topic directory
custom_function() {
  if [[ -z "$1" ]]; then
    echo "Usage: custom_function <argument>"
    return 1
  fi
  # Function logic here
}
```

### Managing Packages

```bash
# Homebrew packages: add to homebrew/install.sh
# Node.js packages: add to node/install.sh
# Python packages: add to python/install.sh
# Ruby gems: add to ruby/install.sh
```

### Managing Agent Skills

Authored skills live in `agents/agents.symlink/skills/` (tracked) or
`agents/agents.symlink/skills/.local/` (gitignored). The runtime
directory is `~/.agents/skills`, a real directory in `$HOME` that
Cursor, Claude, and pi all point at. External installs land there, not in the
repo; only `.skill-lock.json` is committed.

```bash
# Author a skill that is safe to publish
mkdir agents/agents.symlink/skills/my-skill
# write agents/agents.symlink/skills/my-skill/SKILL.md
dot --sync

# Author a skill that must stay untracked (company IP, cookie forges, …)
mkdir agents/agents.symlink/skills/.local/my-private-skill
# write SKILL.md inside that directory
dot --sync

# Install an external skill (recorded in .skill-lock.json)
skills install <source>/<name>

# Restore all external skills on a new machine
skills experimental_install
```

## Important Notes

- **Never commit** sensitive data to this repository
- Use `~/.localrc` for personal configurations
- **Always test** changes before committing
- **Respect the loading order** when adding new configurations
- **Backup existing configs** before running bootstrap on new systems
- The `dot` command is the primary interface for all operations
- Symlink conflicts are handled interactively during bootstrap

## Agent skills

### Issue tracker

Issues are tracked on GitHub (`strativd/dotfiles`) via the `gh` CLI; PRs are not
a triage surface. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles use their default label strings (e.g.
`needs-triage`, `ready-for-agent`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout: one `CONTEXT.md` + `docs/adr/` at the repo root, created
lazily. See `docs/agents/domain.md`.
