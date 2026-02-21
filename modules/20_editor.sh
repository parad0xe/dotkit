#!/bin/bash

module_init() {
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi
}

module_check() {
	if ! command_exists "nvim" && ! file_exists "$HOME/.local/bin/nvim"; then
        return $RET_MODULE_DOEXECUTE
    fi

    local plug_path="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
    if ! file_exists "$plug_path"; then
        return $RET_MODULE_DOEXECUTE
    fi

    case "$TARGET_SHELL" in
        fish)
            if ! fish_command_exists "tree-sitter"; then
                return $RET_MODULE_DOEXECUTE
            fi
            ;;
        *)
            export NVM_DIR="$HOME/.nvm"
            non_empty_file "$NVM_DIR/nvm.sh" && \. "$NVM_DIR/nvm.sh" >/dev/null 2>&1
            if ! command_exists "tree-sitter"; then
                return $RET_MODULE_DOEXECUTE
            fi
            ;;
    esac

    return $RET_MODULECHECK_DONOTHING
}

module_install() {
    header "Installing neovim & code tools"

    info "Checking neovim..."

	if ! command_exists "nvim"; then
        _install_neovim_binary
    else
        success "Neovim is already installed"
    fi

	blank
    info "Checking vim-plug..."

    local plug_path="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"

    if ! file_exists "$plug_path"; then
        _install_vim_plug "$plug_path"
    else
        success "Vim-plug already installed"
    fi

    blank
    info "Checking tree-sitter..."

    local ts_installed=false

    case "$TARGET_SHELL" in
        fish)
            fish_command_exists "tree-sitter" && ts_installed=true
            ;;
        *)
            export NVM_DIR="$HOME/.nvm"

			if ! dry_run; then
				if non_empty_file "$NVM_DIR/nvm.sh"; then
					\. "$NVM_DIR/nvm.sh" >/dev/null 2>&1
				fi
			fi
            command_exists "tree-sitter" && ts_installed=true
            ;;
    esac

    if ! $ts_installed; then
        _install_tree_sitter
    else
        success "Tree-sitter cli already installed"
    fi

    blank
    success "Editor neovim and code tools installed successfully"
}

module_configure() {
    header "Configuring neovim assets"

    info "Preparing neovim configuration directory..."
    safe_mkdir "$HOME/.config/nvim"

    blank
    info "Linking core configuration files..."
    safe_link "$ASSETS_DIR/tools/nvim/config.lua" "$HOME/.config/nvim/config.lua"
    safe_link "$ASSETS_DIR/tools/nvim/init.vim" "$HOME/.config/nvim/init.vim"

    blank
    info "Synchronizing lua modules..."
    safe_link_all "$ASSETS_DIR/tools/nvim/lua" "$HOME/.config/nvim/lua"

    blank
    success "Neovim environment synchronized"
}

module_uninstall() {
    header "Uninstalling neovim & code tools"
    
    if safe_rm \
            "$HOME/.config/nvim" \
            "${XDG_DATA_HOME:-$HOME/.local/share}/nvim" \
            "${XDG_STATE_HOME:-$HOME/.local/state}/nvim" \
            "${XDG_CACHE_HOME:-$HOME/.cache}/nvim" \
            "$HOME/.local/bin/nvim"; then
		blank
        success "Neovim and editor tools uninstalled"
    else
        muted "Neovim uninstallation skipped."
    fi
}

# --- Internal helpers ---

_install_neovim_binary() {
    info "Installing Neovim binary (nightly)..."
    
    ensure_has_command "curl"
    ensure_has_command "tar"

    local archive="nvim-linux-x86_64.tar.gz"
    
    step "Downloading Neovim nightly archive..."
    safe_execute curl -LO "https://github.com/neovim/neovim/releases/download/nightly/$archive" --output-dir "$TMP_DIR"

    step "Extracting to $HOME/.local..."
    safe_mkdir "$HOME/.local"
    safe_execute tar -C "$HOME/.local" -xzf "$TMP_DIR/$archive" --strip-components=1

    success "Neovim installed in $HOME/.local"
}

_install_vim_plug() {
    local plug_path="$1"
    step "Downloading vim-plug..."
	ensure_has_command "curl"

	safe_execute curl -sfLo "$plug_path" --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	success "Vim-plug installed"
}

_install_tree_sitter() {
    step "Installing tree-sitter-cli via npm..."

	npm_install_g "tree-sitter-cli"

	blank
	success "Tree-sitter installed"
}
