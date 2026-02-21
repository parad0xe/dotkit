#!/bin/bash

module_check() {
    if ! file_exists "$HOME/.gitconfig"; then
        return $RET_MODULE_DOEXECUTE
    fi

    return $RET_MODULECHECK_DONOTHING
}

module_install() {
    return $RETOK
}

module_configure() {
	header "Configuring git assets"

    local tmp="$TMP_DIR/.gitconfig"
    local output="$HOME/.gitconfig"

    if force_confirm || confirm "Do you want to generate a custom .gitconfig ?"; then
        local git_user git_email
        local default_user="parad0xe"
        local default_email="parad0xe@protonmail.com"

        if force_confirm; then
            git_user="$default_user"
            git_email="$default_email"
        else
            read -p "  Enter Git Username [$default_user]: " input_user
            git_user="${input_user:-$default_user}"
            
            read -p "  Enter Git Email [$default_email]: " input_email
            git_email="${input_email:-$default_email}"
        fi

        info "Generating $tmp..."
        
        cat <<EOF > "$tmp"
[user]
	name = $git_user
	email = $git_email
	username = $git_user

[pull]
	rebase = false

[core]
    editor = nvim
EOF

		backup_file $output
		safe_mv $tmp $output

		blank
        success "Git configuration file generated at $output"
	else
		muted "Skipped git configuration."
    fi
}

module_uninstall() {
    header "Uninstalling git configuration"
    
    if safe_rm "$HOME/.gitconfig"; then
		blank
        success "Git configuration removed (consider restoring your backups)"
    else
        muted "Git configuration uninstallation skipped."
    fi
}
