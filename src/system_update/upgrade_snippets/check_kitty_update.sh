#!/bin/bash
#
# check_kitty_update.sh - Kitty terminal emulator update manager
#
# Handles version checking and updates for Kitty terminal.
# Reference: https://github.com/kovidgoyal/kitty
#
# Version: 0.1.0-alpha
# Date: 2025-11-25
# Author: mpb
# Repository: https://github.com/mpbarbosa/mpb_scripts
# Status: Non-production (Alpha)
#
# Version History:
#   0.1.0-alpha (2025-11-25) - Initial alpha version with upgrade script pattern
#                            - Migrated from hardcoded to config-driven approach
#                            - Uses config_driven_version_check() from upgrade_utils.sh
#                            - All strings externalized to kitty.yaml
#                            - Not ready for production use
#

# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
source "$LIB_DIR/upgrade_utils.sh"

# Load configuration
CONFIG_FILE="$SCRIPT_DIR/kitty.yaml"

# Update Kitty terminal emulator
check_kitty_update() {
    # Perform config-driven version check
    if ! config_driven_version_check; then
        ask_continue
        return 0
    fi
    
    # Handle update workflow
    local installer_url
    installer_url=$(get_config "update.installer_url")
    local output_lines
    output_lines=$(get_config "update.output_lines")
    local downloading_msg
    downloading_msg=$(get_config "messages.downloading_installer")
    local success_msg
    success_msg=$(get_config "messages.update_success")
    local app_name
    app_name=$(get_config "application.name")
    
    # Build update command
    local update_cmd="print_status '$downloading_msg' && "
    if ${VERBOSE_MODE:-false}; then
        update_cmd+="curl -L '$installer_url' | sh /dev/stdin && "
    else
        update_cmd+="curl -L '$installer_url' | sh /dev/stdin 2>&1 | tail -$output_lines && "
    fi
    update_cmd+="print_success '$success_msg' && "
    update_cmd+="show_installation_info '$app_name' '$APP_DISPLAY_NAME'"
    
    if ! handle_update_prompt "$APP_DISPLAY_NAME" "$VERSION_STATUS" "$update_cmd"; then
        ask_continue
        return 1
    fi
}

check_kitty_update