#!/bin/bash

# Checks if a specified command is available in the current environment's PATH.
# Arguments:
#   $1: The name of the command to check.
command_exists() {
	command -v "$1" >/dev/null 2>&1 || which "$1" 2>/dev/null
}

# Checks if a specified command or function is available within the Fish shell.
# Arguments:
#   $1: The name of the command or function to check.
fish_command_exists() {
	if ! command_exists "fish"; then
		return $RETERR
	fi
	fish -c "command -v '$1' || which '$1' || functions -q '$1'" >/dev/null 2>&1
}

# Verifies that a required command exists. Aborts the script with a fatal error
# if the command is missing, unless running in dry-run mode.
# Arguments:
#   $1: The name of the required command.
ensure_has_command() {
	if dry_run; then
		return $RETOK
	fi
	if ! command_exists "$1"; then
		fatal "Command $1 not found"
	fi
}

# Verifies that a required command exists within the Fish shell. Aborts the script 
# with a fatal error if missing, unless running in dry-run mode.
# Arguments:
#   $1: The name of the required Fish command.
ensure_fish_has_command() {
	if dry_run; then
		return $RETOK
	fi
	if ! fish_command_exists "$1"; then
		fatal "Fish command $1 not found"
	fi
}

# Executes a given command safely. If the script is running in dry-run mode, 
# it only logs the command to the console instead of executing it.
# Arguments:
#   $@: The command and its arguments to execute.
safe_execute() {
    if dry_run; then
        dry "$*"
    else
        "$@"
    fi
}

# Determines if the current user has effective sudo privileges without blocking 
# to prompt for a password.
# Returns:
#   Success (0) if sudo privileges are detected, error otherwise.
has_real_sudo() {
	if ! command_exists sudo; then
		return $RETERR
	fi

	if can_read "$JUNEST_ROOT_DIR/usr/bin_wrappers/sudo"; then
		return $RETERR
	fi

	local test_sudo_msg=$(LC_ALL=C sudo -vn 2>&1)
	is_empty "$test_sudo_msg" || echo "$test_sudo_msg" | grep -q "password is required"
}

# Executes a command with elevated privileges. If native sudo is unavailable 
# and the script is not already inside Junest, it automatically routes the 
# command through the Junest sandbox environment.
# Arguments:
#   $@: The command and its arguments to execute.
try_sudo() {
	info "Executing on $ID 'sudo $*'"

    if command_exists sudo; then
        if ! has_real_sudo && is_empty "${JUNEST_ENV:-}"; then
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

# Executes the appropriate package manager installation command based on 
# the detected Linux distribution (e.g., pacman for Arch, apt for Debian/Ubuntu).
# Arguments:
#   $@: The list of packages to install.
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

# A high-level package installation wrapper that processes OS-specific targeting flags.
# Delegates the actual installation to 'distro_install' based on the active OS.
# Arguments:
#   $1: Targeting flag (--both, --arch-only, --debian-only, --ubuntu-only).
#   $2..$N: The list of packages to install.
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

# Detects the current Linux distribution by sourcing /etc/os-release.
# Populates OS-related environment variables (like $ID) for later use.
detect_os() {
	if [ -f /etc/os-release ]; then
		. /etc/os-release
	else
		fatal "Unable to detect distribution."
	fi
}

# Installs a Node.js package globally. Automatically detects and utilizes NVM 
# (Node Version Manager) if available to avoid permission issues. Falls back 
# to system-wide installation via sudo if NVM is not present. Handles specific 
# syntax routing for the Fish shell.
# Arguments:
#   $1: The name of the npm package to install.
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
