# if there is no ~/.nvm directory make one
nvm_dir="$HOME/.nvm"

# Check if the directory exists
if [ ! -d "$nvm_dir" ]; then
  # If not, create it
  mkdir "$nvm_dir"
  echo "✅ Directory '$nvm_dir' created."
fi

# https://github.com/nvm-sh/nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# use .npmrc config from nvm directory
NPM_CONFIG_GLOBALCONFIG=$NVM_DIR
