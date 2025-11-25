#!/bin/bash
#
# check_vscode_insiders_update.sh - VSCode Insiders Update Manager
#
# Handles version checking and updates for Visual Studio Code Insiders.
# Reference: https://code.visualstudio.com/insiders
#
# Version: 1.0.0-alpha
# Date: 2025-11-25
# Author: mpb
# Repository: https://github.com/mpbarbosa/mpb_scripts
# Status: Non-production (Alpha)
#
# Version History:
#   1.0.0-alpha (2025-11-25) - Aligned with upgrade script pattern v1.1.0
#                            - Uses Method 2: Installer Script Pattern (deb_package)
#                            - Simplified main function to use handle_deb_package_update()
#                            - Removed download_and_install_vscode_insiders() function
#                            - Follows check_kitty_update.sh pattern
#                            - Custom version checking in perform_vscode_version_check()
#   0.1.0-alpha (2025-11-25) - Initial alpha version with upgrade script pattern
#                            - Migrated from hardcoded to config-driven approach
#                            - All strings externalized to vscode_insiders.yaml
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

# Custom version check for VSCode Insiders
# VSCode Insiders has a non-standard version format that requires custom handling
perform_vscode_version_check() {
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
        return 1
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
        return 1
    fi
    
    # Strip the last part after the last hyphen for comparison
    # VSCode Insiders uses format: 1.96.0-insider-1732118645
    local current_version_compare="${current_version%-*}"
    local latest_version_compare="${latest_version%-*}"
    
    # Determine version status manually (VSCode has custom version format)
    VERSION_STATUS=0
    if [ "$current_version_compare" != "$latest_version_compare" ]; then
        local update_msg
        update_msg=$(get_config "messages.update_available")
        update_msg="${update_msg/\{current\}/$current_version}"
        update_msg="${update_msg/\{latest\}/$latest_version}"
        print_warning "$update_msg"
        VERSION_STATUS=2
    else
        local uptodate_msg
        uptodate_msg=$(get_config "messages.up_to_date")
        print_success "$uptodate_msg"
        VERSION_STATUS=0
    fi
    
    # Set global variables for handle_update_prompt
    CURRENT_VERSION="$current_version"
    LATEST_VERSION="$latest_version"
    APP_DISPLAY_NAME="$app_display"
    
    return 0
}

# Update VSCode Insiders
# Uses Method 2: Installer Script Pattern (see upgrade_script_pattern_documentation.md)
# Note: VSCode uses .deb package download instead of shell installer
check_vscode_insiders_update() {
    # Perform custom version check (VSCode has non-standard version format)
    if ! perform_vscode_version_check; then
        ask_continue
        return 0
    fi
    
    # Handle .deb package download and installation (extracted to upgrade_utils.sh)
    handle_deb_package_update
}

check_vscode_insiders_update