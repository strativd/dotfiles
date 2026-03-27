# mise

[mise](https://mise.jdx.dev/) (formerly rtx) installs and switches versions of languages and CLI tools per-project or globally. It is a single replacement for tools like asdf, nvm, rbenv, and many ad-hoc installers.

## Links

- [Documentation](https://mise.jdx.dev/)
- [Getting started](https://mise.jdx.dev/getting-started.html)
- [GitHub: jdx/mise](https://github.com/jdx/mise)

## Install (this setup)

On macOS, mise is installed via Homebrew as part of the dotfiles Homebrew bundle:

```bash
brew install mise
```

See `homebrew/brew.sh` for the full list.

### Shell integration

These dotfiles load the [dev](https://github.com/bai/dev) helper from `~/.dev`, which wires mise (and related tooling) into zsh. If you use this repo without `dev`, add the standard hook to your zshrc after mise is on your `PATH`:

```bash
eval "$(mise activate zsh)"
```

Convenience aliases live in `aliases.zsh`:

- `miseon` → `mise activate zsh`
- `miseoff` → `mise deactivate`

## dev tool install (one-time)

The `dev` CLI coordinates repo layout, tooling, and mise config. Install it with the upstream installer, pointing at a config URL (remote gist or a local file).

**Using the tracked config in this repo** (after cloning dotfiles):

```bash
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/bai/dev/refs/heads/main/hack/setup.sh)" -- \
  --config-url="file://${HOME}/.dotfiles/mise/dev.config.json"
```

If your dotfiles live elsewhere, adjust the path (for example `~/src/github.com/strativd/dotfiles/mise/dev.config.json`).

**Using the default remote config** (same gist URL as in `dev.config.json`):

```bash
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/bai/dev/refs/heads/main/hack/setup.sh)" -- \
  --config-url="https://gist.githubusercontent.com/bai/d5a4a92350e67af8aba1b9db33d5f077/raw/config.json"
```

Then reload zsh:

```bash
source ~/.zshrc
```

`zshrc.symlink` sources `~/.dev/hack/zshrc.sh` once at the very end (after `compinit`), only if that file exists, so new shells still start cleanly before you run the installer.

## `dev.config.json` and mise

`dev.config.json` is the dev-tool config for this machine layout. Relevant sections:

- **`miseGlobalConfig`** — default mise tools and [settings](https://mise.jdx.dev/configuration.html) (for example `trusted_config_paths`) applied in the dev/mise workflow.
- **`miseRepoConfig`** — repo-level defaults (here, Python versions) layered on per-repository configs.

After changing tool versions, use mise as usual (`mise install`, `mise use`, etc.) per [mise docs](https://mise.jdx.dev/getting-started.html).
