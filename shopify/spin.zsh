# Shopify Spin 🌀

if [ $SPIN ]; then
  alias jest='yarn test --no-graphql'
  alias mfadd="bin/rails dev:metafields:create SHOP_ID=1"

  # Spin prompt
  autoload -Uz vcs_info
  precmd_functions+=( vcs_info )
  setopt prompt_subst

  zstyle ':vcs_info:git:*' check-for-changes true
  zstyle ':vcs_info:*' unstagedstr '*'
  zstyle ':vcs_info:*' stagedstr '+'
  zstyle ':vcs_info:git:*' formats '%F{200}[%b%u%c]%f'
  zstyle ':vcs_info:*' enable git

  PROMPT='%(?.%F{green}√.%F{red}?%?)%f %B%~%b $vcs_info_msg_0_ $ '
fi
