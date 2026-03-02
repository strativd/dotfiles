# uv — Python package and project manager
# https://github.com/astral-sh/uv

# Enable uv shell completion
if (( $+commands[uv] )); then
  eval "$(uv generate-shell-completion zsh)"
  print "🐍 → python $(python --version | awk '{print $2}')"
fi
