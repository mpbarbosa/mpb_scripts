#!/bin/bash
#
# update_postman.sh - Postman Update Manager
#
# Handles version checking and updates for Postman API Platform.
# Supports both snap and tarball installations.
#
# Reference: https://learning.postman.com/docs/getting-started/installation/installation-and-updates/
#
# Version: 0.2.0-alpha
# Date: 2025-11-29
# Author: mpb
# Repository: https://github.com/mpbarbosa/mpb_scripts
# Status: Non-production (Alpha)
#
# Version History:
#   0.2.0-alpha (2025-11-29) - Updated to support both snap and tarball installations
#                            - Follows upgrade script pattern v1.2.0
#                            - Fixed VERBOSE variable typo
#                            - Not ready for production use
#
# Dependencies:
#   - wget (for tarball download)
#   - snap (optional, for snap-based installation)
#

# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/postman.yaml"
source "$LIB_DIR/upgrade_utils.sh"

# Override version check for Postman (snap has special requirements)
check_postman_version() {
    print_operation_header "Checking Postman updates..."
    
    # Check if Postman is installed
    if ${VERBOSE_MODE:-false}; then
        print_status "Verifying Postman installation..."
    fi
    if ! command -v postman &>/dev/null; then
        local install_help
        install_help=$(get_config "messages.install_help")
        print_error "Postman is not installed"
        echo -e "$install_help"
        ask_continue
        return 1
    fi
    if ${VERBOSE_MODE:-false}; then
        print_success "Postman installation detected"
    fi
    
    # Detect installation method first
    if ${VERBOSE_MODE:-false}; then
        print_status "Detecting installation method..."
    fi
    local install_method
    install_method=$(detect_install_method)
    if ${VERBOSE_MODE:-false}; then
        print_success "Installation method: $install_method"
    fi
    
    if ${VERBOSE_MODE:-false}; then
        print_status "Retrieving version information..."
    fi
    if [[ "$install_method" == "snap" ]]; then
        # Check if snap version is compatible
        if ! check_snap_compatibility; then
            print_error "Snap version of Postman is incompatible with your system"
            echo ""
            local incompatible_msg
            incompatible_msg=$(get_config "messages.snap_incompatible")
            echo -e "$incompatible_msg"
            echo ""
            if ${VERBOSE_MODE:-false}; then
                print_status "Offering migration to tarball installation..."
            fi
            # Offer to migrate automatically
            if prompt_yes_no "Would you like to automatically migrate to tarball installation?"; then
                migrate_snap_to_tarball
                return $?
            else
                if ${VERBOSE_MODE:-false}; then
                    print_status "Manual migration required. Run 'sudo snap remove postman' then run this script again."
                fi
                print_status "Manual migration required. Run 'sudo snap remove postman' then run this script again."
                ask_continue
                return 1
            fi
        fi
        
        if ${VERBOSE_MODE:-false}; then
            print_success "Snap version is compatible"
        fi
        # Get current version from snap
        CURRENT_VERSION=$(snap info postman 2>/dev/null | grep '^installed:' | awk '{print $2}')
        
        if [ -z "$CURRENT_VERSION" ]; then
            print_error "Failed to get current Postman version"
            ask_continue
            return 1
        fi
        
        # Get latest available version from snap channel
        LATEST_VERSION=$(snap info postman 2>/dev/null | grep 'v11/stable:' | awk '{print $2}')
        
        if [ -z "$LATEST_VERSION" ]; then
            print_warning "Could not determine latest version from snap"
            LATEST_VERSION="$CURRENT_VERSION"
        fi
    elif [[ "$install_method" == "tarball" ]]; then
        # For tarball, get version from GitHub releases
        CURRENT_VERSION=$(get_tarball_version)
        
        if [ -z "$CURRENT_VERSION" ]; then
            print_warning "Could not determine current tarball version"
            CURRENT_VERSION="unknown"
        fi
        
        # Get latest from download page (always latest)
        LATEST_VERSION="latest"
        if ${VERBOSE_MODE:-false}; then
            print_success "Latest version is always 'latest' for tarball installations"
        fi
    else
        print_error "Could not detect Postman installation"
        ask_continue
        return 1
    fi
    
    # Compare versions
    if ${VERBOSE_MODE:-false}; then
        print_success "Retrieved version information"
    fi
    print_status "Current version: $CURRENT_VERSION"
    print_status "Latest version: $LATEST_VERSION"
    
    if [[ "$LATEST_VERSION" == "latest" ]] || [[ "$CURRENT_VERSION" == "unknown" ]]; then
        if ${VERBOSE_MODE:-false}; then
            print_status "Assuming update is available for tarball installation"
        fi
        VERSION_STATUS=2
    else
        compare_versions "$CURRENT_VERSION" "$LATEST_VERSION"
        VERSION_STATUS=$?
    fi
    
    APP_DISPLAY_NAME=$(get_config "application.display_name")
    
    return 0
}

