if ! [ -x "$(command -v frum)" ]; then
  brew install frum
fi

if ! [ -x "$(command -v openssl)" ]; then
  brew install openssl
fi
