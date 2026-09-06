# Generalized config-directory symlinks

Date: 2026-09-02

## Problem

This repo was built for classic dotfiles: single files linked to `$HOME/.name`
via the `*.symlink` convention. Modern tools ship *config directories* at
arbitrary paths (`~/.cursor/`, `~/.config/opencode/`, `~/.pi/agent/`), so every
new tool has grown a bespoke bash function in `script/bootstrap`.

Six linking mechanisms coexist today:

| Mechanism | Scope | Wired into `dot --bootstrap`? |
| --- | --- | --- |
| `*.symlink` files | generic, single files | yes |
| `install_agents_dir()` | hardcoded `agents/` + 3 Cursor subdirs | yes |
| `link_my_skills()` | fan-in of `my-skills/*` into `agents/skills/` | yes |
| `install_pi_dir()` | hardcoded per-file links into `~/.pi/agent/` | yes |
| `opencode/scripts/link-config.sh` | files into `~/.config/opencode/` | no |
| `claude/sync.sh` | `CLAUDE.md` into three places | no |

Only the first is generic. The consequences are already visible:

- **Repo pollution.** `~/.cursor/skills` is a whole-directory symlink to
  `agents/skills`, so skill installers write into the git repo. 37 external
  skill directories now live in `.dotfiles`, suppressed by a `.gitignore` rule.
- **Divergent copy-paste.** Two prune loops were written twice and drifted.
  `link_my_skills()` iterates `agents/skills/*/`, and a trailing-slash glob only
  matches entries resolving to real directories, so it can never see a dangling
  symlink. `install_pi_dir()` iterates `*` and does. Result: the dangling
  `agents/skills/enable-ollama-in-cursor` link has survived every bootstrap.
- **Unwired scripts.** `claude/sync.sh` never runs, so `~/.claude/CLAUDE.md` is
  a stale copy rather than a link. `opencode` links were made by hand.
- **Dead references.** `install_pi_dir()` links
  `pi/agent/extensions/rtk.ts`, which does not exist in the repo.

Three requirements the current conventions cannot express:

1. **P1 — deep targets.** `*.symlink` encodes a basename, not a path. It cannot
   reach `~/.config/opencode/opencode.json`.
2. **P2 — co-owned directories.** `~/.cursor` holds tool-written `plugins/`,
   `projects/`, and caches that must stay out of git, so the directory itself
   cannot be a symlink. Individual children must be linked into a real
   directory.
3. **P3 — fan-out.** One source must appear at several targets: `CLAUDE.md` in
   Cursor, Claude, and agents; skills in Cursor, Claude, and pi.

## Constraints

- No new runtime dependencies. `script/bootstrap` runs before Homebrew on a
  fresh machine, so the strategy must be self-contained bash.
- No major migration of the existing repo structure.
- Preserve the `*.symlink` convention for the entries that use it: 11 tracked
  files, plus the generated `git/gitconfig.local.symlink`.

## Background: how other tools solve this

Surveyed GNU Stow, chezmoi, dotdrop, dotbot, yadm, rcm, homeshick, vcsh, and
Nix home-manager. Three findings drove the decision.

**Descending is the mature default; whole-directory linking is the exception.**

| Tool | Directory default | Whole-dir opt-in |
| --- | --- | --- |
| rcm | descend, mkdir real dirs, link files within | `SYMLINK_DIRS` / `-S` |
| homeshick | descend depth-first, tracked only | entry is itself a symlink |
| chezmoi | materialize children (copies) | `exact_` |
| home-manager | whole-dir | `recursive = true` to leaf-link |
| dotdrop | copy | `link_children` to leaf-link |
| Stow | folds: depends on target dir existing | `--no-folding` (global) |

**Stow is the cautionary tale, and we have already hit it.** Stow "folds": if
the target directory is absent it links the whole directory, otherwise it
descends. The standard complaint is that a folded `~/.config/Code` causes
VSCode's runtime files to be written into the git repo. Real repos work around
it with a `NO_FOLD_DIRS` list (one includes `~/.claude`) pre-created so Stow is
forced to link leaves. Our `agents/skills` pollution is the same failure.