# Check if snap version is compatible with the system
check_snap_compatibility() {
    if ${VERBOSE_MODE:-false}; then
        print_status "Checking snap compatibility..."
    fi
    # Try to get version info - if it fails with library error, it's incompatible
    # Try to get snap postman version with a timeout to avoid hangs
    local snap_output rc
    snap_output=$(timeout 2s snap run postman --version 2>&1) || rc=$?
    rc=${rc:-0}
    # timeout exit code is 124 -> treat as incompatible
    if [ "$rc" -eq 124 ]; then
        return 1
    fi
    # Any GLIBC related error indicates incompatibility
    if echo "$snap_output" | grep -q -E "GLIBC|libc\.so\.6"; then
        return 1
    fi
    # Quick test - just check if command exists without error
    if ! timeout 2 postman --version &>/dev/null; then
        # Command failed or timed out - likely compatibility issue
        return 1
    fi
    return 0
}

# Migrate from snap to tarball installation
migrate_snap_to_tarball() {
    print_operation_header "Migrating from snap to tarball installation"
    
    # Confirm with user
    if ! prompt_yes_no "Remove snap version and install tarball?"; then
        print_status "Migration cancelled"
        return 1
    fi
    
    # Remove snap
    print_status "Removing snap version..."
    if ! sudo snap remove postman; then
        print_error "Failed to remove snap version"
        return 1
    fi
    
    print_success "Snap version removed"
    
    # Install tarball
    print_status "Installing tarball version..."
    if ! perform_postman_update; then
        print_error "Failed to install tarball version"
        return 1
    fi
    
    print_success "Migration completed successfully!"
    return 0
}

# Get version from tarball installation
get_tarball_version() {
    local install_dir
    install_dir=$(get_config "update.install_dir")
    
    if [ -f "$install_dir/version" ]; then
        cat "$install_dir/version"
    else
        echo ""
    fi
}

# Detect installation method
detect_install_method() {
    if command -v snap &>/dev/null && snap list postman &>/dev/null 2>&1; then
        echo "snap"
    elif [ -d "/opt/Postman" ]; then
        echo "tarball"
    else
        echo "unknown"
    fi
}

# Update via snap
update_via_snap() {
    local update_msg
    update_msg=$(get_config "messages.updating_snap")
    print_status "$update_msg"
    
    if sudo snap refresh postman; then
        local success_msg
        success_msg=$(get_config "messages.update_success")
        print_success "$success_msg"
        return 0
    else
        print_error "Failed to update Postman via snap"
        return 1
    fi
}

# Backup existing Postman installation
backup_postman() {
    local install_dir
    install_dir=$(get_config "update.install_dir")
    
    if [[ -d "$install_dir" ]]; then
        local backup_msg
        backup_msg=$(get_config "messages.backing_up")
        print_status "$backup_msg"
        
        local backup_dir="${install_dir}.backup.$(date +%Y%m%d_%H%M%S)"
        sudo mv "$install_dir" "$backup_dir" || {
            print_error "Failed to backup existing installation"
            return 1
        }
        print_success "Backed up to $backup_dir"
    fi
}

