#!/bin/bash
#
# check_vscode_insiders_update.sh - VSCode Insiders Update Manager
#
# Handles version checking and updates for Visual Studio Code Insiders.
# Reference: https://code.visualstudio.com/insiders
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
#                            - Custom version fetching from Microsoft download redirect
#                            - All strings externalized to vscode_insiders.yaml
#                            - Not ready for production use
#

# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
source "$LIB_DIR/upgrade_utils.sh"

# Load configuration
CONFIG_FILE="$SCRIPT_DIR/vscode_insiders.yaml"

# Get latest VSCode Insiders version from download redirect
get_vscode_insiders_latest_version() {
    local fetch_url
    fetch_url=$(get_config "version.custom_fetch_url")
    local version_regex
    version_regex=$(get_config "version.version_regex")
    
    local latest_version
    latest_version=$(curl -sL "$fetch_url" -I 2>/dev/null | \
                     grep -i 'location:' | \
                     sed -E "s/.*$version_regex.*/\1/" | \
                     tr -d '\r')
    echo "$latest_version"
}

# Download and install VSCode Insiders .deb package
download_and_install_vscode_insiders() {
    local redirect_url
    redirect_url=$(get_config "update.redirect_url")
    
    local download_url
    download_url=$(curl -sL "$redirect_url" -I 2>/dev/null | \
                   grep -i 'location:' | \
                   awk '{print $2}' | \
                   tr -d '\r')
    
    if [ -z "$download_url" ]; then
        local error_msg
        error_msg=$(get_config "messages.failed_download_url")
        print_error "$error_msg"
        return 1
    fi
    
    local temp_deb
    temp_deb=$(get_config "update.temp_file")
    
    local downloading_msg
    downloading_msg=$(get_config "messages.downloading")
    downloading_msg="${downloading_msg/\{url\}/$download_url}"
    print_status "$downloading_msg"
    
    if ${VERBOSE_MODE:-false}; then
        wget --show-progress -O "$temp_deb" "$download_url"
    else
        wget -q --show-progress -O "$temp_deb" "$download_url"
    fi
    
    if [ $? -ne 0 ]; then
        local error_msg
        error_msg=$(get_config "messages.failed_download")
        print_error "$error_msg"
        rm -f "$temp_deb"
        return 1
    fi
    
    local installing_msg
    installing_msg=$(get_config "messages.installing")
    print_status "$installing_msg"
    
    if ! sudo -v; then
        local sudo_error
        sudo_error=$(get_config "messages.failed_sudo")
        print_error "$sudo_error"
        rm -f "$temp_deb"
        return 1
    fi
    
    local output_lines
    output_lines=$(get_config "update.output_lines")
    
    if ${VERBOSE_MODE:-false}; then
        sudo dpkg -i "$temp_deb"
    else
        sudo dpkg -i "$temp_deb" 2>&1 | tail -"$output_lines"
    fi
    
    if [ $? -eq 0 ]; then
        local fix_deps
        fix_deps=$(get_config "update.fix_dependencies")
        sudo $fix_deps &> /dev/null
        rm -f "$temp_deb"
        return 0
    else
        local install_error
        install_error=$(get_config "messages.installation_failed")
        print_error "$install_error"
        rm -f "$temp_deb"
        return 1
    fi
}

# Update VSCode Insiders
check_vscode_insiders_update() {
    local checking_msg
    checking_msg=$(get_config "messages.checking_updates")
    print_operation_header "$checking_msg"
    
    # Check if VSCode Insiders is installed
    local app_name
    app_name=$(get_config "application.name")
    local app_display
    app_display=$(get_config "application.display_name")
    local install_help
    install_help=$(get_config "messages.install_help")
    
    if ! check_app_installed_or_help "$app_name" "$app_display" "$install_help"; then
        ask_continue
        return 0
    fi
    
    # Get current version
    local current_version
    local version_cmd
    version_cmd=$(get_config "version.command")
    current_version=$($version_cmd 2>/dev/null | head -1)
    
    if [ -z "$current_version" ]; then
        local error_msg
        error_msg=$(get_config "messages.failed_version")
        print_error "$error_msg"
        ask_continue
        return 1
    fi
    
    # Get latest version
    local latest_version
    latest_version=$(get_vscode_insiders_latest_version)
    
    print_status "Current version: $current_version"
    print_status "Latest version: $latest_version"
    
    if [ -z "$latest_version" ]; then
        local error_msg
        error_msg=$(get_config "messages.failed_latest_version")
        print_error "$error_msg"
        ask_continue
        return 1
    fi
    
    # Strip the last part after the last hyphen for comparison
    # VSCode Insiders uses format: 1.96.0-insider-1732118645
    local current_version_compare="${current_version%-*}"
    local latest_version_compare="${latest_version%-*}"
    
    # Determine version status manually (VSCode has custom version format)
    local version_status=0
    if [ "$current_version_compare" != "$latest_version_compare" ]; then
        local update_msg
        update_msg=$(get_config "messages.update_available")
        update_msg="${update_msg/\{current\}/$current_version}"
        update_msg="${update_msg/\{latest\}/$latest_version}"
        print_warning "$update_msg"
        version_status=2
    else
        local uptodate_msg
        uptodate_msg=$(get_config "messages.up_to_date")
        print_success "$uptodate_msg"
        version_status=0
    fi
    
    # Handle update workflow
    local success_msg
    success_msg=$(get_config "messages.update_success")
    
    if ! handle_update_prompt "$app_display" "$version_status" \
        "download_and_install_vscode_insiders && \
         print_success '$success_msg' && \
         show_installation_info '$app_name' '$app_display'"; then
        ask_continue
        return 1
    fi
}

check_vscode_insiders_update