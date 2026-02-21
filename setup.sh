#!/bin/bash

# ============================================================
#  Configuration & Security
# ============================================================
set -euo pipefail

# ------------------------------------------------------------
# Global variables (modified by flags)
# ------------------------------------------------------------
RUN_COMMAND=""
FORCE_CONFIRMATION="false"
DRY_RUN="false"
VERBOSE=1
TARGET_SHELL=""
TARGET_SHELL_RC=""

# ------------------------------------------------------------
# Constants
# ------------------------------------------------------------
readonly PROJECT_ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
readonly TMP_DIR="$(mktemp -d -t dotfiles.XXXXXX)"
readonly ASSETS_DIR="$PROJECT_ROOT_DIR/assets"
readonly LOCAL_BIN_DIR="${HOME}/.local/bin"
readonly LOCAL_FONT_DIR="${HOME}/.local/share/fonts"
readonly JUNEST_DIR="$HOME/.local/share/junest"
readonly JUNEST_EXEC_DIR="$HOME/.local/share/junest/bin"
readonly JUNEST_ROOT_DIR="$HOME/.junest"
readonly JUNEST_BIN_DIR="$JUNEST_ROOT_DIR/bin"
readonly JUNEST_BIN_WRAPPERS_DIR="$JUNEST_ROOT_DIR/usr/bin_wrappers"
readonly BACKUP_DIR="${HOME}/.local/state/dotfiles_backups/$(date +%Y%m%d_%H%M%S)"

readonly RETOK=0
readonly RETERR=1

readonly RET_MODULE_LOADED=0
readonly RET_MODULE_SKIP=1

readonly RET_MODULE_DOEXECUTE=0
readonly RET_MODULE_DONOTHING=1

# ============================================================
#  Cleanup
# ============================================================
trap 'rm -rf "$TMP_DIR"' EXIT

# ============================================================
#  Helpers
# ============================================================
force_confirm() {
	[[ "${FORCE_CONFIRMATION:-false}" = "true" ]]
}

dry_run() {
	[[ "${DRY_RUN:-false}" = "true" ]]
}

verbose() {
	echo ${VERBOSE:-1}
}

# ============================================================
#  Load Libraries
# ============================================================
for core_lib in "${PROJECT_ROOT_DIR}/lib/core/"*.sh; do
    source "$core_lib"
done

# ============================================================
#  Usage
# ============================================================
usage() {
	blank
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] {install|reinstall|reconfigure|uninstall}

Options:
  -y, --yes         Force all confirmations
  -d, --dry-run     Simulate execution (no changes)
  -s, --shell       Target a specific shell (bash|zsh|fish)
  -v, --verbose     Verbose output
  -h, --help        Print this help message
EOF
    exit $RETERR
}

# ============================================================
#  Shell Environment Logic
# ============================================================
setup_shell_env() {
	if is_not_empty "$TARGET_SHELL" && [[ ! "$TARGET_SHELL" =~ ^(bash|zsh|fish)$ ]]; then
		warn "Invalid shell '${TARGET_SHELL}' provided. Reverting to auto-detection..."
		TARGET_SHELL=""
    fi

	if is_empty "$TARGET_SHELL"; then
        local detected_shell
        detected_shell=$(basename "${SHELL:-bash}")

        if force_confirm; then
            TARGET_SHELL="$detected_shell"
        else
			info "Please select the shell you want to configure:"
            PS3="Selection (enter number): "
				
			select opt in bash zsh fish; do
				case $opt in
					bash|zsh|fish) TARGET_SHELL=$opt; break ;;
					*) echo "Invalid option: $REPLY";;
				esac
			done
        fi
    fi
    
	case "$TARGET_SHELL" in
		bash) TARGET_SHELL_RC="$HOME/.bashrc" ;;
		zsh)  TARGET_SHELL_RC="$HOME/.zshrc" ;;
		fish) TARGET_SHELL_RC="$HOME/.config/fish/config.fish" ;;
		*) fatal "Unsupported shell: $TARGET_SHELL. No configuration file found." ;;
	esac

	blank
	success "Target: ${TARGET_SHELL} → ${TARGET_SHELL_RC}"
}