**Fan-out is solved everywhere by committing real symlinks into the repo.**
Stow, yadm, rcm, homeshick, and vcsh all give this answer, because git stores
symlinks as blobs. No configuration language is required for P3.

**Filename-encoded link semantics have precedent in this repo's own lineage.**
`DanielThomas/oh-your-dotfiles`, a holman fork, encodes both modes in directory
names at arbitrary depth: a bare directory inside a `*.symlink` tree has its
files linked individually, while a nested directory that itself ends in
`.symlink` is linked whole and not recursed into. `r-richmond/dotfiles`, another
holman fork, instead flattens target paths into filenames using `+` as a path
separator (`symlink.agents+skills` → `~/.agents/skills`); rejected here because
there is no escape for a literal `+` and nesting is more readable.

Known failure modes of filename-encoded conventions, to design against:

- A `.symlink` suffix breaks editor and forge syntax highlighting. This is the
  stated reason `r-richmond` moved the marker to a prefix.
- Attribute parsing on foreign trees is hazardous. chezmoi added `external_`
  because a vendored `run_tests.sh` would otherwise be executed.
- Names cannot express a rename, and they cannot express a target outside the
  repo.

## Decision

Extend `*.symlink` to directories, with **recursion as the default**. Rejected
alternatives: a per-topic `links.conf` manifest (fully expressive, but adds a
config file to maintain and a second place to edit); GNU Stow (adds a Perl
dependency before Homebrew runs, folding is implicit and state-dependent, and it
still cannot fan out).

Underneath the mechanics, the organizing principle is to separate **content**
(what is authored and version-controlled) from **placement** (where each tool
insists on finding it). `agents/` becomes a content library; each tool topic is
a thin adapter that places that content.

### Rule 1 — `*.symlink` file (unchanged)

A file named `NAME.symlink` at depth 1 or 2 links to `$HOME/.NAME`.

Every current `*.symlink` entry is a file, so Rule 2 changes the behavior of
nothing that exists today.

### Rule 2 — `*.symlink` directory (new)

A directory named `NAME.symlink` establishes `$HOME/.NAME` as its target root,
then recurses: intermediate directories are created as **real directories** and
leaf files are symlinked individually.

Only the link root gains a leading dot; nested paths map verbatim. This is
rcm's rule.

```text
opencode/config.symlink/opencode/opencode.json
  → ~/.config/opencode/opencode.json   (real dirs: ~/.config, ~/.config/opencode)
```

Because intermediate directories are real, two topics may both contribute to
`~/.config/` without conflict.

### Rule 3 — nested `*.symlink` entry: link whole

Inside a Rule 2 tree, an entry whose name ends in `.symlink` has the suffix
stripped and is linked **whole**, with no recursion. No dot is added. This is
the explicit "I own this entire directory" opt-in, and it applies to files as
well as directories.

```text
pi/pi.symlink/agent/themes.symlink/   → ~/.pi/agent/themes   (single link)
```

### Rule 4 — `*.link` file: link to the path in its contents

A file named `NAME.link` creates a symlink at `NAME` pointing to the path held
in the file's contents, with a trailing newline stripped and `$HOME` and
`$DOTFILES` expanded. The contents must be a single line that is either
absolute or begins with `$HOME` or `$DOTFILES`; relative paths are rejected,
because they would resolve against the target directory rather than the repo
and are therefore unreadable in review.

This is chezmoi's `symlink_` mechanism. It exists because Rules 1–3 can only
name paths *inside the repo*, and two required links point elsewhere:

- **`$HOME` → `$HOME` fan-out.** The shared skills runtime directory must be
  `~/.agents/skills`. If `~/.cursor/skills` were a whole-dir link to the repo's
  authored skills (Rule 3), Cursor's installer would write into the repo,
  recreating the pollution this design removes.
- **Renames.** `~/.config/mcp/mcp.json` is sourced from
  `pi/agent/mcp.local.json`. Source and target basenames differ, which no
  name-based rule can express.

