#!/bin/bash

set -e

# lint
shellcheck -s bash ./install.sh

# set staging api endpoint so we can use bogus install token
MACOS_CONFIG="$HOME/Library/Preferences/flossbank"
LINUX_CONFIG="${XDG_CONFIG_HOME:-$HOME}/.config/flossbank"
mkdir -p "$MACOS_CONFIG"
mkdir -p "$LINUX_CONFIG"
echo '{"apiHost":"https://api.flossbank.io"}' > "$MACOS_CONFIG/config.json"
echo '{"apiHost":"https://api.flossbank.io"}' > "$LINUX_CONFIG/config.json"

export FLOSSBANK_INSTALL_TOKEN="cf667c9381f7792bfa772025ff8ee93b89d9a757e6732e87611a0c34b48357d1"
export FLOSSBANK_CONFIRM=1 # skipping the "Press any key to continue..." prompt during installation

# install the latest version at the default location
rm -f ~/.flossbank/bin/flossbank
unset FLOSSBANK_INSTALL
bash ./install.sh
~/.flossbank/bin/flossbank --version

# install to a custom location
rm -rf ~/flossbank-custom
export FLOSSBANK_INSTALL="$HOME/flossbank-custom"
bash ./install.sh
~/flossbank-custom/bin/flossbank --version
