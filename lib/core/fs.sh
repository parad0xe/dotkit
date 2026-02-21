#!/bin/bash

is_empty() {
	[[ -z "$1" ]]
}

is_not_empty() {
	[[ -n "$1" ]]
}

file_exists() {
	[[ -f "$1" ]]
}

non_empty_file() {
	[[ -s "$1" ]]
}

dir_exists() {
	[[ -d "$1" ]]
}

ensure_has_file() {
	if dry_run; then
		return $RETOK
	fi
	if ! file_exists "$1"; then
		err "File $1 not found"
		exit $RETERR
	fi
}

can_read() {
	ensure_has_file "$1"
	[[ -r "$1" ]]
}

safe_mkdir() {
    for dir in "$@"; do
        if dry_run; then
            dry "mkdir -p $dir"
        else
            mkdir -p "$dir"
        fi
    done
}

safe_link_all() {
    local src="$1"
    local dst="$2"
    local header_printed=false
   
    for item in "$src"/*; do
        can_read "$item" || continue
        
        local target_file="$dst/$(basename "$item")"
        
        if [ -L "$target_file" ] && [ "$(readlink "$target_file")" = "$item" ]; then
            continue
        fi
        
        if [ "$header_printed" = false ]; then
            info "Linking $(basename "$src") to $dst"
            safe_mkdir "$dst"
            header_printed=true
        fi
        
        safe_link "$item" "$target_file"
    done

	if [ "$header_printed" = false ]; then
		step "skipped $src -> $dst (already linked)"
	fi
}

safe_link() {
    local src="$1" dst="$2"

    if [ -e "$dst" ] || [ -L "$dst" ]; then
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
			step "skipped $src -> $dst (already linked)"
            return
        fi
        backup_file "$dst"
    fi

    safe_mkdir "$(dirname "$dst")"
    safe_execute ln -Tsf "$src" "$dst"
	
	if ! dry_run; then
		step "link $src -> $dst"
	fi
}

safe_mv() {
    if [ "$#" -lt 2 ]; then
        warn "safe_mv requires at least two arguments."
        return $RETERR
    fi

    local dst="${@: -1}"
    local srcs=("${@:1:$#-1}")

    if [ "${#srcs[@]}" -gt 1 ]; then
        safe_mkdir "$dst"
    else
        safe_mkdir "$(dirname "$dst")"
    fi

    for src in "${srcs[@]}"; do
        if ! dry_run && [ ! -e "$src" ]; then
            warn "Cannot move: '$src' does not exist."
            continue
        fi

        local target_file="$dst"
        if [ -d "$dst" ]; then
            target_file="${dst%/}/$(basename "$src")"
        fi

        if [ -e "$target_file" ]; then
            backup_file "$target_file"
        fi

        safe_execute mv "$src" "$dst"
        
        if ! dry_run; then
            step "mv: $src -> $dst"
        fi
    done
}

safe_rm() {
    local targets=()

    for item in "$@"; do
        local clean_item="${item%/}"

        if [ -z "$clean_item" ] || \
           [ "$clean_item" = "/" ] || \
           [ "$clean_item" = "/*" ] || \
           [ "$clean_item" = "$HOME" ]; then
            
            fatal "SECURITY BLOCK: Attempted to delete critical path -> '${item:-[EMPTY_STRING]}'. Aborting."
        fi

        if [ -e "$item" ] || [ -L "$item" ]; then
            targets+=("$item")
        fi
    done

    if [ ${#targets[@]} -eq 0 ]; then
        return $RETERR
    fi

    info "The following ${#targets[@]} item(s) will be permanently deleted:"
    for target in "${targets[@]}"; do
        step "$target"
    done

    blank
    if force_confirm || confirm "Do you want to proceed with deletion?"; then
        safe_execute rm -rf "${targets[@]}"
    else
        warn "Deletion aborted for these items."
        return $RETERR
    fi
}

backup_file() {
    local target="$1"

    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        return
    fi

    local rel_path="${target#$HOME/}"
    rel_path="${rel_path#/}"
    
    local dest_backup="$BACKUP_DIR/$rel_path"
    
    safe_mkdir "$(dirname "$dest_backup")" 
    safe_execute cp -r "$target" "$dest_backup"

	if ! dry_run; then
    	muted "Backup created: -> $dest_backup"
	fi
}
