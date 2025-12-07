#!/bin/bash
#
# update_awscli.sh - AWS CLI Update Manager
#
# Handles version checking and updates for AWS CLI v2.
# Reference: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
#
# Version: 0.1.0-alpha
# Date: 2025-12-07
# Author: mpb
# Repository: https://github.com/mpbarbosa/mpb_scripts
# Status: Non-production (Alpha)
#
# Version History:
#   0.1.0-alpha (2025-12-07) - Initial alpha version
#
# Dependencies:
#   - curl
#   - unzip
#   - sudo (for installation)
#

# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
source "$LIB_DIR/upgrade_utils.sh"

# Load configuration
CONFIG_FILE="$SCRIPT_DIR/awscli.yaml"

perform_awscli_install_or_update() {
    local download_msg
    download_msg=$(get_config "messages.downloading_installer")
    local cleanup_msg
    cleanup_msg=$(get_config "messages.cleanup_message")
    local success_msg
    success_msg=$(get_config "messages.update_success")
    
    print_status "$download_msg"
    
    local temp_dir
    temp_dir=$(mktemp -d)
    cd "$temp_dir" || return 1
    
    if ! curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; then
        print_error "Failed to download AWS CLI installer"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    if ! unzip -q awscliv2.zip; then
        print_error "Failed to unzip AWS CLI installer"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    if [ "$VERBOSE_MODE" = true ]; then
        sudo ./aws/install --update
    else
        sudo ./aws/install --update 2>&1 | tail -20
    fi
    
    local install_status=$?
    
    cd - > /dev/null
    
    print_status "$cleanup_msg"
    rm -rf "$temp_dir"
    
    if [ $install_status -eq 0 ]; then
        print_success "$success_msg"
        show_installation_info "aws" "$APP_DISPLAY_NAME"
        return 0
    else
        print_error "AWS CLI installation/update failed"
        return 1
    fi
}

update_awscli() {
    local dep_name
    local dep_cmd
    local dep_help
    
    dep_name=$(get_config "dependencies[0].name")
    dep_cmd=$(get_config "dependencies[0].command")
    dep_help=$(get_config "dependencies[0].help")
    
    if ! check_app_installed_or_help "$dep_name" "$dep_cmd" "$dep_help"; then
        return 0
    fi
    
    dep_name=$(get_config "dependencies[1].name")
    dep_cmd=$(get_config "dependencies[1].command")
    dep_help=$(get_config "dependencies[1].help")
    
    if ! check_app_installed_or_help "$dep_name" "$dep_cmd" "$dep_help"; then
        return 0
    fi
    
    if ! config_driven_version_check; then
        local install_help
        install_help=$(get_config "messages.install_help")
        print_info "$install_help"
        
        if prompt_yes_no "Would you like to install AWS CLI now?"; then
            if ! handle_update_prompt "$APP_DISPLAY_NAME" "2" \
                "perform_awscli_install_or_update"; then
                ask_continue
                return 1
            fi
        fi
        return 0
    fi
    
    if ! handle_update_prompt "$APP_DISPLAY_NAME" "$VERSION_STATUS" \
        "perform_awscli_install_or_update"; then
        ask_continue
        return 1
    fi
}

update_awscli
