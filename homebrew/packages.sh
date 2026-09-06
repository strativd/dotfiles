#
# Homebrew package helpers. Sourced, not executed.
#
# install_formulae and install_cask skip names Homebrew already manages.
# Missing casks are installed with --force so an app already sitting in
# /Applications is overwritten with the cask version instead of erroring
# after the download.

install_formulae() {
  for formula in "$@"; do
    brew list "$formula" &>/dev/null || brew install "$formula"
  done
}

install_cask() {
  for cask in "$@"; do
    brew list --cask "$cask" &>/dev/null || brew install --cask --force "$cask"
  done
}
