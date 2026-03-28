### GIT COMPLETIONS ###
# Uses git's autocompletion for inner commands. Assumes an install of git's
# bash `git-completion` script at $completion below (this is where Homebrew
# tosses it, at least).
completion='$(brew --prefix)/share/zsh/site-functions/_git'

if test -f $completion
then
  source $completion
fi

### GT COMPLETIONS ###

_gt_yargs_completions()
{
  local reply
  local si=$IFS
  IFS=$'
' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" gt --get-yargs-completions "${words[@]}"))
  IFS=$si
  _describe 'values' reply
}
compdef _gt_yargs_completions gt

### G COMPLETIONS ###
# Unified completion for `g` (gt + git fallback and alias support).
# Uses `bin/g --gt-cache` for shared caching of all gt commands.
typeset -ga _g_gt_native_commands

_g()
{
  # Lazy-load gt command names (once per shell session) using shared cache from bin/g
  if (( ${#_g_gt_native_commands} == 0 )); then
    local -a raw=(${(f)"$($ZSH/bin/g --gt-cache 2>/dev/null)"})
    _g_gt_native_commands=(${raw%%:*})
  fi

  if (( CURRENT == 2 )); then
    # Subcommand position: offer gt commands (from shared cache in bin/g), then git commands
    local si=$IFS
    IFS=$'\n'
    local -a gt_reply=($(
      COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" \
      COMP_POINT="$CURSOR" $ZSH/bin/g --gt-cache
    ))
    IFS=$si
    _describe 'gt commands' gt_reply
    words[1]=git
    _git 2>/dev/null
  elif (( ${_g_gt_native_commands[(Ie)${words[2]}]} )); then
    # Known gt command: use yargs completions for flags/args
    local si=$IFS
    IFS=$'\n'
    local -a reply=($(
      COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" \
      COMP_POINT="$CURSOR" gt --get-yargs-completions "${words[@]}"
    ))
    IFS=$si
    _describe 'values' reply
  else
    # Git passthrough: delegate to _git for full completion
    words[1]=git
    _git 2>/dev/null
  fi
}
compdef _g g
