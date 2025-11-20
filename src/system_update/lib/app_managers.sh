#!/bin/bash
#
# app_managers.sh - Application Update Managers
#
# Handles updates for specific applications like Kitty, Calibre, and GitHub Copilot CLI.
#
# Version: 0.5.0
# Author: mpb
# Repository: https://github.com/mpbarbosa/mpb_scripts
# License: MIT
#

if [ -z "$BLUE" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/core_lib.sh"
fi

source_upgrade_snippets() {
    # Load upgrade snippets from ../upgrade_snippets if present
    SNIPPETS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/upgrade_snippets"
    if [ -d "$SNIPPETS_DIR" ]; then
        for _f in "$SNIPPETS_DIR"/*.sh; do
            [ -r "$_f" ] && source "$_f"
        done
    fi
}

install_nodejs() {
    print_status "Installing Node.js via NVM (Node Version Manager)..."
    
    # Check if NVM is installed
    if [ ! -d "$HOME/.nvm" ]; then
        print_status "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash 2>&1 | tail -10
        
        # Source NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        if [ ! -d "$HOME/.nvm" ]; then
            print_error "NVM installation failed"
            return 1
        fi
    else
        # Source NVM if already installed
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    
    # Install latest LTS version
    print_status "Installing latest Node.js LTS version..."
    nvm install --lts 2>&1 | tail -10
    nvm use --lts
    nvm alias default lts/*
    
    if command -v node &> /dev/null; then
        print_success "Node.js $(node --version) installed successfully"
        return 0
    else
        print_error "Node.js installation failed"
        return 1
    fi
}

check_nodejs_update() {
    print_operation_header "Checking Node.js updates..."
    
    if ! command -v node &> /dev/null; then
        print_warning "Node.js not installed"
        
        if [ "$QUIET_MODE" = false ]; then
            echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Install Node.js globally? (y/N): "
            read -r response
            case "$response" in
                [Yy]|[Yy][Ee][Ss])
                    if install_nodejs; then
                        ask_continue
                        return 0
                    else
                        ask_continue
                        return 1
                    fi
                    ;;
                *)
                    print_status "Skipping Node.js installation"
                    ask_continue
                    return 0
                    ;;
            esac
        else
            print_status "Run in interactive mode to install Node.js"
            ask_continue
            return 0
        fi
    fi
    
    local current_version
    local latest_lts_version
    current_version=$(node --version 2>/dev/null | sed 's/^v//')
    
    # Source NVM to check for updates
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Get latest LTS version
    if command -v nvm &> /dev/null 2>&1 || [ -s "$NVM_DIR/nvm.sh" ]; then
        latest_lts_version=$(nvm ls-remote --lts 2>/dev/null | tail -1 | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+')
    else
        latest_lts_version=$(curl -s https://nodejs.org/dist/latest/ | grep -oP 'node-v\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi
    
    print_status "Current version: $current_version"
    print_status "Latest LTS version: $latest_lts_version"
    
    if [ -z "$latest_lts_version" ]; then
        print_error "Failed to fetch latest version"
        ask_continue
        return 1
    fi
    
    compare_versions "$current_version" "$latest_lts_version"
    local cmp_result=$?
    
    if [ $cmp_result -eq 2 ]; then
        print_warning "Node.js update available: $current_version → $latest_lts_version"
        
        if [ "$QUIET_MODE" = false ]; then
            echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Update Node.js? (y/N): "
            read -r response
            case "$response" in
                [Yy]|[Yy][Ee][Ss])
                    print_status "Updating Node.js..."
                    if [ -s "$NVM_DIR/nvm.sh" ]; then
                        nvm install --lts 2>&1 | tail -10
                        nvm use --lts
                        nvm alias default lts/*
                        print_success "Node.js updated via NVM to $(node --version)"
                    elif command -v n &> /dev/null; then
                        sudo n lts 2>&1 | tail -10
                        print_success "Node.js updated via 'n'"
                    else
                        print_warning "No Node.js version manager found"
                        print_status "Install NVM: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"
                    fi
                    ;;
                *)
                    print_status "Skipping Node.js update"
                    ;;
            esac
        fi
    else
        print_success "Node.js is up to date"
    fi
    
    ask_continue
}
