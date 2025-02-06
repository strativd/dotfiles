# https://github.com/pyenv/pyenv?tab=readme-ov-file#set-up-your-shell-environment-for-pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Activate the virtual environment if it exists
if [[ -d .venv ]]; then
  source .venv/bin/activate
fi

print "🐍 → $(pyenv version)"
