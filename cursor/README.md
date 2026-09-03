# cursor

Cursor configuration, linked into `~/.cursor` by `script/bootstrap`.

`~/.cursor` stays a real directory because Cursor writes `plugins/`,
`projects/`, and `extensions/` there. Only the entries below are managed.

| Repo path | Target | Rule |
| --- | --- | --- |
| `cursor.symlink/hooks.json` | `~/.cursor/hooks.json` | leaf link |
| `cursor.symlink/prompts.symlink` | `~/.cursor/prompts` | whole dir, repo |
| `cursor.symlink/commands.symlink` | `~/.cursor/commands` | whole dir, repo |
| `cursor.symlink/skills.link` | `~/.cursor/skills` | whole dir, `~/.agents` |

`skills` points at the `$HOME` runtime directory rather than the repo because
Cursor's skill installer writes into it. Prompts and commands point into the
repo, because nothing but you writes there.

`mcp.json` is intentionally not managed: it holds credentials, and Cursor
rewrites it in place, which would replace the symlink with a regular file.

`script/bootstrap` reports any managed path that has stopped being a symlink,
which is how in-place rewrites become visible.
