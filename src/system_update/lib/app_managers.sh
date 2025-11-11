#!/bin/bash
#
# app_managers.sh - Application Update Managers
#
# Handles updates for specific applications like Kitty, Calibre, and GitHub Copilot CLI.
#
# Version: 0.4.0
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
    current_version=$(kitty --version 2>/dev/null | awk '{print $2}')
    print_status "Current Kitty version: $current_version"
    
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
    else
        print_status "Quiet mode - skipping Kitty update"
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
        calibre --version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1
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
        return 0
    fi
    
    print_operation_header "Checking GitHub Copilot CLI updates..."
    
    # Check if Copilot CLI is installed
    if command -v copilot &> /dev/null; then
        print_status "Copilot CLI installed - updating..."
        npm update -g @github/copilot 2>&1 | tail -10
        print_success "GitHub Copilot CLI updated"
    else
        print_warning "GitHub Copilot CLI not installed"
        print_status "Install: npm install -g @github/copilot"
        print_status "Requirements: Node.js v22+, npm v10+, active Copilot subscription"
    fi
    
    ask_continue
}
