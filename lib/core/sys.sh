#!/bin/bash

command_exists() {
	if dry_run; then
		return $RETOK
	fi
	command -v "$1" >/dev/null 2>&1 || which "$1" 2>/dev/null
}

fish_command_exists() {
	if dry_run; then
		return $RETOK
	fi
	ensure_has_command "fish"
	fish -c "command -v '$1' || which '$1' || functions -q '$1'" >/dev/null 2>&1
}

ensure_has_command() {
	if dry_run; then
		return $RETOK
	fi
	if ! command_exists "$1"; then
		fatal "Command $1 not found"
	fi
}

ensure_fish_has_command() {
	if dry_run; then
		return $RETOK
	fi
	if ! fish_command_exists "$1"; then
		fatal "Fish command $1 not found"
	fi
}

safe_execute() {
    if dry_run; then
        dry "$*"
    else
        "$@"
    fi
}

has_real_sudo() {
	if ! command_exists sudo; then
		return $RETERR
	fi

	local test_sudo_msg=$(LC_ALL=C sudo -vn 2>&1)
	echo "$test_sudo_msg" | grep -q "password is required"
}

try_sudo() {
	info "Executing on $ID 'sudo $*'"

    if command_exists sudo; then
        if dir_exists "$JUNEST_ROOT_DIR"; then
            if ! safe_execute junest -- sudo "$@"; then
                fatal "Failed to run 'junest -- sudo $*'"
            fi
        else
            if ! safe_execute sudo "$@"; then
                fatal "Failed to run 'sudo $*'"
            fi
        fi
    else
        fatal "Failed to run 'sudo $*'"
    fi
}

distro_install() {
    local cmd=""
    case "$ID" in
        arch)
            cmd="pacman -Syu --noconfirm --needed"
            ;;
        debian|ubuntu)
            cmd="apt install -y"
            ;;
        *) 
            fatal "Unsupported distribution: $ID"
            ;;
    esac

    try_sudo $cmd "$@"
}

pkg_install() {
    local target_os="all" 
    case "$1" in
        --both) shift ;;
        --arch-only) target_os="arch"; shift ;;
        --debian-only|--ubuntu-only) target_os="debian_ubuntu"; shift ;;
        *) fatal "Unknown flag in pkg_install: $1" ;;
    esac

    if [[ $# -eq 0 ]]; then
        warn "No packages provided to pkg_install, skipping"
        return 0
    fi

    case "$target_os" in
        arch)          [[ "$ID" == "arch" ]] && distro_install "$@" || true ;;
        debian_ubuntu) [[ "$ID" =~ debian|ubuntu ]] && distro_install "$@" || true ;;
        all)           distro_install "$@" ;;
        *)             fatal "Unsupported target os $target_os" ;;
    esac
}

detect_os() {
	if [ -f /etc/os-release ]; then
		. /etc/os-release
	else
		fatal "Unable to detect distribution."
	fi
}

npm_install_g() {
    local package="$1"
    
    case "$TARGET_SHELL" in
        fish)
            safe_execute fish -c "nvm use latest >/dev/null 2>&1 && npm install -g $package"
            ;;
        *)
            export NVM_DIR="$HOME/.nvm"
            if [ -s "$NVM_DIR/nvm.sh" ]; then
                \. "$NVM_DIR/nvm.sh"
                safe_execute npm install -g "$package"
            else
                ensure_has_command "npm"
                try_sudo npm install -g "$package"
            fi
            ;;
    esac
}
