#!/bin/bash
#
# check_kitty_update.sh - Kitty terminal emulator update manager
#
# Handles version checking and updates for Kitty terminal.
# Reference: https://github.com/kovidgoyal/kitty
#

# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
source "$LIB_DIR/upgrade_utils.sh"

# Update Kitty terminal emulator
check_kitty_update() {
    local kitty_installer_url="https://sw.kovidgoyal.net/kitty/installer.sh"
    
    print_operation_header "Checking Kitty terminal updates..."
    
    # Check if Kitty is installed
    if ! check_app_installed "kitty" "Kitty terminal"; then
        ask_continue
        return 0
    fi
    
    # Get current version
    local current_version
    current_version=$(kitty --version 2>/dev/null | awk '{print $2}')
    
    if [ -z "$current_version" ]; then
        print_error "Failed to get current Kitty version"
        ask_continue
        return 1
    fi
    
    # Get latest version from GitHub releases
    local latest_version
    latest_version=$(get_github_latest_version "kovidgoyal" "kitty")
    
    # Compare and report versions
    compare_and_report_versions "$current_version" "$latest_version" "Kitty terminal"
    local version_status=$?
    
    # Handle update workflow
    local update_cmd="print_status 'Downloading installer from: $kitty_installer_url' && "
    if ${VERBOSE_MODE:-false}; then
        update_cmd+="curl -L '$kitty_installer_url' | sh /dev/stdin && "
    else
        update_cmd+="curl -L '$kitty_installer_url' | sh /dev/stdin 2>&1 | tail -20 && "
    fi
    update_cmd+="print_success 'Kitty update completed' && "
    update_cmd+="show_installation_info 'kitty' 'Kitty terminal'"
    
    if ! handle_update_prompt "Kitty terminal" "$version_status" "$update_cmd"; then
        ask_continue
        return 1
    fi
}

check_kitty_update