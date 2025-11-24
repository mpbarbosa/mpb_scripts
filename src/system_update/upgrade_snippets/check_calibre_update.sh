#!/bin/bash
#
# check_calibre_update.sh - Calibre Update Manager
#
# Handles version checking and updates for Calibre e-book manager.
# Reference: https://github.com/kovidgoyal/calibre
#

# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
source "$LIB_DIR/upgrade_utils.sh"

# Update Calibre e-book manager
check_calibre_update() {
    local calibre_installer_url="https://download.calibre-ebook.com/linux-installer.sh"
    
    print_operation_header "Checking Calibre updates..."
    
    # Check if Calibre is installed
    if ! check_app_installed "calibre" "Calibre e-book manager"; then
        ask_continue
        return 0
    fi
    
    # Get current version
    local current_version
    current_version=$(calibre --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    
    if [ -z "$current_version" ]; then
        print_error "Failed to get current Calibre version"
        ask_continue
        return 1
    fi
    
    # Get latest version from GitHub releases
    local latest_version
    latest_version=$(get_github_latest_version "kovidgoyal" "calibre")
    
    # Compare and report versions
    compare_and_report_versions "$current_version" "$latest_version" "Calibre e-book manager"
    local version_status=$?
    
    # Update if needed (version_status: 0=equal, 1=current>latest, 2=update available)
    if [ $version_status -eq 2 ]; then
        if prompt_yes_no "Update Calibre?"; then
            print_status "Updating Calibre..."
            print_status "Downloading installer from: $calibre_installer_url"
            if ! sudo -v; then
                print_error "Failed to obtain sudo privileges"
                ask_continue
                return 1
            fi
            if ${VERBOSE_MODE:-false}; then
                wget -nv -O- "$calibre_installer_url" | sudo sh /dev/stdin
            else
                wget -nv -O- "$calibre_installer_url" | sudo sh /dev/stdin 2>&1 | tail -20
            fi
            print_success "Calibre update completed"
            show_installation_info "calibre" "Calibre e-book manager"
        else
            print_status "Skipping Calibre update"
        fi
    fi
    
    ask_continue
}


check_calibre_update