# ============================================================
#  Module Manager
# ============================================================
run_modules() {
	local -a modules_to_run=()

	log "Analyzing modules..."
	for module in "${PROJECT_ROOT_DIR}/modules"/*.sh; do
		if ! can_read "$module"; then
			continue
		fi

		if (
            # Isolated subshell
            module_init()  { return $RET_MODULE_LOADED; }
            module_check() { return $RET_MODULECHECK_DONOTHING; }

            source "${module}"

			if ! module_init; then
				return $RETERR
			fi

            case "${RUN_COMMAND}" in
                install)     	module_check ;;
                reinstall)   	return $RET_MODULE_DOEXECUTE ;;
                reconfigure) 	! module_check ;;
                uninstall) 		return $RET_MODULE_DOEXECUTE ;;
                *)				return $RET_MODULECHECK_DONOTHING ;;
            esac
        ); then
            modules_to_run+=("${module}")
        fi
	done

	if [[ ${#modules_to_run[@]} -eq 0 ]]; then
        log "No modules to process."
        return
    fi

	blank
	log "Selected modules for ${RUN_COMMAND}:"
    for module in "${modules_to_run[@]}"; do
		local display_name="${module##*/}"
		display_name="${display_name#*_}"
		display_name="${display_name%.sh}"
		step "$display_name"
	done

    if ! force_confirm; then
		blank
		if ! confirm "Do you want to continue?"; then
			fatal "Aborted by user."
		fi
    fi

	blank
	for module in "${modules_to_run[@]}"; do
		local display_name="${module##*/}"
		display_name="${display_name#*_}"
		display_name="${display_name%.sh}"
		if ! can_read "$module"; then
			warn "$module does not exists on system. skipping."
			continue
		fi

		blank
        info "Executing: $display_name"

        (
			module_init()      { return $RET_MODULE_LOADED; }
            module_install()   { return $RETOK; }
            module_uninstall()   { return $RETOK; }
            module_configure() { return $RETOK; }

            source "${module}"

            if ! module_init; then
				warn "skip $module"
				return $RETOK
			fi

			case "${RUN_COMMAND}" in
                install)
                    module_install
                    module_configure
                    ;;
                reinstall)
                    info "Starting reinstallation sequence..."
                    module_uninstall
                    module_install
                    module_configure
                    ;;
                reconfigure)
                    module_configure
                    ;;
                uninstall)
                    module_uninstall
                    ;;
            esac
        ) || fatal "An error occurred in module: ${module}"
    done
}

target_shell_is() {
	[[ "$TARGET_SHELL" == "$1" ]]
}

# ============================================================
#  Argument Parsing
# ============================================================
while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes) FORCE_CONFIRMATION="true"; shift ;;
        -d|--dry-run) DRY_RUN="true"; shift ;;
		-s|--shell) 
            if [[ -n "${2:-}" ]]; then
                TARGET_SHELL="$2"
                shift 2
            else
                fatal "--shell requires an argument (bash|zsh|fish)"
            fi
            ;;
        -v|--verbose) VERBOSE=2; shift ;;
        -h|--help) usage ;;
        install|reinstall|reconfigure|uninstall) 
			if ! is_empty "$RUN_COMMAND"; then
				usage
			fi

			RUN_COMMAND="$1"
			shift
			;;
        *) usage ;;
    esac
done

readonly ARCH=$(uname -m)
readonly IS_VERBOSE=$([ "$VERBOSE" == "2" ] && echo "true" || echo "false")

# ============================================================
#  Main
# ============================================================
main() {
	detect_os
	setup_shell_env

	header \
		"Runtime configuration" \
		"" \
		"User            : $USER" \
		"OS              : $ID ($ARCH)" \
		"Target shell    : ${TARGET_SHELL:-none}" \
		"Target shell RC : ${TARGET_SHELL_RC:-none}" \
		"Command         : $RUN_COMMAND" \
		"Force confirms  : $FORCE_CONFIRMATION" \
		"Dry run         : $DRY_RUN" \
		"Verbose         : $IS_VERBOSE" \
		"" \
		"Directories" \
		"Project root   : $PROJECT_ROOT_DIR" \
		"Assets         : $ASSETS_DIR" \
		"Backup folder  : $BACKUP_DIR" \
		"Local fonts    : $LOCAL_FONT_DIR"

	run_modules

	blank
	case $RUN_COMMAND in
		install)
			success "Installation complete"
			tips "Restart your shell and run :PlugInstall inside nvim"
			;;
		reinstall)
			success "Reinstallation complete"
			tips "Restart your shell and run :PlugInstall inside nvim"
			;;
		reconfigure)
			success "Reconfigure complete"
			tips "Restart your shell and run :PlugInstall inside nvim"
			;;
		uninstall)
			success "Uninstallation complete"
			;;
		*) usage ;;
	esac
}

main
