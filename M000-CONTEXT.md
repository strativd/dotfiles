# M000: Initialize GSD Workspace

**Status:** Active  
**Started:** 2026-04-23  
**Scope:** Establish GSD milestone tracking within the dotfiles repository.

## Context

This is a personal dotfiles management system forked from holman/dotfiles, running on macOS with a zsh-based, topical modular structure. The repository is already mature with numerous topics (zsh, git, homebrew, macos, python, node, ruby, vim, tmux, agents, etc.).

## Goal

Bootstrap the `.gsd/` workspace so future changes to dotfiles can be planned, tracked, and executed using GSD milestone workflows.

## Current State

- **Repo:** `~/.dotfiles` (this directory)
- **Platform:** macOS primary, Linux support
- **Shell:** Zsh
- **Topics:** 15+ topical directories
- **Agent stack:** Claude Code, pi-coding-agent, opencode, cursor
- **Package managers:** Homebrew, mise, uv, nvm
- **No GSD workspace:** First time initializing

## Deliverables

- [x] `.gsd/` directory structure created
- [x] `M000-CONTEXT.md` baseline milestone written
- [x] `STATE.md` current state initialized
- [x] `.gsd/metrics.json` created

## Next Steps

Define the first real milestone (M001) for an upcoming dotfiles change, or import an existing task/plan from `.planning/` or `claude/`.
