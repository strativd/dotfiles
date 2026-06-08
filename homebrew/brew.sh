#!/usr/bin/env bash

# Install command-line tools using Homebrew.

# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae and casks.
brew upgrade

# Install missing formulae and casks; upgrades handled by brew upgrade above.
install_formulae() {
  for formula in "$@"; do
    brew list "$formula" &>/dev/null || brew install "$formula"
  done
}

install_cask() {
  for cask in "$@"; do
    brew list --cask "$cask" &>/dev/null || brew install --cask "$cask"
  done
}

# Install GNU core utilities (those that come with OS X are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
install_formulae coreutils
sudo ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum

# Install some other useful utilities like `sponge`.
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
# Install GNU `sed`, overwriting the built-in `sed`.
install_formulae moreutils findutils gnu-sed

# Install Bash 4.
# Note: don’t forget to add `/usr/local/bin/bash` to `/etc/shells` before
# running `chsh`.
install_formulae bash bash-completion2

# Install Git and related tools.
install_formulae git git-completion
brew list graphite &>/dev/null || brew install withgraphite/tap/graphite # gt (git with Graphite)

# Install other useful binaries.
install_formulae bat dark-mode tree

# Install others for bin commands
install_formulae fzf

install_formulae mise pnpm uv

# Install opencode
install_formulae opencode ollama ast-grep

# Install Apps
install_cask \
  raycast \
  warp \
  cursor \
  google-chrome \
  brave-browser \
  slack \
  spotify \
  readdle-spark \
  notion \
  notion-calendar \
  google-drive

# Remove outdated versions from the cellar.
brew cleanup
