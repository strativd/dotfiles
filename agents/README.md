# agents

Shared agent content: prompts, commands, and authored skills. Cursor, Claude,
and pi all consume this directory, each through its own topic.

## Layout

| Path | Tracked | Target |
| --- | --- | --- |
| `agents.symlink/prompts/` | yes | `~/.agents/prompts/*` (leaf links) |
| `agents.symlink/commands/` | yes | `~/.agents/commands/*` (leaf links) |
| `agents.symlink/skills/` | yes | one whole-dir link per skill |
| `agents.symlink/skills/.local/` | no | one whole-dir link per skill |
| `agents.symlink/skills/.link-children` | yes | makes `~/.agents/skills` real |
| `agents.symlink/AGENTS.md` | yes | `~/.agents/AGENTS.md`; other tools link here via `*.link` files |
| `agents.symlink/.skill-lock.json` | yes | `~/.agents/.skill-lock.json` |
| `README.md` | yes | not linked (outside the tree) |

## The runtime directory is not in this repo

`~/.agents/skills` is a real directory in `$HOME`. Tracked authored skills
are symlinks into the tracked tree; overlay authored skills are
symlinks into `.local/`; installer-written skills stay real
directories in `$HOME`; Gaia skills stay linked from `~/.gaia`.
`.local/` is gitignored, so overlay skills stay out of `git status`.
Untracked files in the tracked skills tree can still appear.

`.skill-lock.json` is linked rather than copied, so the skills CLI's writes
land in git and external skills can be restored on a new machine with
`skills experimental_install`.

## Adding a skill

Author a skill that is safe to publish:

```bash
mkdir agents/agents.symlink/skills/my-skill
# write SKILL.md
dot --sync
```

Author a skill that must stay untracked:

```bash
mkdir agents/agents.symlink/skills/.local/unsafe-skill
# write SKILL.md
dot --sync
```

Overlay children land at `~/.agents/skills/<name>`, never
`~/.agents/skills/.local/<name>`.

## Who consumes this

| Consumer | Mechanism |
| --- | --- |
| `~/.agents` | this topic |
| `~/.cursor` | `cursor/cursor.symlink/` — `skills.link`, `prompts.symlink` |
| `~/.claude` | `claude/claude.symlink/` — `skills.link` |
| `~/.pi/agent` | `pi/pi.symlink/agent/` — its own skills, plus pi's own links |
