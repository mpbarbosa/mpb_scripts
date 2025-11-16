#!/bin/bash
#
# app_managers.sh - Application Update Managers
#
# Handles updates for specific applications like Kitty, Calibre, and GitHub Copilot CLI.
#
# Version: 0.4.1
# Author: mpb
# Repository: https://github.com/mpbarbosa/mpb_scripts
# License: MIT
#

if [ -z "$BLUE" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/core_lib.sh"
fi

# Update Kitty terminal emulator
check_kitty_update() {
    # Check if Kitty is installed
    if ! command -v kitty &> /dev/null; then
        print_warning "Kitty terminal not installed - skipping update check"
        return 0
    fi
    
    print_operation_header "Checking Kitty terminal updates..."
    
    local current_version
    local latest_version
    current_version=$(kitty --version 2>/dev/null | awk '{print $2}')
    latest_version=$(curl -s https://api.github.com/repos/kovidgoyal/kitty/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    print_status "Current version: $current_version"
    print_status "Latest version: $latest_version"
    
    if [ -z "$latest_version" ]; then
        print_error "Failed to fetch latest version"
        ask_continue
        return 1
    fi
    
    compare_versions "$current_version" "$latest_version"
    local cmp_result=$?
    
    if [ $cmp_result -eq 2 ]; then
        print_warning "Kitty update available: $current_version → $latest_version"
        
        if [ "$QUIET_MODE" = false ]; then
            echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Update Kitty terminal? (y/N): "
            read -r response
            case "$response" in
                [Yy]|[Yy][Ee][Ss])
                    print_status "Updating Kitty..."
                    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin 2>&1 | tail -20
                    print_success "Kitty update completed"
                    ;;
                *)
                    print_status "Skipping Kitty update"
                    ;;
            esac
        fi
    else
        print_success "Kitty is up to date"
    fi
    
    ask_continue
}

check_calibre_installed() {
    # Check if Calibre is installed
    command -v calibre &> /dev/null
}

get_calibre_current_version() {
    # Get the currently installed Calibre version
    if check_calibre_installed; then
        calibre --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1
    else
        echo "not_installed"
    fi
}

get_calibre_latest_version() {
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/kovidgoyal/calibre/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    echo "$latest_version"
}

download_and_install_calibre() {
    print_status "Downloading and installing latest Calibre..."
    if sudo -v; then
        wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin 2>&1 | tail -20
        return $?
    else
        print_error "Failed to obtain sudo privileges"
        return 1
    fi
}

check_calibre_update() {
    print_operation_header "Checking Calibre updates..."
    
    if ! check_calibre_installed; then
        print_warning "Calibre not installed - skipping update check"
        print_status "Install Calibre: wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin"
        ask_continue
        return 0
    fi
    
    local current_version
    local latest_version
    current_version=$(get_calibre_current_version)
    latest_version=$(get_calibre_latest_version)
    
    print_status "Current version: $current_version"
    print_status "Latest version: $latest_version"
    
    compare_versions "$current_version" "$latest_version"
    local cmp_result=$?
    
    if [ $cmp_result -eq 2 ]; then
        print_warning "Calibre update available: $current_version → $latest_version"
        
        if [ "$QUIET_MODE" = false ]; then
            echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Update Calibre? (y/N): "
            read -r response
            case "$response" in
                [Yy]|[Yy][Ee][Ss])
                    if download_and_install_calibre; then
                        print_success "Calibre updated successfully"
                    else
                        print_error "Calibre update failed"
                    fi
                    ;;
                *)
                    print_status "Skipping Calibre update"
                    ;;
            esac
        fi
    else
        print_success "Calibre is up to date"
    fi
    
    ask_continue
}

# Update GitHub Copilot CLI
update_github_copilot_cli() {
    print_operation_header "Checking GitHub Copilot CLI updates..."
    
    if ! command -v npm &> /dev/null; then
        print_warning "npm not installed - skipping Copilot CLI update"
        print_status "Install npm first to use GitHub Copilot CLI"
        ask_continue
        return 0
    fi
    
    # Check if Copilot CLI is installed
    if ! command -v copilot &> /dev/null; then
        print_warning "GitHub Copilot CLI not installed"
        print_status "Install: npm install -g @github/copilot"
        print_status "Requirements: Node.js v22+, npm v10+, active Copilot subscription"
        ask_continue
        return 0
    fi
    
    local current_version
    local latest_version
    
    # Get current version
    current_version=$(npm list -g @github/copilot 2>/dev/null | grep @github/copilot | sed -E 's/.*@([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
    
    # Get latest version from npm registry
    latest_version=$(npm view @github/copilot version 2>/dev/null)
    
    print_status "Current version: $current_version"
    print_status "Latest version: $latest_version"
    
    if [ -z "$latest_version" ]; then
        print_error "Failed to fetch latest version"
        ask_continue
        return 1
    fi
    
    compare_versions "$current_version" "$latest_version"
    local cmp_result=$?
    
    if [ $cmp_result -eq 2 ]; then
        print_warning "GitHub Copilot CLI update available: $current_version → $latest_version"
        
        if [ "$QUIET_MODE" = false ]; then
            echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Update GitHub Copilot CLI? (y/N): "
            read -r response
            case "$response" in
                [Yy]|[Yy][Ee][Ss])
                    print_status "Updating GitHub Copilot CLI..."
                    npm update -g @github/copilot 2>&1 | tail -10
                    print_success "GitHub Copilot CLI updated"
                    ;;
                *)
                    print_status "Skipping GitHub Copilot CLI update"
                    ;;
            esac
        fi
    else
        print_success "GitHub Copilot CLI is up to date"
    fi
    
    ask_continue
}

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
    latest_version=$(curl -sL 'https://code.visualstudio.com/sha/download?build=insider&os=linux-deb-x64' -I 2>/dev/null | grep -i 'location:' | sed 's/.*code-insiders_\([0-9.]*-insider\)_.*/\1/' | tr -d '\r')
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
    
    if [ "$current_version" != "$latest_version" ]; then
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
