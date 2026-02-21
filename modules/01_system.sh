#!/bin/bash

module_check() {
    return $RET_MODULE_DOEXECUTE
}

module_install() {
    header "Installing system dependencies"

    info "Installing base development tools..."
    pkg_install --arch-only base-devel
    pkg_install --debian-only build-essential libssl-dev

    blank
    info "Installing core cli utilities..."
    pkg_install --both python3 curl wget clang \
        llvm gcc unzip tar git man make which vim ncdu

	case "$TARGET_SHELL" in
		fish)
    		blank
    		info "Installing terminal $TARGET_SHELL..."
			pkg_install --both fish ;;
		zsh)
    		blank
    		info "Installing terminal $TARGET_SHELL..."
			pkg_install --both zsh ;;
	esac

    blank
    info "Installing sys utilities..."
    pkg_install --debian-only python3-pygments python3-venv libclang-dev openssh-server
    pkg_install --arch-only python-pygments python-virtualenv openssh

    blank
    success "System dependencies installed successfully"
}

module_configure() {
    return $RETOK
}

module_uninstall() {
    header "Uninstalling system dependencies"
    info "Skipping system packages uninstallation to prevent OS breakage."
    muted "Packages like curl, git, python3 remain installed."
    return $RETOK
}
