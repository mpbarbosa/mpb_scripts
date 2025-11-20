#!/bin/bash
# check_kitty_update.sh - Kitty update snippet
# Extracted from src/system_update/lib/app_managers.sh

# Update Kitty terminal emulator
check_kitty_update() {
    local kitty_installer_url="https://sw.kovidgoyal.net/kitty/installer.sh"
    # Check if Kitty is installed
    if ! command -v kitty &> /dev/null; then
        print_warning "Kitty terminal not installed - skipping update check"
        return 0
    fi
    
    print_operation_header "Checking Kitty terminal updates..."
    
    local current_version
    local latest_version
    current_version=$(kitty --version 2>/dev/null | awk '{print $2}')
    latest_version=$(curl -s https://api.github.com/repos/kovidgoyal/kitty/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^\"]+)".*/\1/')
    
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
                    print_status "Downloading installer from: $kitty_installer_url"
                    if $VERBOSE_MODE; then
                        curl -L "$kitty_installer_url" | sh /dev/stdin
                    else
                        curl -L "$kitty_installer_url" | sh /dev/stdin 2>&1 | tail -20
                    fi
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

check_kitty_update