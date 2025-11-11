#!/bin/bash
#
# cargo_manager.sh - Rust/Cargo Package Manager Operations
#
# Handles Rust toolchain and Cargo package updates.
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

update_rustup_toolchain() {
    print_operation_header "Updating rustup toolchain..."
    
    if rustup update 2>&1 | tee /tmp/rustup_output.txt; then
        print_success "Rustup toolchain updated successfully"
    else
        print_warning "Rustup update encountered issues"
    fi
}

update_rust_toolchains() {
    print_operation_header "Updating all installed Rust toolchains..."
    
    local toolchains=$(rustup toolchain list | awk '{print $1}')
    for toolchain in $toolchains; do
        print_status "Updating $toolchain..."
        rustup update "$toolchain" >/dev/null 2>&1
    done
    
    print_success "All Rust toolchains updated"
}

install_cargo_update_utility() {
    if ! command -v cargo-install-update &> /dev/null; then
        print_status "Installing cargo-update utility..."
        if cargo install cargo-update 2>&1 | grep -q "Installed"; then
            print_success "cargo-update utility installed"
        else
            print_warning "Failed to install cargo-update"
            return 1
        fi
    fi
    return 0
}

update_common_cargo_packages() {
    local common_packages=("ripgrep" "fd-find" "bat" "exa" "tokei" "hyperfine")
    
    for pkg in "${common_packages[@]}"; do
        if cargo install --list | grep -q "^$pkg "; then
            print_status "Updating $pkg..."
            cargo install "$pkg" --force >/dev/null 2>&1 || true
        fi
    done
}

update_cargo_packages() {
    if install_cargo_update_utility; then
        print_operation_header "Updating installed Cargo packages..."
        cargo install-update -a 2>&1 | head -20
        print_success "Cargo packages update completed"
    fi
    
    ask_continue
}

update_rust_packages() {
    if ! command -v rustup &> /dev/null; then
        print_warning "Rust/Cargo not installed - skipping Rust updates"
        print_status "Install Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        return 0
    fi
    
    update_rustup_toolchain
    update_rust_toolchains
    update_cargo_packages
    
    ask_continue
}
