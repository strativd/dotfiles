#!/usr/bin/env bash

# Install command-line tools using Homebrew.

# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Install GNU core utilities (those that come with OS X are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
sudo ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed
# Install Bash 4.
# Note: don’t forget to add `/usr/local/bin/bash` to `/etc/shells` before
# running `chsh`.
brew install bash
brew tap homebrew/versions
brew install bash-completion2

# Install other useful binaries.
brew install bat
brew install dark-mode
brew install git
brew install tree

# Install others for bin commands
brew install fzf

# Install pls (pretty-ls) — requires Python 3.8 + Nerd Fonts
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font
brew install pipx
pipx ensurepath
pipx install pls

brew install pnpm
brew install yarn
brew install pyenv
brew install git-completion

# Install Apps
brew install --cask raycast
brew install --cask iterm2
brew install --cask visual-studio-code
brew install --cask google-chrome
brew install --cask firefox
brew install --cask slack
brew install --cask spotify
brew install --cask readdle-spark
brew install --cask notion
brew install --cask notion-calendar
brew install --cask google-drive
# brew install --cask dropbox
# brew install --cask cleanmymac
# brew install --cask github
# brew install --cask imageoptim

# Remove outdated versions from the cellar.
brew cleanup
