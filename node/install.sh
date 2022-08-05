if ! [[ $(brew ls --versions yarn) ]]; then
  brew install yarn
fi

if ! [[ $(brew ls --versions nvm) ]]; then
  brew install nvm
fi

# if there is no ~/.nvm directory make one
if [ -d "~/.nvm" ]; then
  mkdir ~/.nvm
fi
