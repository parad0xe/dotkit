#!/bin/bash

module_init() {
	if has_real_sudo; then
		return $RET_MODULE_SKIP
	fi

	export PATH="$JUNEST_EXEC_DIR:$PATH:$JUNEST_BIN_WRAPPERS_DIR"
    ID="arch"

	return $RET_MODULE_LOADED
}

module_check() {
	if ! has_real_sudo; then
		if ! dir_exists "$JUNEST_ROOT_DIR" || ! command_exists junest; then
			return $RET_MODULE_DOEXECUTE
		fi
	fi

	return $RET_MODULECHECK_DONOTHING
}

module_install() {
	header "Installing junest (unprivileged jail)"
	
    warn "Sudo access not detected. To proceed without root, junest is required"
	
	if force_confirm || confirm "Install junest in $JUNEST_DIR and continue?"; then
		_install_junest
	else
		fatal \
			"Unprivileged environment setup declined" \
			"This script requires either sudo or junest to manage system dependencies"
	fi

	blank
	success "Junest installed successfully"			
}

module_configure() {
	header "Configuring junest environment"
    
    info "Updating junest package databases..."
    _configure_junest
    
    blank
    success "Junest environment is ready"
}

module_uninstall() {
    header "Uninstalling junest"
    
	if safe_rm "$JUNEST_ROOT_DIR" "$JUNEST_DIR"; then
		blank
		success "Junest uninstalled"
    else
        muted "Junest uninstallation skipped."
    fi
}

# --- Internal helpers ---

_install_junest() {
    info "Cloning junest repository..."

    ensure_has_command "git"
    safe_execute git clone --depth 1 https://github.com/fsquillace/junest.git "$JUNEST_DIR"

    step "Running junest setup..."
    safe_execute junest setup
}

_configure_junest() {
    safe_execute junest -- sudo pacman --noconfirm -Syy
    safe_execute junest -- sudo pacman --noconfirm -Sy archlinux-keyring
}
