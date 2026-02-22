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
readonly TMP_DIR="$(mktemp -d -t dotkit.XXXXXX)"
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

readonly RET_MODULE_ENABLE=0
readonly RET_MODULE_DISABLE=1

readonly RET_MODULE_DOEXECUTE=0
readonly RET_MODULE_DONOTHING=1

# ============================================================
#  Cleanup
# ============================================================

# Ensures the temporary directory is removed upon script exit.
trap 'rm -rf "$TMP_DIR"' EXIT

# ============================================================
#  Helpers
# ============================================================

# Checks if the non-interactive (force confirmation) mode is enabled.
# Returns:
#   Success (0) if enabled, error (1) otherwise.
force_confirm() {
	[[ "${FORCE_CONFIRMATION:-false}" == "true" ]]
}

# Checks if the dry-run (simulation) mode is enabled.
# Returns:
#   Success (0) if enabled, error (1) otherwise.
dry_run() {
	[[ "${DRY_RUN:-false}" == "true" ]]
}

# Returns the current verbosity level.
verbose() {
	echo ${VERBOSE:-1}
}

# ============================================================
#  Load Libraries
# ============================================================

# Sources all core library scripts required for the framework to function.
for core_lib in "${PROJECT_ROOT_DIR}/lib/core/"*.sh; do
    source "$core_lib"
done

# ============================================================
#  Usage
# ============================================================

# Displays the help menu detailing available commands and options, then exits.
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

# Injects an autoload configuration block into the default bashrc.
# This ensures that if the user selects an alternative shell (e.g., Zsh or Fish),
# it is automatically launched when a new interactive terminal session starts.
autoload_shell() {
    local default_rc="$HOME/.bashrc"

    if target_shell_is "bash"; then
        return $RETOK
    fi

    blank
    if ! grep -q "exec $TARGET_SHELL" "$default_rc" 2>/dev/null; then
		if force_confirm || confirm "Do you want to autoload $TARGET_SHELL when opening a terminal?"; then
			info "Configuring autoload in $default_rc..."

			backup_file "$default_rc" 2>/dev/null || true

			step "Generate autoload configuration"
			cat <<EOF > "$TMP_DIR/.default_rc"
# --- BEGIN Autoload $TARGET_SHELL ---
if [[ ":\$PATH:" != *":$JUNEST_EXEC_DIR:"* ]]; then
	export PATH="\$PATH:$JUNEST_EXEC_DIR:$JUNEST_BIN_WRAPPERS_DIR"
fi

# Launch $TARGET_SHELL if interactive AND NOT in junest
if [[ \$- == *i* ]] && [[ -z "\${JUNEST_ENV:-}" ]] && [[ -z "\${AUTOLOADED_SHELL:-}" ]] && command -v $TARGET_SHELL >/dev/null 2>&1; then
	export AUTOLOADED_SHELL=1
	exec $TARGET_SHELL
fi
# --- END Autoload $TARGET_SHELL ---
EOF
				
			if ! dry_run; then
				step "Write autoload configuration in $default_rc"
				cat "$TMP_DIR/.default_rc" | safe_execute tee -a "$default_rc" >/dev/null
			else
				dry "Write autoload configuration in $default_rc"
			fi

			blank
			success "Autoload successfully added to $default_rc"
			
			blank
			success "Launching $TARGET_SHELL for this session..."
		   
			if is_empty "${JUNEST_ENV:-}"; then
				if ! dry_run; then
					exec "$TARGET_SHELL"
				else
					dry "exec $TARGET_SHELL"
				fi
			fi
		else
			muted "Autoload skipped."
		fi
	else
		muted "Autoload for $TARGET_SHELL is already configured."
	fi
}

# Removes the previously injected autoload configuration block from the default bashrc.
# Switches the current session back to bash if applicable.
remove_autoload_shell() {
    local default_rc="$HOME/.bashrc"

    if grep -q "# --- BEGIN Autoload" "$default_rc" 2>/dev/null; then
        blank
        info "Cleaning up autoload configuration in $default_rc..."

		if can_read "$default_rc"; then
        	safe_execute sed '/# --- BEGIN Autoload/,/# --- END Autoload/d' "$default_rc" > "${TMP_DIR}/clean_bashrc"
        	safe_mv "${TMP_DIR}/clean_bashrc" "$default_rc"

			blank
        	success "Autoload successfully removed from $default_rc"
		else
			warn "Cannot read $default_rc."
		fi
    else
        muted "No autoload configuration found to clean."
    fi

	if is_empty "${JUNEST_ENV:-}" && [[ "$SHELL" != "bash" ]]; then
		if ! dry_run; then
			exec "bash"
		else
			dry "exec bash"
		fi
	fi
}

# Determines the target shell for the environment setup.
# Uses user input, command-line flags, or auto-detection to set TARGET_SHELL 
# and its corresponding configuration file path (TARGET_SHELL_RC).
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

# Discovers, evaluates, and sequentially executes the available modules 
# based on the selected command (install, reinstall, reconfigure, uninstall).
# Orchestrates environment variable exports and lifecycle hooks.
run_modules() {
	local -a modules_to_run=()

	log "Analyzing modules..."
	for module in "${PROJECT_ROOT_DIR}/modules"/*.sh; do
		if ! can_read "$module"; then
			continue
		fi

		local env_data=$(
			module_enable() { return $RET_MODULE_ENABLE; }
			module_export_env() { return $RETOK; }
			source "$module" </dev/null >/dev/null 2>&1

			if module_enable; then
				module_export_env
			fi
		)

		for pair in $env_data; do
			if [[ -z "$pair" ]]; then
				continue
			fi

			key="${pair%%=*}"
			value="${pair#*=}"

			case "$key" in
				PATH_PREPEND)
					if [[ ":$PATH:" != *":$value:"* ]]; then
						export PATH="$value:$PATH"
					fi
					;;
				PATH_APPEND)
					if [[ ":$PATH:" != *":$value:"* ]]; then
						export PATH="$PATH:$value"
					fi
					;;
				*)
					if [[ -n "$key" && "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
						export "$key=$value"
					fi
					;;
			esac
		done

		if (
            module_enable() { return $RET_MODULE_ENABLE; }
            module_check() { return $RET_MODULE_DONOTHING; }

            source "${module}"

			if ! module_enable; then
				return $RET_MODULE_DONOTHING;
			fi

            case "${RUN_COMMAND}" in
                install)     	module_check ;;
                reinstall)   	return $RET_MODULE_DOEXECUTE ;;
                reconfigure) 	! module_check ;;
                uninstall) 		return $RET_MODULE_DOEXECUTE ;;
                *)				return $RET_MODULE_DONOTHING ;;
            esac
        ); then
            modules_to_run+=("${module}")
        fi
	done

	if [[ ${#modules_to_run[@]} -eq 0 ]]; then
        log "No modules to process."
        return $RETERR
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
            module_install()   { return $RETOK; }
            module_uninstall()   { return $RETOK; }
            module_configure() { return $RETOK; }

            source "${module}"

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

# Evaluates whether the configured target shell matches a given string.
# Arguments:
#   $1: The shell name to test against (e.g., "bash").
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

# The primary entry point of the script. 
# Orchestrates OS detection, configuration output, module execution, 
# and post-installation shell adjustments.
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

	if ! run_modules; then
		blank
		success "Nothing to do."
		return
	fi

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

	case "${RUN_COMMAND}" in
		install|reinstall|reconfigure)
			autoload_shell
			;;
		uninstall)
			remove_autoload_shell
			;;
	esac
}

main
