#!/bin/bash
#
# pip_manager.sh - Python pip Package Manager Operations
#
# Handles Python package updates via pip.
#
# Version: 0.4.2
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
    
    # List of system packages to exclude (managed by apt, not pip)
    local exclude_packages="dbus-python|PyGObject|distro-info|python-apt"
    
    local outdated=$(pip3 list --outdated 2>/dev/null | tail -n +3)
    if [ -z "$outdated" ]; then
        print_success "All pip packages are up to date"
    else
        # Filter out system packages
        local user_packages=$(echo "$outdated" | grep -vE "^($exclude_packages) " || true)
        
        if [ -z "$user_packages" ]; then
            print_success "All user pip packages are up to date"
            print_status "💡 System packages (managed by apt) are excluded from pip updates"
        else
            print_status "Found outdated user packages:"
            echo "$user_packages" | head -10
            
            if [ "$QUIET_MODE" = false ]; then
                echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Update all outdated pip packages? (y/N): "
                read -r response
                case "$response" in
                    [Yy]|[Yy][Ee][Ss])
                        print_status "Updating pip packages..."
                        
                        local success_count=0
                        local fail_count=0
                        local total_packages=$(echo "$user_packages" | wc -l)
                        
                        echo "$user_packages" | awk '{print $1}' | while read -r package; do
                            if [ -n "$package" ]; then
                                print_status "📦 Updating $package..."
                                if pip3 install -U "$package" --user 2>&1 | grep -q "Successfully installed\|Requirement already satisfied"; then
                                    success_count=$((success_count + 1))
                                    print_success "✅ $package updated successfully"
                                else
                                    fail_count=$((fail_count + 1))
                                    print_warning "⚠️  Failed to update $package (skipping)"
                                fi
                            fi
                        done
                        
                        echo ""
                        if [ $fail_count -eq 0 ]; then
                            print_success "✅ All pip packages updated successfully"
                        else
                            print_warning "⚠️  $fail_count package(s) failed to update (possibly due to missing build dependencies)"
                            print_status "💡 Failed packages may require system dependencies: sudo apt install python3-dev build-essential"
                        fi
                        ;;
                    *)
                        print_status "Skipping pip package updates"
                        ;;
                esac
            else
                print_status "Quiet mode - skipping interactive pip updates"
            fi
        fi
    fi
    
    ask_continue
}

update_pip_packages