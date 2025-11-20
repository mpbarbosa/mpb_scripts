#!/bin/bash
#
# pip_manager.sh - Python pip Package Manager Operations
#
# Handles Python package updates via pip.
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

update_pip_packages() {
    if ! command -v pip3 &> /dev/null; then
        print_warning "Python pip3 not installed - skipping pip updates"
        print_status "Install pip: sudo apt install python3-pip"
        return 0
    fi
    
    print_operation_header "Updating Python pip packages..."
    print_status "Checking for outdated packages..."
    
    local outdated=$(pip3 list --outdated 2>/dev/null | tail -n +3)
    if [ -z "$outdated" ]; then
        print_success "All pip packages are up to date"
    else
        print_status "Found outdated packages:"
        echo "$outdated" | head -10
        
        if [ "$QUIET_MODE" = false ]; then
            echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Update all outdated pip packages? (y/N): "
            read -r response
            case "$response" in
                [Yy]|[Yy][Ee][Ss])
                    print_status "Updating pip packages..."
                    pip3 list --outdated | tail -n +3 | awk '{print $1}' | xargs -n1 pip3 install -U 2>&1 | head -50
                    print_success "Pip packages updated"
                    ;;
                *)
                    print_status "Skipping pip package updates"
                    ;;
            esac
        else
            print_status "Quiet mode - skipping interactive pip updates"
        fi
    fi
    
    ask_continue
}

update_pip_packages