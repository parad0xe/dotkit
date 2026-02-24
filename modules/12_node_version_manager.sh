#!/bin/bash

module_check() {
    case "$TARGET_SHELL" in
        fish)
            if ! fish_command_exists "nvm"; then
                return $RET_MODULE_DOEXECUTE
            fi
            ;;
        *)
            export NVM_DIR="$HOME/.nvm"
            if ! non_empty_file "$NVM_DIR/nvm.sh"; then
                return $RET_MODULE_DOEXECUTE
            fi
            ;;
    esac

    return $RET_MODULE_DONOTHING
}

module_install() {
    header "Installing nvm (node version manager)"
    
    info "Installing nvm for $TARGET_SHELL shell..."
    blank

    case "$TARGET_SHELL" in
        fish) _install_nvm_fish ;;
        *) _install_nvm_standard ;;
    esac

    blank
    success "Nvm installation process completed"
}

module_configure() {
    header "Configuring nvm environment"
    
    info "Nvm is integrated via shell configuration assets"
    muted "No additional configuration required for this module"
    
    blank
    success "Nvm environment check complete"
}

module_uninstall() {
    header "Uninstalling nvm"

	local uninstalled=false

    if ! force_confirm && ! confirm "Do you want to completely uninstall nvm and its node versions?"; then
        muted "Nvm uninstallation skipped."
        return $RETOK
    fi

    if target_shell_is "fish" && fish_command_exists "fisher"; then
        info "Removing nvm.fish plugin..."
		if safe_execute fish -c "fisher remove jorgebucaran/nvm.fish"; then
            uninstalled=true
        fi
    fi

    if safe_rm "$HOME/.nvm"; then
		safe_rm "$HOME/.npm"
        uninstalled=true
    else
        muted "Nvm directory not found or already removed."
    fi
	
	if [[ "$uninstalled" == "true" ]]; then
        blank
        success "Nvm and node versions uninstalled"
    else
        muted "Nothing to do: nvm is already uninstalled."
    fi
}

# --- Internal helpers ---

_install_nvm_fish() {
    info "Setting up nvm for fish..."
    
	ensure_has_command "fish"
	ensure_fish_has_command "fisher"

	step "Installing nvm.fish plugin..."
	safe_execute fish -c "fisher install jorgebucaran/nvm.fish"
	
	blank
	info "Installing latest node.js version..."
	safe_execute fish -c "nvm install latest"
	safe_execute fish -c "set -U nvm_default_version latest"

	success "Nvm and node.js installed successfully for $TARGET_SHELL"
}

_install_nvm_standard() {
    export NVM_DIR="$HOME/.nvm"

	ensure_has_command "curl"

	local version
	version=$(get_github_latest_release "nvm-sh/nvm")
	
	step "Detected latest nvm version: $version"

	blank
	info "Downloading and running nvm installation script..."
	safe_execute curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$version/install.sh" | bash

	if ! dry_run; then
		if non_empty_file "$NVM_DIR/nvm.sh"; then
			\. "$NVM_DIR/nvm.sh"
		else
			fatal "Nvm installation failed: $NVM_DIR/nvm.sh not found"
		fi
	fi

	blank
	info "Installing node.js lts version..."
	safe_execute nvm install node
	success "Nvm and node.js lts installed successfully for $TARGET_SHELL"
}
