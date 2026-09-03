# agents

Shared agent content: prompts, commands, and authored skills. Cursor, Claude,
and pi all consume this directory, each through its own topic.

## Layout

| Path | Tracked | Target |
| --- | --- | --- |
| `agents.symlink/prompts/` | yes | `~/.agents/prompts/*` (leaf links) |
| `agents.symlink/commands/` | yes | `~/.agents/commands/*` (leaf links) |
| `agents.symlink/skills/` | yes | one whole-dir link per skill |
| `agents.symlink/skills/.link-children` | yes | makes `~/.agents/skills` real |
| `agents.symlink/.skill-lock.json` | yes | `~/.agents/.skill-lock.json` |
| `README.md` | yes | not linked (outside the tree) |

## The runtime directory is not in this repo

`~/.agents/skills` is a real directory in `$HOME`. Skills you author are
symlinks from it into `agents.symlink/skills/`; skills installed by any tool
are real directories in `$HOME`. Nothing external is stored in the repo, so
`git status` stays quiet.

`.skill-lock.json` is linked rather than copied, so the skills CLI's writes
land in git and external skills can be restored on a new machine with
`skills experimental_install`.

## Adding a skill

```bash
mkdir agents/agents.symlink/skills/my-skill
# write SKILL.md
dot --sync
```

## Who consumes this

| Consumer | Mechanism |
| --- | --- |
| `~/.agents` | this topic |
| `~/.cursor` | `cursor/cursor.symlink/` — `skills.link`, `prompts.symlink` |
| `~/.claude` | `claude/claude.symlink/` — `skills.link` |
| `~/.pi/agent` | `pi/pi.symlink/agent/` — its own skills, plus pi's own links |
