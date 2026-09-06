# Dotfiles

A personal macOS configuration repository that keeps every piece of system and
tool configuration versioned in one place and mirrors it onto a machine
through symlinks. Everything is organized by topic, not by file type.

## Language

### Structure

**Topic**:
A top-level directory representing one area of the machine — `zsh`, `git`,
`homebrew`, `pi`, and so on. A topic owns its config, its installer, and its
symlinks together.
_Avoid_: module, package, plugin

**Adapter**:
A topic that maps one coding agent's configuration directory into this repo
(`claude`, `cursor`, `pi`, `opencode`). An adapter exists so a tool's config
lives in the repo while the tool itself keeps writing to its normal location.
_Avoid_: integration, bridge

### Linking

**Symlink file** (`.symlink`):
A repo file or directory that is mirrored into `$HOME` with a leading dot and
no extension. `gitconfig.symlink` becomes `~/.gitconfig`. A symlink
_directory_ is recursed: intermediate directories are created real, and only
leaf entries are linked.
_Avoid_: dotfile (too ambiguous — the whole repo is dotfiles)

**Link root**:
The top of a symlink tree — the only level that gains the leading dot.
Everything below maps verbatim.
_Avoid_: source, parent

**Link file** (`.link`):
A one-line file whose first line names where the link should be created,
used for targets outside `$HOME` and for renames.
_Avoid_: redirect

**Link-children sentinel** (`.link-children`):
A marker file that says: link each of my siblings whole, and leave my
directory itself real. Used when a target directory must stay a real
directory (e.g. `~/.agents/skills`).
_Avoid_: glob link, whole-link marker

**Local overlay** (`.local/`):
An untracked directory inside a symlink tree whose contents are merged into
the same target as its parent. Directory-shaped content that must exist on
the machine but never be committed.
_Avoid_: private dir, secret folder

**Target**:
The real path in `$HOME` (or beyond) that a symlink points at. The target
never contains a `.local` path.

### Lifecycle

**Bootstrap** (`script/bootstrap` / `dot --sync`):
The act of establishing the symlink set on a machine. Re-running it is safe;
it reconciles links rather than replacing configurations.
_Avoid_: install (reserved for installers)

**Installer** (`*/install.sh`):
A per-topic script that installs or updates software. Run by `script/install`.
A topic may have an installer without any symlinks and vice versa.
_Avoid_: setup script

**Setup** (`dot --start`):
A full new-machine bring-up: bootstrap, install, brew, macOS defaults.
_Avoid_: install (that's per-topic only)

### Shell

**Topic load order**:
The fixed sequence in which topic `.zsh` files are sourced: all `path.zsh`
first, all other `.zsh` next, all `completion.zsh` last.
_Avoid_: source order (too vague)

**Machine-local config** (`~/.localrc`):
Untracked, per-machine shell settings sourced after the tracked config.
Secrets and machine quirks live here, never in the repo.
_Avoid_: override file

### Agent skills

**Shared skills runtime** (`~/.agents/skills`):
A single real directory in `$HOME` that every coding agent points at. Authored
skills appear here as symlinks into this repo; external installs land here as
real directories.
_Avoid_: skills dir, skill path

**Authored skill**:
A skill written in this repo, tracked under
`agents/agents.symlink/skills/` (publishable) or its `.local/` overlay
(must not be committed).
_Avoid_: custom skill, local skill

**External skill**:
A skill installed from outside the repo by the `skills` CLI, recorded in
`.skill-lock.json` so it can be restored on a new machine.
_Avoid_: downloaded skill, third-party skill
