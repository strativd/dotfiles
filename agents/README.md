# Agent Skills

This directory is the **runtime skills directory** — it is what CLIs and AI tools read from.
It is **not** where you author or store skills.

## What lives here

| Item                                 | Tracked in git  | Purpose                                             |
| ------------------------------------ | --------------- | --------------------------------------------------- |
| `.skill-lock.json`                   | Yes             | Source of truth for externally-installed skills     |
| `README.md`                          | Yes             | This file                                           |
| `<skill>/` (symlinks)                | No (gitignored) | Own skills linked from `../my-skills/` by bootstrap |
| `<skill>/` (installed)               | No (gitignored) | Skills installed by CLIs (e.g. `skills install`)    |
| `<skill>/` (symlinks to other repos) | No (gitignored) | Skills from other local repos                       |

## Authoring your own skills

Add skills to `agents/my-skills/` — they are tracked in git and symlinked here by `script/bootstrap`.

```bash
mkdir agents/my-skills/my-new-skill
# write agents/my-skills/my-new-skill/SKILL.md
dot --bootstrap   # creates agents/skills/my-new-skill -> ../my-skills/my-new-skill
```

## Installing external skills

Use the skills CLI. The install is recorded in `.skill-lock.json` (tracked) but the files are gitignored:

```bash
skills install <source>/<skill-name>
```

To restore all externally-installed skills on a new machine:

```bash
skills experimental_install
```
