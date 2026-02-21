
module_init() {
	return $RETOK
}

module_check() {
	return $RET_MODULE_DOEXECUTE
}

module_install() {
	return $RETOK
}

module_configure() {
    header "Configuring bin & scripts assets"
	
	info "Synchronizing custom scripts..."
	
    safe_link_all "$ASSETS_DIR/common/bin" "$LOCAL_BIN_DIR"
    safe_link_all "$ASSETS_DIR/common/scripts" "$LOCAL_BIN_DIR"

	blank
    success "Custom scripts synchronized"
}

module_uninstall() {
    header "Uninstalling custom scripts"
    
    if force_confirm || confirm "Do you want to remove custom script symlinks from $LOCAL_BIN_DIR?"; then
        info "Removing symlinks from $LOCAL_BIN_DIR..."
        
        local links_to_remove=()
        for item in "$ASSETS_DIR/common/bin"/* "$ASSETS_DIR/common/scripts"/*; do
            if can_read "$item"; then
                links_to_remove+=("$LOCAL_BIN_DIR/$(basename "$item")")
            fi
        done
        
        safe_rm "${links_to_remove[@]}"
        
        success "Custom scripts unlinked"
    else
        muted "Custom scripts uninstallation skipped."
    fi
}
