#!/bin/bash
#
# check_calibre_update.sh - Calibre Update Manager
#
# Handles version checking and updates for Calibre e-book manager.
# Reference: https://github.com/kovidgoyal/calibre
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
#                            - All strings externalized to calibre.yaml
#                            - Not ready for production use
#

# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
source "$LIB_DIR/upgrade_utils.sh"

# Load configuration
CONFIG_FILE="$SCRIPT_DIR/calibre.yaml"

# Update Calibre e-book manager
check_calibre_update() {
    # Perform config-driven version check
    if ! config_driven_version_check; then
        ask_continue
        return 0
    fi
    
    # Update if needed (VERSION_STATUS: 0=equal, 1=current>latest, 2=update available)
    if [ $VERSION_STATUS -eq 2 ]; then
        local confirm_msg
        confirm_msg=$(get_config "prompts.confirm_update.message")
        
        if prompt_yes_no "$confirm_msg"; then
            local updating_msg
            updating_msg=$(get_config "messages.updating")
            print_status "$updating_msg"
            
            local downloading_msg
            downloading_msg=$(get_config "messages.downloading_installer")
            print_status "$downloading_msg"
            
            # Check for sudo privileges
            if ! sudo -v; then
                local sudo_error
                sudo_error=$(get_config "messages.sudo_failed")
                print_error "$sudo_error"
                ask_continue
                return 1
            fi
            
            # Download and run installer
            local installer_url
            installer_url=$(get_config "update.installer_url")
            local output_lines
            output_lines=$(get_config "update.output_lines")
            
            if ${VERBOSE_MODE:-false}; then
                wget -nv -O- "$installer_url" | sudo sh /dev/stdin
            else
                wget -nv -O- "$installer_url" | sudo sh /dev/stdin 2>&1 | tail -"$output_lines"
            fi
            
            local success_msg
            success_msg=$(get_config "messages.update_success")
            print_success "$success_msg"
            
            local app_name
            app_name=$(get_config "application.name")
            show_installation_info "$app_name" "$APP_DISPLAY_NAME"
        else
            local skip_msg
            skip_msg=$(get_config "messages.skipping_update")
            print_status "$skip_msg"
        fi
    fi
    
    ask_continue
}

check_calibre_update