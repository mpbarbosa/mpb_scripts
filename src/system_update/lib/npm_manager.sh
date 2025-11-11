#!/bin/bash
#
# npm_manager.sh - Node.js npm Package Manager Operations
#
# Handles Node.js global package updates via npm.
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

update_npm_packages() {
    if ! command -v npm &> /dev/null; then
        print_warning "Node.js npm not installed - skipping npm updates"
        print_status "Install npm: sudo apt install nodejs npm"
        return 0
    fi
    
    print_operation_header "Updating Node.js npm packages..."
    print_status "Checking globally installed npm packages..."
    
    local outdated=$(npm outdated -g --depth=0 2>/dev/null)
    if [ -z "$outdated" ]; then
        print_success "All global npm packages are up to date"
    else
        print_status "Found outdated global packages:"
        echo "$outdated"
        
        if [ "$QUIET_MODE" = false ]; then
            echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Update all global npm packages? (y/N): "
            read -r response
            case "$response" in
                [Yy]|[Yy][Ee][Ss])
                    print_status "Updating global npm packages..."
                    npm update -g 2>&1 | head -30
                    print_success "Global npm packages updated"
                    ;;
                *)
                    print_status "Skipping npm package updates"
                    ;;
            esac
        else
            print_status "Quiet mode - skipping interactive npm updates"
        fi
    fi
    
    ask_continue
}
