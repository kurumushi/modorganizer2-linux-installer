#!/bin/bash

cache_enabled="${CACHE:-1}"

set -eu

script_root=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

utils="$script_root/utils"
dialog="$utils/dialog.sh"
gamesinfo="$script_root/gamesinfo"
handlers="$script_root/handlers"
launchers="$script_root/launchers"
redirector="$script_root/steam-redirector"
step="$script_root/step"
downloads_cache=/tmp/mo2-linux-installer-downloads-cache
shared="$HOME/.local/share/modorganizer2"

started_download_step=0
expect_exit=0

mkdir -p "$downloads_cache"
mkdir -p "$shared"

function handle_error() {
	if [ "$expect_exit" != "1" ]; then
		if [ "$started_download_step" == "1" ]; then
			purge_downloads_cache
		fi

		"$dialog" \
			errorbox \
			"Operation canceled. Check the terminal for details"
	fi
}

function log_info() {
	echo "INFO:" "$@"
}

function log_warn() {
	echo "WARN:" "$@" >&2
}

function log_error() {
	echo "ERROR:" "$@" >&2
}

trap handle_error EXIT

expect_exit=1

source "$step/check_dependencies.sh"

selected_game=$(source "$step/select_game.sh")
log_info "selected game '$selected_game'"

runner=$(source "$step/select_runner.sh")
log_info "selected runner '$runner'"

source "$step/load_gameinfo.sh"

install_dir=$(source "$step/select_install_dir.sh")
log_info "selected install directory '$install_dir'"

expect_exit=0

source "$step/download_external_resources.sh"
source "$step/install_external_resources.sh"
source "$step/install_nxm_handler.sh"

case "$runner" in
	proton)
		source "$step/install_proton_launcher.sh"
		source "$step/configure_steam_wineprefix.sh"
	;;
	wine)
		source "$step/install_wine_launcher.sh"
	;;
esac

source "$step/register_installation.sh"

log_info "installation completed successfully"
expect_exit=1
"$dialog" infobox "Installation successful"

