# auto-nvm – call `nvm use` automatically in a directory with a .nvmrc file
# https://github.com/nvm-sh/nvm#zsh

autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Check if nvm command exists
if ! type nvm &> /dev/null; then
  echo "❌ Install nvm manually: https://github.com/nvm-sh/nvm#installing-and-updating"
fi