# Install Postman from tarball
install_postman_tarball() {
    local tarball="$1"
    local install_dir
    install_dir=$(get_config "update.install_dir")
    local symlink_path
    symlink_path=$(get_config "update.symlink_path")
    
    # Create temporary extraction directory
    local extract_dir
    extract_dir=$(mktemp -d) || {
        print_error "Cannot create temp directory"
        return 1
    }
    trap "rm -rf '$extract_dir'" RETURN
    
    # Extract tarball
    local extracting_msg
    extracting_msg=$(get_config "messages.extracting")
    print_status "$extracting_msg"
    
    if ! tar -xzf "$tarball" -C "$extract_dir" 2>/dev/null; then
        print_error "Failed to extract tarball"
        return 1
    fi
    
    # Install to /opt
    local installing_msg
    installing_msg=$(get_config "messages.installing")
    print_status "$installing_msg"
    
    if ! sudo mv "$extract_dir/Postman" "$install_dir"; then
        print_error "Failed to move to $install_dir"
        return 1
    fi
    
    # Create symbolic link
    local symlink_msg
    symlink_msg=$(get_config "messages.creating_symlink")
    print_status "$symlink_msg"
    
    sudo ln -sf "$install_dir/Postman" "$symlink_path" || {
        print_error "Failed to create symlink"
        return 1
    }
    
    # Create desktop entry
    create_desktop_entry
    
    return 0
}

# Create desktop entry for application launcher
create_desktop_entry() {
    local desktop_msg
    desktop_msg=$(get_config "messages.creating_desktop")
    print_status "$desktop_msg"
    
    local install_dir
    install_dir=$(get_config "update.install_dir")
    local desktop_file="$HOME/.local/share/applications/postman.desktop"
    
    mkdir -p "$(dirname "$desktop_file")"
    
    cat > "$desktop_file" << EOF
[Desktop Entry]
Encoding=UTF-8
Name=Postman
Exec=$install_dir/Postman
Icon=$install_dir/app/resources/app/assets/icon.png
Terminal=false
Type=Application
Categories=Development;
EOF
    
    chmod +x "$desktop_file"
}

# Perform Postman update workflow
perform_postman_update() {
    local download_url
    download_url=$(get_config "update.download_url")
    local download_msg
    download_msg=$(get_config "messages.downloading")
    
    # Create temporary file for download
    local temp_tarball
    temp_tarball=$(mktemp --suffix=.tar.gz) || {
        print_error "Cannot create temp file"
        return 1
    }
    trap "rm -f '$temp_tarball'" RETURN
    
    # Download latest tarball
    print_status "$download_msg"
    if ! wget -q --show-progress "$download_url" -O "$temp_tarball"; then
        print_error "Failed to download Postman"
        return 1
    fi
    
    # Backup and install
    if ! backup_postman; then
        return 1
    fi
    
    if ! install_postman_tarball "$temp_tarball"; then
        return 1
    fi
    
    # Success message
    local success_msg
    success_msg=$(get_config "messages.update_success")
    print_success "$success_msg"
    
    # Show installation info
    local app_name
    app_name=$(get_config "application.name")
    local app_display
    app_display=$(get_config "application.display_name")
    show_installation_info "$app_name" "$app_display"
}

# Main update function
update_postman() {
    # Use custom version check
    if ! check_postman_version; then
        return 0
    fi
    
    # Detect installation method
    local install_method
    install_method=$(detect_install_method)
    
    # Handle update based on installation method
    if [[ "$install_method" == "snap" ]]; then
        if ! handle_update_prompt "$APP_DISPLAY_NAME" "$VERSION_STATUS" \
            "update_via_snap"; then
            ask_continue
            return 1
        fi
    elif [[ "$install_method" == "tarball" ]]; then
        if ! handle_update_prompt "$APP_DISPLAY_NAME" "$VERSION_STATUS" \
            "perform_postman_update"; then
            ask_continue
            return 1
        fi
    else
        print_error "Could not detect Postman installation method"
        local install_help
        install_help=$(get_config "messages.install_help")
        echo -e "$install_help"
        ask_continue
        return 1
    fi
}

update_postman
