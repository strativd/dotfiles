# ghostty

Ghostty terminal configuration, linked into `~/.config/ghostty` by
`script/bootstrap`.

Ghostty reads its config from the XDG path
`$XDG_CONFIG_HOME/ghostty/config` (`~/.config/ghostty/config` by
default on macOS), so the topic uses `config.symlink` to walk into
`~/.config` (intermediate directories stay real, leaf files are linked
individually) and the nested `ghostty/` directory maps verbatim.

| Repo path                               | Target                     | Rule      |
| --------------------------------------- | -------------------------- | --------- |
| `ghostty/config.symlink/ghostty/config` | `~/.config/ghostty/config` | leaf link |

Useful commands:

```bash
ghostty +validate-config        # check the linked config
ghostty +show-config --default --docs   # full option reference
ghostty +list-themes            # built-in themes
```
