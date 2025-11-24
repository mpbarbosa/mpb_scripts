#!/bin/bash
#
# update_tmux.sh - Tmux Update Manager
#
# Handles version checking and updates for tmux terminal multiplexer.
# Reference: https://github.com/tmux/tmux
#
# Dependencies:
#   - libevent 2.x (https://github.com/libevent/libevent/releases/latest)
#   - ncurses (https://invisible-mirror.net/archives/ncurses/)
#   - C compiler (gcc or clang)
#   - make, pkg-config, yacc/bison
#   - autoconf, automake (for building from source)
#

# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
source "$LIB_DIR/upgrade_utils.sh"

build_tmux_from_source() {
    local version=$1
    local build_dir
    
    print_status "Building tmux $version from source..."
    
    # Check for required build dependencies
    if ! check_build_dependencies git make pkg-config autoconf automake; then
        print_status "Install with: sudo apt install git build-essential autoconf automake pkg-config libevent-dev libncurses-dev bison"
        return 1
    fi
    
    # Check for compiler
    if ! command -v gcc &> /dev/null && ! command -v clang &> /dev/null; then
        print_error "Missing build dependencies: gcc or clang"
        print_status "Install with: sudo apt install gcc"
        return 1
    fi
    
    # Create build directory
    build_dir=$(create_build_directory "tmux")
    local original_dir=$(pwd)
    cd "$build_dir" || return 1
    
    # Clone repository
    print_status "Cloning tmux repository..."
    if ! git clone https://github.com/tmux/tmux.git; then
        print_error "Failed to clone tmux repository"
        cleanup_build_directory "$build_dir" "$original_dir"
        return 1
    fi
    
    cd tmux || return 1
    
    # Checkout specific version if provided
    if [ -n "$version" ]; then
        print_status "Checking out version $version..."
        if ! git checkout "$version" 2>/dev/null; then
            print_warning "Failed to checkout version $version, using master branch"
        fi
    fi
    
    # Build process
    print_status "Running autogen.sh..."
    if ! sh autogen.sh; then
        print_error "autogen.sh failed"
        cleanup_build_directory "$build_dir" "$original_dir"
        return 1
    fi
    
    print_status "Running configure..."
    if ! ./configure; then
        print_error "configure failed"
        cleanup_build_directory "$build_dir" "$original_dir"
        return 1
    fi
    
    print_status "Building tmux (this may take a few minutes)..."
    if ! make; then
        print_error "make failed"
        cleanup_build_directory "$build_dir" "$original_dir"
        return 1
    fi
    
    print_status "Installing tmux..."
    if ! sudo make install; then
        print_error "make install failed"
        cleanup_build_directory "$build_dir" "$original_dir"
        return 1
    fi
    
    # Cleanup
    cleanup_build_directory "$build_dir" "$original_dir"
    
    print_success "tmux built and installed from source"
    show_installation_info "tmux" "tmux"
    
    return 0
}

# Perform tmux update with method selection
perform_tmux_update() {
    local latest_version="$1"
    
    # Ask for update method
    local method
    method=$(prompt_choice "Update method: (p)ackage manager or (s)ource build?" "p/s" "p")
    
    if [[ "$method" =~ ^[Ss]$ ]]; then
        build_tmux_from_source "$latest_version"
    else
        # Try package manager update
        if ! update_via_package_manager "tmux"; then
            # No package manager found, offer source build
            if prompt_yes_no "Build from source instead?"; then
                build_tmux_from_source "$latest_version"
            else
                print_status "Build from source instructions:"
                print_status "1. Install dependencies: libevent-dev, ncurses-dev, build-essential, autoconf, automake, pkg-config, bison"
                print_status "2. Clone: git clone https://github.com/tmux/tmux.git"
                print_status "3. Build: cd tmux && sh autogen.sh && ./configure && make"
                print_status "4. Install: sudo make install"
                print_status "Reference: https://github.com/tmux/tmux"
            fi
        else
            print_success "tmux updated via package manager"
            show_installation_info "tmux" "tmux"
        fi
    fi
}

update_tmux() {
    print_operation_header "Checking tmux updates..."
    
    # Check if tmux is installed
    if ! check_app_installed_or_help "tmux" "tmux" "Install via: apt install tmux, brew install tmux, or build from source
Source: https://github.com/tmux/tmux"; then
        return 0
    fi
    
    # Get current version
    local current_version
    current_version=$(tmux -V 2>/dev/null | sed -E 's/tmux ([0-9]+\.[0-9]+[a-z]?).*/\1/')
    
    if [ -z "$current_version" ]; then
        print_error "Failed to get current tmux version"
        ask_continue
        return 1
    fi
    
    # Get latest version from GitHub releases
    local latest_version
    latest_version=$(get_github_latest_version "tmux" "tmux")
    
    # Compare and report versions
    compare_and_report_versions "$current_version" "$latest_version" "tmux"
    local version_status=$?
    
    # If no update needed
    if [ $version_status -ne 2 ]; then
        ask_continue
        return 0
    fi
    
    # Update if needed
    if ! prompt_yes_no "Update tmux?"; then
        print_status "Skipping tmux update"
        ask_continue
        return 0
    fi
    
    print_status "Updating tmux..."
    perform_tmux_update "$latest_version"
    
    ask_continue
}

update_tmux