```text
cursor/cursor.symlink/skills.link   contents: $HOME/.agents/skills
  → ~/.cursor/skills -> ~/.agents/skills
```

If the referent does not exist on a given machine, the resulting link dangles
and the prune pass removes it. This is the desired behavior for machine-local
sources such as `mcp.local.json`.

### Sentinel — `.link-children`

A file named `.link-children` in a directory means: stop recursing, and link
each child of this directory **whole**, as if every child carried a `.symlink`
suffix. The containing target directory is created real.

It is sugar for Rule 3, needed because skills directories hold dozens of
children that are each a unit while the directory itself is co-owned. Required
in three places: agents, pi, and Claude skills.

### Choosing between Rule 3 and Rule 4

Point at the **repo** when only you write to the target. Point at the **`$HOME`
runtime path** when the tool also writes there.

## Algorithm

```text
discover:
  for each entry E matching *.symlink at depth 1..2 under $DOTFILES,
  excluding .git:
    target = $HOME/.<basename E with .symlink stripped>
    if E is a file: link E -> target
    else:           walk(E, target)

walk(src, dst):
  mkdir -p dst                       # real directory, never a symlink
  if src contains .link-children:
    for each child C of src, excluding the ignore list and .link-children:
      link C -> dst/<basename C>     # whole, no recursion
    overlay(src, dst)
    return
  for each entry E in src, excluding the ignore list:
    name = basename E
    if name ends in .link:
      link <expanded contents of E> -> dst/<name minus .link>
    elif name ends in .symlink:
      link E -> dst/<name minus .symlink>   # whole, no recursion
    elif E is a directory:
      walk(E, dst/name)
    else:
      link E -> dst/name
  overlay(src, dst)

overlay(src, dst):
  if src/.local is a real directory (not a symlink):
    if src contains .link-children:
      link each child of src/.local into dst whole
    else:
      walk(src/.local, dst)

prune(dst):
  for each symlink L directly in a managed target directory dst:
    if readlink L resolves under $DOTFILES and L's referent is missing:
      remove L
```

Ignore list: `.DS_Store`, `.git`, `.link-children`, `.local`. Dot-prefixed
entries are otherwise linked normally - `agents/.skill-lock.json` depends
on this, and it must remain a link into the repo so the skills CLI's writes
are captured by git.

Symlinks committed in the repo are resolved to their physical path before
linking, so `$HOME` links point at the real file rather than forming a two-hop
chain. Directories resolve via `(cd "$src" && pwd -P)`; files resolve via
`(cd "$(dirname "$src")" && pwd -P)` joined with the link's own basename after
following it. `readlink -f` is not used because it is unavailable on older
macOS.

### Ownership and pruning

A link in a managed target directory is *owned* if `readlink` resolves to a path
under `$DOTFILES`. Pruning removes owned links whose referent no longer exists.

Known limit, shared with Stow: removing a *declaration* while the source file
still exists leaves a live link behind, because it is not dangling. Undoing a
link is a manual `rm`. Accepted; the alternative is a state file.

### Conflict handling

Reuse the existing `link_file` prompt (skip / overwrite / backup, with
all-variants). One behavior change: a pre-existing **real directory** at an
intermediate path is not a conflict — `mkdir -p` is a no-op and the walk
continues. Only leaf collisions prompt. Today `link_file` prompts on
directories, which is the source of the interactive noise during bootstrap.

### Bugs fixed as part of this work

- `link_file` uses `readlink $dst` unquoted; quote it.
- `install_dotfiles` iterates `$(find ...)`, which word-splits on paths
  containing spaces; switch to `find -print0` with `while read -r -d ''`.
- Two divergent prune loops collapse into one implementation, which removes the
  dangling `agents/skills/enable-ollama-in-cursor` link.
- Drop the link to the nonexistent `pi/agent/extensions/rtk.ts`.
- `~/.claude/CLAUDE.md` becomes a real link instead of a stale copy.
- `find -maxdepth 2` is retained for *discovery* of link roots only; the walk
  below a root is unbounded in depth.

