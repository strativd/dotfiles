# Shopify spin 🌀

if [ "$SPIN" ]; then
  # metafields
  alias mfadd="bin/rails dev:metafields:create SHOP_ID=1"
  # yarn
  alias jest="yarn test --no-graphql"
  # spin shell
  alias scdot="systemctl restart dotfiles.service"
  alias jcdot="journalctl -xeu dotfiles.service"
fi
