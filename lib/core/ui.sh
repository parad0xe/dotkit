#!/bin/bash

readonly C_RESET="\033[0m"
readonly C_BOLD="\033[1m"
readonly C_DIM="\033[2m"

# Std colors
readonly C_RED="\033[31m"
readonly C_GREEN="\033[32m"
readonly C_YELLOW="\033[33m"
readonly C_BLUE="\033[34m"
readonly C_PURPLE="\033[35m"
readonly C_CYAN="\033[36m"
readonly C_GRAY="\033[90m"

# Bold colors
readonly CB_RED="\033[1;31m"
readonly CB_GREEN="\033[1;32m"
readonly CB_YELLOW="\033[1;33m"
readonly CB_BLUE="\033[1;34m"
readonly CB_PURPLE="\033[1;35m"
readonly CB_CYAN="\033[1;36m"
readonly CB_WHITE="\033[1;37m"


blank() { echo ""; }

# Main actions (level 1)
log()    { printf " %s\n" "$1"; }
info()    { printf "${CB_CYAN} ➜ ${C_RESET} %s\n" "$1"; }
success() { printf "${CB_GREEN} ✔ ${C_RESET} %s\n" "$1"; }
warn()    { printf "${CB_YELLOW} ⚠ ${C_RESET} %s\n" "$1" >&2; }
err()     { printf "${CB_RED} ✖ ${C_RESET} %s\n" "$1" >&2; }
tips()    { printf "${CB_PURPLE} 💡${C_RESET} %s\n" "$1"; }

# Details and sub-actions (level 2)
step()    { printf "    ${CB_BLUE}•${C_RESET} %s\n" "$1"; }
muted()   { printf "      ${C_GRAY}%s${C_RESET}\n" "$1"; }

fatal()   {
	blank
	for e in "$@"; do
		err "$e"
	done
	exit ${RETERR:-1}
}

dry() {
    if dry_run; then
        printf "    ${CB_YELLOW}• [DRY RUN]${C_GRAY} %s${C_RESET}\n" "$*" >&2
    fi
}

header() {
    [[ $# -eq 0 ]] && return

    local lines=("$@")
    local max_len=0
    local padding=4

    for line in "${lines[@]}"; do
        (( ${#line} > max_len )) && max_len=${#line}
    done

    local content_width=$(( max_len + (padding * 2) ))
    
    local edge
    printf -v edge '%*s' "$content_width" ""
    edge="${edge// /=}"

    blank
    printf "${CB_PURPLE} +${edge}+ ${C_RESET}\n"
    for line in "${lines[@]}"; do
        printf -v formatted_line " %-*s " "$((content_width - $padding))" "$line"
        printf "${CB_PURPLE} |${C_RESET} %s ${CB_PURPLE}| ${C_RESET}\n" "$formatted_line"
    done
    printf "${CB_PURPLE} +${edge}+ ${C_RESET}\n"
    blank
}

confirm() {
    local prompt="${1:-Are you sure ?} [y/N] "
    read -r -p " ${prompt}" response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return $RETOK
            ;;
        *)
            return $RETERR
            ;;
    esac
}


