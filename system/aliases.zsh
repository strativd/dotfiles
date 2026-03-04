# grc overides for ls
#   Made possible through contributions from generous benefactors like
#   `brew install coreutils`
if $(gls &>/dev/null)
then
  alias ls="gls -F --color"
  alias l="gls -lAh --color"
  alias ll="gls -l --color"
  alias la='gls -A --color'
fi

# Copy previous input/command to clipboard
alias copy-input="fc -ln -1 | pbcopy"

# Re-run the last command and copy its output to clipboard
copy-output() {
  local last_cmd=$(fc -ln -1)
  eval "$last_cmd" 2>/dev/null | pbcopy
}