## Target layout

```text
agents/                                # content library
  agents.symlink/
    .skill-lock.json                   → ~/.agents/.skill-lock.json
    prompts/                           → ~/.agents/prompts/*   (leaf links)
      CLAUDE.md -> ../../../claude/claude.symlink/CLAUDE.md
    commands/                          → ~/.agents/commands/*
    skills/
      .link-children                   → ~/.agents/skills/ is a REAL dir
      coding-guidelines/               → ~/.agents/skills/coding-guidelines
      refactor-with-a-kiss/            (one whole-dir link per authored skill)
      ...

cursor/                                # adapter
  cursor.symlink/
    hooks.json                         → ~/.cursor/hooks.json   (newly tracked)
    skills.link                        → ~/.cursor/skills  -> ~/.agents/skills
    prompts.symlink  -> ../../agents/agents.symlink/prompts
    commands.symlink -> ../../agents/agents.symlink/commands

claude/                                # adapter
  claude.symlink/
    CLAUDE.md                          → ~/.claude/CLAUDE.md   (source of truth)
    skills.link                        → ~/.claude/skills -> ~/.agents/skills

pi/                                    # adapter
  pi.symlink/
    agent/
      settings.json                    → ~/.pi/agent/settings.json
      mcp.json                         → ~/.pi/agent/mcp.json
      mcp.local.json                   (gitignored; referent of the .link below)
      prompts.symlink/                 → ~/.pi/agent/prompts
      themes.symlink/                  → ~/.pi/agent/themes
      skills/
        .link-children                 → ~/.pi/agent/skills/ is a REAL dir
        build-vercel-site/             → one whole-dir link per pi skill
        ...
  config.symlink/
    mcp/
      mcp.json.link                    → ~/.config/mcp/mcp.json
                                         -> $DOTFILES/pi/pi.symlink/agent/mcp.local.json

opencode/                              # adapter
  config.symlink/
    opencode/
      opencode.json                    → ~/.config/opencode/opencode.json
      oh-my-opencode.json              → ~/.config/opencode/oh-my-opencode.json
```

`cursor/cursor.symlink/prompts.symlink` uses Rule 3 (points into the repo)
because Cursor never writes to `prompts/`. `skills.link` uses Rule 4 because
Cursor's installer does write to `skills/`.

Adding a new tool means creating one topic directory. No bash, no bootstrap
edit.

## Migration

Existing `*.symlink` files: no change.

| Current | New |
| --- | --- |
| `agents/prompts/` | `agents/agents.symlink/prompts/` |
| `agents/commands/` | `agents/agents.symlink/commands/` |
| `agents/my-skills/<skill>/` | `agents/agents.symlink/skills/<skill>/` |
| `agents/.skill-lock.json` | `agents/agents.symlink/.skill-lock.json` |
| `agents/skills/` (37 external) | deleted; runtime is `~/.agents/skills` |
| `pi/agent/**` | `pi/pi.symlink/agent/**` |
| `opencode/*.json` | `opencode/config.symlink/opencode/*.json` |
| `claude/CLAUDE.md` | `claude/claude.symlink/CLAUDE.md` |

Removed after migration:

- `install_agents_dir()`, `link_my_skills()`, `install_pi_dir()` in
  `script/bootstrap`
- `opencode/scripts/link-config.sh`
- `claude/sync.sh`
- `agents/skills-lock.json` (redundant symlink to `.skill-lock.json`)
- `.gitignore` rule `agents/skills/*`

The `agents/my-skills/` split disappears. It existed only to keep authored
skills out of a runtime directory that lived inside the repo; once the runtime
directory moves to `$HOME`, one authored-skills directory suffices. `agents/`
and `agents/README.md` need rewriting to describe the new layout, as does the
"Managing Agent Skills" section of `AGENTS.md` and the `*.symlink` paragraph of
`README.md`.

External skills are re-installed on a fresh machine with `skills
experimental_install`, driven by the tracked `.skill-lock.json`. This is
unchanged, but it becomes the *only* way external skills arrive, rather than
them being committed-but-ignored inside the repo.

