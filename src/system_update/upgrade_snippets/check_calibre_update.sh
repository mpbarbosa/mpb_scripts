#!/bin/bash
#
# check_calibre_update.sh - Calibre Update Manager
#
# Handles version checking and updates for Calibre e-book manager.
#

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


check_calibre_update