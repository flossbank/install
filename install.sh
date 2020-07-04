#!/bin/bash
# TODO(everyone): Keep this script simple and easily auditable.
# Thanks deno.land for inspiration <3
#
#    Copyright (C) 2020 Flossbank, Inc.
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

set -eo pipefail

BOLD="$(tput bold 2>/dev/null || echo '')"
RED="$(tput setaf 1 2>/dev/null || echo '')"
YELLOW="$(tput setaf 3 2>/dev/null || echo '')"
MAGENTA="$(tput setaf 5 2>/dev/null || echo '')"
NO_COLOR="$(tput sgr0 2>/dev/null || echo '')"

info() {
	printf "%s\n" "${BOLD}$*${NO_COLOR}"
}

error() {
	printf "%s\n" "${RED}x $*${NO_COLOR}" >&2
}

flossbank_install="${FLOSSBANK_INSTALL:-$HOME/.flossbank}"
bin_dir="$flossbank_install/bin"
exe="$bin_dir/flossbank"

if [ -z "$FLOSSBANK_INSTALL_TOKEN" ]; then
	# We might not need an install token: Flossbank might already be installed
	# and an API key may already be configured. So we'll check that here.
	if [ ! -x "$exe" ] || ! "$exe" check; then
		# The installer needs a token and it isn't present as an env var.
		# When we ask for the user to type it in, this script will try to read
		# from stdin. But this script was piped into `sh`. Instead we're going
		# to explicitly connect /dev/tty to the installer's stdin, ala https://sh.rustup.rs.
		if [ ! -t 1 ]; then
			error "Unable to run interactively. Run with FLOSSBANK_INSTALL_TOKEN=<token>."
		fi
		while [ -z "$FLOSSBANK_INSTALL_TOKEN" ]; do
			read -r -p "${BOLD}Please enter install token to continue: ${NO_COLOR}" FLOSSBANK_INSTALL_TOKEN </dev/tty
		done
	fi
fi

case $(uname -s) in
Darwin) target="macos-x86_64" ;;
*) target="linux-x86_64" ;;
esac

if [ "$(uname -m)" != "x86_64" ]; then
	error "Unsupported architecture $(uname -m). Only x64 binaries are available."
	exit
fi

if ! command -v unzip >/dev/null; then
	error "Error: unzip is required to install Flossbank." 1>&2
	exit 1
fi

if ! command -v curl >/dev/null; then
	error "Error: curl is required to install Flossbank." 1>&2
	exit 1
fi

if ! command -v cut >/dev/null; then
	error "Error: cut is required to install Flossbank." 1>&2
	exit 1
fi

echo
info "Welcome to Flossbank!"
echo
echo "This script will download and install the latest version of Flossbank,"
echo "a package manager wrapper that helps compensate open source maintainers."
echo
echo "It will add the 'flossbank' command to Flossbank's bin directory, located at:"
echo
echo "${YELLOW}${bin_dir}${NO_COLOR}"
echo
echo "This path will then be added to your PATH environment variable by"
echo "modifying your shell profile/s."
echo
echo "You can uninstall at any time by executing 'flossbank uninstall'"
echo "and these changes will be reverted."
echo

if [ ! "$FLOSSBANK_CONFIRM" ]; then
	if [ -t 1 ]; then
		read -n 1 -s -r -p "Press any key to continue..." </dev/tty
	fi
fi

flossbank_asset_info=$(command curl -sSLf "https://install.flossbank.com/releases/${target}")
if [ ! "$flossbank_asset_info" ]; then
	echo
	error "Error: unable to locate latest release on GitHub. Please try again or email support@flossbank.com for help!"
	exit 1
fi

flossbank_uri=$(echo "$flossbank_asset_info" | head -n 1)
flossbank_version=$(echo "$flossbank_asset_info" | tail -n 1)
flossbank_file_name=$(echo "$flossbank_uri" | cut -d'/' -f 9)

echo "Installing version: ${YELLOW}${flossbank_version}${NO_COLOR}"
echo "  - Downloading ${YELLOW}${flossbank_file_name}${NO_COLOR}..."

[ ! -d "$bin_dir" ] && mkdir -p "$bin_dir"
curl -sS --fail --location --output "$exe.zip" "$flossbank_uri"
cd "$bin_dir"
unzip -qq -o "$exe.zip"
chmod +x "$exe"
rm "$exe.zip"

echo
$exe install "$flossbank_install"
$exe wrap all
[ -n "$FLOSSBANK_INSTALL_TOKEN" ] && $exe auth "$FLOSSBANK_INSTALL_TOKEN"
echo

echo
info "Flossbank (${flossbank_version}) is now installed and registered. Great!"
echo
echo "To get started, you need Flossbank's bin directory (${bin_dir}) in your 'PATH'"
echo "environment variable. Next time you log in this will be done"
echo "automatically."
echo
info "To configure your current shell run ${MAGENTA}source ${flossbank_install}/env${NO_COLOR}"
echo
