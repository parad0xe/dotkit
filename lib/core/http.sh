#!/bin/bash

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
