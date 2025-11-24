#!/bin/bash
#
# check_vscode_insiders_update.sh - VSCode Insiders Update Manager
#
# Handles version checking and updates for Visual Studio Code Insiders.
# Reference: https://code.visualstudio.com/insiders
#

# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
source "$LIB_DIR/upgrade_utils.sh"

# Get latest VSCode Insiders version from download redirect
get_vscode_insiders_latest_version() {
    local latest_version
    latest_version=$(curl -sL 'https://code.visualstudio.com/sha/download?build=insider&os=linux-deb-x64' -I 2>/dev/null | \
                     grep -i 'location:' | \
                     sed -E 's/.*code-insiders_([0-9.]+-[0-9]+)_.*/\1/' | \
                     tr -d '\r')
    echo "$latest_version"
}

# Download and install VSCode Insiders .deb package
download_and_install_vscode_insiders() {
    local download_url
    download_url=$(curl -sL 'https://code.visualstudio.com/sha/download?build=insider&os=linux-deb-x64' -I 2>/dev/null | \
                   grep -i 'location:' | \
                   awk '{print $2}' | \
                   tr -d '\r')
    
    if [ -z "$download_url" ]; then
        print_error "Failed to get download URL"
        return 1
    fi
    
    local temp_deb="/tmp/code-insiders.deb"
    
    print_status "Downloading VSCode Insiders from: $download_url"
    
    if ${VERBOSE_MODE:-false}; then
        wget --show-progress -O "$temp_deb" "$download_url"
    else
        wget -q --show-progress -O "$temp_deb" "$download_url"
    fi
    
    if [ $? -ne 0 ]; then
        print_error "Failed to download VSCode Insiders"
        rm -f "$temp_deb"
        return 1
    fi
    
    print_status "Installing VSCode Insiders..."
    if ! sudo -v; then
        print_error "Failed to obtain sudo privileges"
        rm -f "$temp_deb"
        return 1
    fi
    
    if ${VERBOSE_MODE:-false}; then
        sudo dpkg -i "$temp_deb"
    else
        sudo dpkg -i "$temp_deb" 2>&1 | tail -10
    fi
    
    if [ $? -eq 0 ]; then
        sudo apt-get install -f -y &> /dev/null
        rm -f "$temp_deb"
        return 0
    else
        print_error "Installation failed"
        rm -f "$temp_deb"
        return 1
    fi
}

# Update VSCode Insiders
check_vscode_insiders_update() {
    print_operation_header "Checking VSCode Insiders updates..."
    
    # Check if VSCode Insiders is installed
    if ! check_app_installed "code-insiders" "VSCode Insiders"; then
        ask_continue
        return 0
    fi
    
    # Get current version
    local current_version
    current_version=$(code-insiders --version 2>/dev/null | head -1)
    
    if [ -z "$current_version" ]; then
        print_error "Failed to get current VSCode Insiders version"
        ask_continue
        return 1
    fi
    
    # Get latest version
    local latest_version
    latest_version=$(get_vscode_insiders_latest_version)
    
    print_status "Current version: $current_version"
    print_status "Latest version: $latest_version"
    
    if [ -z "$latest_version" ]; then
        print_error "Failed to fetch latest version"
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
        print_warning "VSCode Insiders update available: $current_version → $latest_version"
        version_status=2
    else
        print_success "VSCode Insiders is up to date"
        version_status=0
    fi
    
    # Handle update workflow
    if ! handle_update_prompt "VSCode Insiders" "$version_status" \
        "download_and_install_vscode_insiders && \
         print_success 'VSCode Insiders update completed' && \
         show_installation_info 'code-insiders' 'VSCode Insiders'"; then
        ask_continue
        return 1
    fi
}

check_vscode_insiders_update