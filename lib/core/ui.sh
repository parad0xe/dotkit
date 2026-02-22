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

# Outputs an empty line to standard output for visual spacing.
blank() { echo ""; }

# Prints a standard log message with a leading space.
# Arguments:
#   $1: The message to print.
log()    { printf " %s\n" "$1"; }

# Prints an informational message prefixed with a bold cyan arrow.
# Arguments:
#   $1: The informational message to print.
info()    { printf "${CB_CYAN} ➜ ${C_RESET} %s\n" "$1"; }

# Prints a success message prefixed with a bold green checkmark.
# Arguments:
#   $1: The success message to print.
success() { printf "${CB_GREEN} ✔ ${C_RESET} %s\n" "$1"; }

# Prints a warning message prefixed with a bold yellow warning icon.
# Outputs to standard error (stderr).
# Arguments:
#   $1: The warning message to print.
warn()    { printf "${CB_YELLOW} ⚠ ${C_RESET} %s\n" "$1" >&2; }

# Prints an error message prefixed with a bold red cross.
# Outputs to standard error (stderr).
# Arguments:
#   $1: The error message to print.
err()     { printf "${CB_RED} ✖ ${C_RESET} %s\n" "$1" >&2; }

# Prints a helpful tip prefixed with a purple lightbulb icon.
# Arguments:
#   $1: The tip message to print.
tips()    { printf "${CB_PURPLE} 💡${C_RESET} %s\n" "$1"; }

# Prints a secondary-level step message, indented with a bold blue bullet point.
# Used to detail sub-actions under a main task.
# Arguments:
#   $1: The step description to print.
step()    { printf "    ${CB_BLUE}•${C_RESET} %s\n" "$1"; }

# Prints a deeply indented, grayed-out message for minor details or skipped actions.
# Arguments:
#   $1: The muted message to print.
muted()   { printf "      ${C_GRAY}%s${C_RESET}\n" "$1"; }

# Logs one or multiple error messages and immediately aborts the script execution.
# Arguments:
#   $@: A list of error messages to print before exiting.
fatal()   {
	blank
	for e in "$@"; do
		err "$e"
	done
	exit ${RETERR:-1}
}

# Logs a simulated command execution if the script is running in dry-run mode.
# Formats the output with a yellow [DRY RUN] prefix and directs it to stderr.
# Arguments:
#   $*: The simulated command and its arguments.
dry() {
    if dry_run; then
        printf "    ${CB_YELLOW}• [DRY RUN]${C_GRAY} %s${C_RESET}\n" "$*" >&2
    fi
}

# Renders a stylized, boxed header around the provided text lines. 
# Useful for defining distinct sections within the script's output.
# Arguments:
#   $@: The lines of text to include inside the header box.
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

# Prompts the user for a yes/no confirmation before proceeding.
# Arguments:
#   $1: (Optional) A custom prompt message. Defaults to "Are you sure ?".
# Returns:
#   Success (0) if the user answers yes (y/Y/yes).
#   Error (1) if the user answers no or anything else.
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


