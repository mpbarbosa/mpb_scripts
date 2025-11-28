#!/bin/bash
#
# update_npm.sh - npm Update Manager
#
# Handles version checking and updates for npm (Node Package Manager).
# Reference: https://docs.npmjs.com/try-the-latest-stable-version-of-npm
#
# Version: 1.0.0-alpha
# Date: 2025-11-26
# Author: mpb
# Repository: https://github.com/mpbarbosa/mpb_scripts
# Status: Non-production (Alpha)
#
# Version History:
#   1.0.0-alpha (2025-11-26) - Aligned with upgrade script pattern v1.1.0
#                            - Uses Method 1: Direct Command Update
#                            - Added complete version header
#                            - Follows update_github_copilot_cli.sh pattern
#
# Dependencies:
#   - Node.js (required by npm)
#

# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"

# Load configuration
CONFIG_FILE="$SCRIPT_DIR/npm.yaml"

source "$LIB_DIR/upgrade_utils.sh"

# Update npm
# Uses Method 1: Direct Command Update (see upgrade_script_pattern_documentation.md)
update_npm() {
    # Check Node.js dependency first
    local dep_name
    dep_name=$(get_config "dependencies[0].name")
    local dep_cmd
    dep_cmd=$(get_config "dependencies[0].command")
    local dep_help
    dep_help=$(get_config "dependencies[0].help")
    
    if ! check_app_installed_or_help "$dep_cmd" "$dep_name" "$dep_help"; then
        ask_continue
        return 0
    fi
    
    # Perform config-driven version check
    if ! config_driven_version_check; then
        ask_continue
        return 0
    fi
    
    # Handle update workflow with direct npm command
    local update_cmd
    update_cmd=$(get_config "update.command")
    local output_lines
    output_lines=$(get_config "update.output_lines")
    local success_msg
    success_msg=$(get_config "messages.update_success")
    local app_name
    app_name=$(get_config "application.name")
    
    if ! handle_update_prompt "$APP_DISPLAY_NAME" "$VERSION_STATUS" \
        "$update_cmd 2>&1 | tail -$output_lines && \
         print_success '$success_msg' && \
         show_installation_info '$app_name' '$APP_DISPLAY_NAME'"; then
        ask_continue
        return 1
    fi
}

update_npm
