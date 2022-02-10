# Shopify spin 🌀

if [ "$SPIN" ]; then
  # metafields
  alias mfadd="bin/rails dev:metafields:create SHOP_ID=1"

  # yarn
  alias jest="yarn test --no-graphql"

  # systemd
  alias scdot="systemctl restart dotfiles.service"
  alias jcdot="journalctl -xeu dotfiles.service"
  alias jcweb="journalctl -fu redis@shopify--web"
  alias jcshop="journalctl -fu redis@shopify--shopify"
  alias jcall="jc -f"

  # shop import database
  sim () {
    # [ $# -eq 0 ] && echo "No argument supplied..."
    if [ -z "$1" ]; then
      echo "Cannot import shop data: no argument supplied..."
    else
      SHOPIFY_DIR="~/src/github.com/Shopify/shopify"
      CURRENT_DIR=$(pwd)
      cd "$SHOPIFY_DIR"
      shop import "$1" >/dev/null &
      cd "$CURRENT_DIR"
      return;
    fi
  }
fi
