# test

Tests for the symlink engine in `script/lib/links.sh`.

```bash
test/links_test.sh
```

Each test builds a throwaway `DOTFILES_ROOT` and `HOME` under `mktemp -d`, runs
`install_dotfiles` against them, and asserts on the resulting links. Nothing
touches the real machine.

Tests set `LINK_CONFLICT_POLICY=skip` so `link_file` never prompts. The other
values are `prompt` (the default, used by `script/bootstrap`), `overwrite`, and
`backup`.

Add a test by defining a function named `test_*`; the runner discovers them
with `declare -F`.
