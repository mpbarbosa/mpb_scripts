#!/bin/bash
#
# check_vscode_insiders_update.sh - VSCode Insiders Update Manager
#
# Handles version checking and updates for Visual Studio Code Insiders.
#

check_vscode_insiders_installed() {
    command -v code-insiders &> /dev/null
}

get_vscode_insiders_current_version() {
    if check_vscode_insiders_installed; then
        code-insiders --version 2>/dev/null | head -1
    else
        echo "not_installed"
    fi
}

get_vscode_insiders_latest_version() {
    local latest_version
    latest_version=$(curl -sL 'https://code.visualstudio.com/sha/download?build=insider&os=linux-deb-x64' -I 2>/dev/null | grep -i 'location:' | sed -E 's/.*code-insiders_([0-9.]+-[0-9]+)_.*/\1/' | tr -d '\r')
    echo "$latest_version"
}

download_and_install_vscode_insiders() {
    local download_url
    download_url=$(curl -sL 'https://code.visualstudio.com/sha/download?build=insider&os=linux-deb-x64' -I 2>/dev/null | grep -i 'location:' | awk '{print $2}' | tr -d '\r')
    
    if [ -z "$download_url" ]; then
        print_error "Failed to get download URL"
        return 1
    fi
    
    local temp_deb="/tmp/code-insiders.deb"
    
    print_status "Downloading VSCode Insiders from: $download_url"
    if ! wget -q --show-progress -O "$temp_deb" "$download_url"; then
        print_error "Failed to download VSCode Insiders"
        return 1
    fi
    
    print_status "Installing VSCode Insiders..."
    if sudo -v; then
        if sudo dpkg -i "$temp_deb" 2>&1 | tail -10; then
            sudo apt-get install -f -y &> /dev/null
            rm -f "$temp_deb"
            return 0
        else
            print_error "Installation failed"
            rm -f "$temp_deb"
            return 1
        fi
    else
        print_error "Failed to obtain sudo privileges"
        rm -f "$temp_deb"
        return 1
    fi
}

check_vscode_insiders_update() {
    print_operation_header "Checking VSCode Insiders updates..."
    
    if ! check_vscode_insiders_installed; then
        print_warning "VSCode Insiders not installed - skipping update check"
        print_status "Install from: https://code.visualstudio.com/insiders"
        ask_continue
        return 0
    fi
    
    local current_version
    local latest_version
    current_version=$(get_vscode_insiders_current_version)
    latest_version=$(get_vscode_insiders_latest_version)
    
    print_status "Current version: $current_version"
    print_status "Latest version: $latest_version"
    
    if [ -z "$latest_version" ] || [ "$latest_version" = "not_installed" ]; then
        print_error "Failed to fetch latest version"
        ask_continue
        return 1
    fi
    
    # Strip the last part after the last hyphen for comparison
    local current_version_compare="${current_version%-*}"
    local latest_version_compare="${latest_version%-*}"
    
    if [ "$current_version_compare" != "$latest_version_compare" ]; then
        print_warning "VSCode Insiders update available: $current_version → $latest_version"
        
        if [ "$QUIET_MODE" = false ]; then
            echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Update VSCode Insiders? (y/N): "
            read -r response
            case "$response" in
                [Yy]|[Yy][Ee][Ss])
                    if download_and_install_vscode_insiders; then
                        print_success "VSCode Insiders updated successfully"
                    else
                        print_error "VSCode Insiders update failed"
                    fi
                    ;;
                *)
                    print_status "Skipping VSCode Insiders update"
                    ;;
            esac
        fi
    else
        print_success "VSCode Insiders is up to date"
    fi
    
    ask_continue
}

check_vscode_insiders_update