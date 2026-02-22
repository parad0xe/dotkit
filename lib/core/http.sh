#!/bin/bash

# Fetches the latest release tag name for a given GitHub repository using the GitHub API.
# If the API request fails (e.g., due to rate limits or network issues), it returns 
# a provided fallback version. If no fallback is provided, it triggers a fatal error.
# Arguments:
#   $1: The GitHub repository in the format "owner/repository" (e.g., "jesseduffield/lazygit").
#   $2: (Optional) A fallback version string to use if the fetch fails.
# Outputs:
#   Prints the fetched version string (or the fallback version) to standard output.
get_github_latest_release() {
    local repo="$1"
    local fallback="${2:-}"
    local latest_version

    latest_version=$(curl -s --connect-timeout 5 "https://api.github.com/repos/${repo}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if is_empty "$latest_version"; then
        if is_not_empty "$fallback"; then
            warn "GitHub API limit reached or offline for $repo. Falling back to $fallback" >&2
            echo "$fallback"
        else
            fatal "Failed to fetch latest release for $repo and no fallback provided" >&2
        fi
    else
        echo "${latest_version}"
    fi
}