Migration is done topic by topic; each topic is independently bootstrappable, so
`agents` and `cursor` land first and the rest follow.

## Risks

- **Atomic saves replace symlinks.** Tools that write config by creating a
  temp file and renaming over the original will replace a leaf symlink with a
  regular file, silently detaching it from the repo. This affects every
  symlink-based approach. It is a new exposure for `~/.cursor/hooks.json`,
  which is not tracked today. Mitigation: bootstrap reports managed paths that
  are no longer symlinks, so the drift is visible. `~/.cursor/mcp.json` is
  excluded from management for this reason plus the credentials it holds.
- **`~/.claude/skills` may hold real content.** Replacing it with a whole-dir
  link will hide anything not already linked. The `link_file` backup prompt
  covers this, but the directory should be inspected before migrating.
- **Suffix highlighting.** `*.symlink` still breaks syntax highlighting, but
  only for the marker itself. Files *inside* a Rule 2 tree keep their real
  extensions, so all newly tracked configs (`hooks.json`, `settings.json`) are
  highlighted correctly. This is a net improvement over adding a suffix per
  file.
- **Foreign trees.** Rules 3 and 4 parse filenames, so a vendored tree
  containing a file named `something.link` would be misinterpreted. No current
  content is at risk; if vendoring becomes common, add an
  `external`-style opt-out sentinel as chezmoi did.

## Naming decisions

- **`.symlink`, not `.sym`.** Reusing the existing suffix keeps one convention
  instead of two coexisting ones and means zero migration for current files.
- **No leading dot on repo directories.** `agents.symlink`, not `.agents.sym`,
  matching `gitconfig.symlink` → `~/.gitconfig` and keeping entries visible to
  `ls` and tab completion.
- **No per-file suffix inside a tree.** Files under a Rule 2 root need no
  marker, which is what preserves their extensions.
- **Machine-local files are handled by `.gitignore`, not by filename.** Under a
  name-based convention the repo path must equal the target path, so a local
  variant is a gitignored file at the real target path — or a Rule 4 `.link`
  when a rename is genuinely required.

## Verification

The repo has no automated test suite; verification is manual.

1. `script/bootstrap` on a machine with existing links completes without
   prompting for intermediate directories.
2. Idempotency: run `script/bootstrap` twice; the second run reports only
   skips and creates no new links.
3. `ls -la ~/.cursor` shows `plugins/`, `projects/`, and `extensions/` as real
   directories, with `skills`, `prompts`, `commands`, and `hooks.json` as
   symlinks, and `mcp.json` still an untracked plain file.
4. `~/.agents/skills` is a real directory; authored skills are symlinks into
   the repo and external skills are real directories in `$HOME`.
5. `git status` is clean after installing an external skill.
6. Prune: `ln -s /nonexistent ~/.agents/skills/bogus` inside the repo tree,
   then bootstrap; the link is removed.
7. Deep target: `readlink ~/.config/opencode/opencode.json` resolves into the
   repo, and `~/.config` is a real directory.
8. Fan-out: `readlink ~/.cursor/skills` and `readlink ~/.claude/skills` both
   resolve to `~/.agents/skills`.
9. A path containing a space links correctly (regression test for the
   `find` word-splitting fix).

## P4 - local directory overlay

Machine-local *files* stay gitignored at the real target basename
(`*.local.json`) or renamed with Rule 4. Machine-local *directories*
cannot use that pattern: `cursor.local.symlink` would become
`~/.cursor.local`.

A real subdirectory named `.local` inside a Rule 2 or `.link-children`
tree is a second source for the same destination. It is in `LINK_IGNORE`
and in `.gitignore` as `**/.local/`. Bootstrap merges it after the
parent's own children, inheriting the parent's whole-child vs recurse
mode. The target never contains a `.local` path.

Choose this when content must live in the working tree for bootstrap and
backups, and must not enter git. Keep pointing at `$HOME` (Rule 4) when
the canonical copy already lives outside this repo (Gaia skills).
