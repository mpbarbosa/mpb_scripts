#!/bin/bash
#
# system_update.sh - Comprehensive Package Management and System Update Script
#
# This script provides comprehensive package management across multiple package managers
# including APT, Snap, Rust/Cargo, pip (Python), and npm (Node.js). It automates the
# process of updating, upgrading, and maintaining packages while providing intelligent
# error handling and user interaction.
#
# Features:
# - Multi-package-manager support (apt, pacman, snap, cargo, pip, npm)
# - Interactive and quiet modes
# - Intelligent handling of kept back packages
# - Comprehensive package listing and statistics
# - Calibre update checking
# - Detailed error analysis and recovery suggestions
# - Progress tracking and user confirmation options
# - Modular architecture with separated package manager modules
#
# Usage:
#   ./system_update.sh [OPTIONS]
#
# Options:
#   -q, --quiet       Run in quiet mode (no user prompts)
#   -s, --simple      Simple mode (skip cleanup)
#   -f, --full        Full mode (run system_summary.sh first + dist-upgrade)
#   -c, --cleanup     Cleanup only mode
#   -l, --list        List all installed packages
#   --list-detailed   List all packages with detailed information
#   -v, --version     Show version information
#   -h, --help        Show help message
#
# Dependencies:
#   - sudo access for system package operations
#   - Various package managers (detected automatically)
#   - Network connectivity for package updates
#
# Author: mpb
# Repository: https://github.com/mpbarbosa/mpb_scripts
# License: MIT
#

#=============================================================================
# SCRIPT VERSION AND METADATA
#=============================================================================
readonly SCRIPT_VERSION="0.4.0"
readonly SCRIPT_NAME="system_update.sh"
readonly SCRIPT_DESCRIPTION="Comprehensive Package Management and System Update Script"
readonly SCRIPT_AUTHOR="mpb"
readonly SCRIPT_REPOSITORY="https://github.com/mpbarbosa/mpb_scripts"

#=============================================================================
# DETERMINE SCRIPT DIRECTORY AND SOURCE LIBRARIES
#=============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Source all library modules
source "$LIB_DIR/core_lib.sh"
source "$LIB_DIR/apt_manager.sh"
source "$LIB_DIR/pacman_manager.sh"
source "$LIB_DIR/dpkg_manager.sh"
source "$LIB_DIR/snap_manager.sh"
source "$LIB_DIR/cargo_manager.sh"
source "$LIB_DIR/pip_manager.sh"
source "$LIB_DIR/npm_manager.sh"
source "$LIB_DIR/app_managers.sh"

#=============================================================================
# GLOBAL FLAGS AND CONFIGURATION
#=============================================================================
QUIET_MODE=false
SIMPLE_MODE=false
FULL_MODE=false
CLEANUP_ONLY=false
LIST_PACKAGES=false
LIST_DETAILED=false

#=============================================================================
# UTILITY FUNCTIONS
#=============================================================================

show_version() {
    echo -e "${BLUE}${SCRIPT_NAME}${NC} - ${SCRIPT_DESCRIPTION}"
    echo -e "${CYAN}Version:${NC} ${SCRIPT_VERSION}"
    echo -e "${CYAN}Author:${NC} ${SCRIPT_AUTHOR}"
    echo -e "${CYAN}Repository:${NC} ${SCRIPT_REPOSITORY}"
    echo -e "${CYAN}License:${NC} MIT"
    echo ""
    echo -e "${YELLOW}Features:${NC}"
    echo "  • Multi-package-manager support (APT, Pacman, Snap, Rust/Cargo, Python pip, Node.js npm)"
    echo "  • Interactive and quiet modes with hierarchical output formatting"
    echo "  • Intelligent handling of kept back packages and dependency conflicts"
    echo "  • Comprehensive package listing, statistics, and application update checking"
    echo "  • Modular architecture with separated package manager modules"
    echo ""
    echo -e "${GREEN}Package Managers Supported:${NC}"
    echo "  📦 APT/DPKG    🏹 Pacman     🦀 Rust/Cargo"
    echo "  📱 Snap        🐍 Python pip 📗 Node.js npm"
    echo "  🐱 Kitty       📚 Calibre    🤖 GitHub Copilot CLI"
}

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Comprehensive system update and package management script supporting multiple
package managers including APT, Pacman, Snap, Cargo, pip, and npm.

Options:
    -q, --quiet         Run in quiet mode (no user prompts)
    -s, --simple        Simple mode (skip cleanup operations)
    -f, --full          Full mode (run system_summary.sh + dist-upgrade)
    -c, --cleanup       Cleanup only mode (just run cleanup operations)
    -l, --list          List all installed packages
    --list-detailed     List all packages with detailed information
    -v, --version       Show version information
    -h, --help          Show this help message

Examples:
    $SCRIPT_NAME                 # Run with interactive prompts
    $SCRIPT_NAME -q              # Run quietly without prompts
    $SCRIPT_NAME -f              # Full system upgrade
    $SCRIPT_NAME -l              # List installed packages
    $SCRIPT_NAME -c              # Cleanup only

Package Managers:
    • APT/DPKG (Debian/Ubuntu)
    • Pacman (Arch Linux)
    • Snap (Universal packages)
    • Rust/Cargo
    • Python pip
    • Node.js npm
    • Kitty terminal
    • Calibre e-book manager
    • GitHub Copilot CLI

Author: $SCRIPT_AUTHOR
Repository: $SCRIPT_REPOSITORY
License: MIT
EOF
}

list_all_packages() {
    local detailed="${1:-}"
    
    print_section_header "INSTALLED PACKAGES SUMMARY"
    
    PKG_MANAGER=$(detect_package_manager)
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        print_operation_header "APT Packages:"
        local apt_count=$(apt list --installed 2>/dev/null | wc -l)
        print_status "Total APT packages: $apt_count"
        
        if [ "$detailed" = "--detailed" ]; then
            apt list --installed 2>/dev/null | head -50
        fi
    elif [ "$PKG_MANAGER" = "pacman" ]; then
        print_operation_header "Pacman Packages:"
        local pacman_count=$(pacman -Q | wc -l)
        print_status "Total Pacman packages: $pacman_count"
        
        if [ "$detailed" = "--detailed" ]; then
            pacman -Q | head -50
        fi
    fi
    
    if command -v snap &> /dev/null; then
        print_operation_header "Snap Packages:"
        snap list 2>/dev/null | head -20
    fi
    
    if command -v cargo &> /dev/null; then
        print_operation_header "Cargo Packages:"
        cargo install --list 2>/dev/null | head -20
    fi
    
    if command -v pip3 &> /dev/null; then
        print_operation_header "Python pip Packages:"
        local pip_count=$(pip3 list 2>/dev/null | wc -l)
        print_status "Total pip packages: $pip_count"
        
        if [ "$detailed" = "--detailed" ]; then
            pip3 list 2>/dev/null | head -30
        fi
    fi
    
    if command -v npm &> /dev/null; then
        print_operation_header "Node.js Global Packages:"
        npm list -g --depth=0 2>/dev/null | head -20
    fi
}

#=============================================================================
# ARGUMENT PARSING
#=============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        -s|--simple)
            SIMPLE_MODE=true
            shift
            ;;
        -f|--full)
            FULL_MODE=true
            shift
            ;;
        -c|--cleanup)
            CLEANUP_ONLY=true
            shift
            ;;
        -l|--list)
            LIST_PACKAGES=true
            shift
            ;;
        --list-detailed)
            LIST_PACKAGES=true
            LIST_DETAILED=true
            shift
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

#=============================================================================
# MAIN EXECUTION
#=============================================================================

# Load .bashrc if available
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"

# Handle list packages mode
if [ "$LIST_PACKAGES" = true ]; then
    echo "=========================================="
    if [ "$LIST_DETAILED" = true ]; then
        list_all_packages --detailed
    else
        list_all_packages
    fi
    exit 0
fi

# Execute system_summary.sh if full mode is enabled
if [ "$FULL_MODE" = true ]; then
    print_status "Full mode enabled - executing system_summary.sh first..."
    if [ -f "$SCRIPT_DIR/../system_summary.sh" ]; then
        if bash "$SCRIPT_DIR/../system_summary.sh"; then
            true
        else
            print_warning "system_summary.sh execution failed, continuing with operations..."
        fi
    else
        print_warning "system_summary.sh not found in parent directory, skipping..."
    fi
    ask_continue
fi

# Handle cleanup only mode
if [ "$CLEANUP_ONLY" = true ]; then
    print_status "Running in cleanup-only mode"
    PKG_MANAGER=$(detect_package_manager)
    
    if [ "$PKG_MANAGER" = "pacman" ]; then
        source "$LIB_DIR/pacman_manager.sh"
        clean_pacman_cache
        remove_pacman_orphans
    elif [ "$PKG_MANAGER" = "apt" ]; then
        cleanup
    fi
    exit 0
fi

# Detect package manager
PKG_MANAGER=$(detect_package_manager)

# Package Manager Specific Operations
if [ "$PKG_MANAGER" = "pacman" ]; then
    print_section_header "PACMAN PACKAGE MANAGER"
    check_pacman_config
    update_pacman_database
    upgrade_pacman_packages
elif [ "$PKG_MANAGER" = "apt" ]; then
    check_broken_packages
    print_section_header "APT PACKAGE MANAGER"
    check_unattended_upgrades
    update_package_list
    upgrade_packages
    
    print_section_header "DPKG PACKAGE MANAGER"
    maintain_dpkg_packages
else
    print_warning "No supported package manager detected (apt or pacman)"
fi

# Snap Package Manager Operations
print_section_header "SNAP PACKAGE MANAGER"
update_snap_packages

# Rust/Cargo Package Manager Operations
print_section_header "RUST/CARGO PACKAGE MANAGER"
update_rust_packages

# Python pip Package Manager Operations
print_section_header "PYTHON PIP PACKAGE MANAGER"
update_pip_packages

# Node.js npm Package Manager Operations
print_section_header "NODE.JS NPM PACKAGE MANAGER"
update_npm_packages

# Node.js Updates
print_section_header "NODE.JS"
check_nodejs_update

# Kitty Terminal Emulator Updates
print_section_header "KITTY TERMINAL EMULATOR"
check_kitty_update

# GitHub Copilot CLI Updates
print_section_header "GITHUB COPILOT CLI"
update_github_copilot_cli

# VSCode Insiders Updates
print_section_header "VSCODE INSIDERS"
check_vscode_insiders_update

# Calibre Application Updates
print_section_header "CALIBRE APPLICATION"
check_calibre_update

# System Upgrade Operations (only in full mode)
if [ "$FULL_MODE" = true ]; then
    print_section_header "SYSTEM UPGRADE"
    if [ "$PKG_MANAGER" = "apt" ]; then
        full_upgrade
    elif [ "$PKG_MANAGER" = "pacman" ]; then
        print_status "Full system upgrade already performed with pacman -Syu"
    fi
fi

# Cleanup unless in simple mode
if [ "$SIMPLE_MODE" = false ]; then
    if [ "$PKG_MANAGER" = "pacman" ]; then
        clean_pacman_cache
        remove_pacman_orphans
    elif [ "$PKG_MANAGER" = "apt" ]; then
        cleanup
    fi
fi

# Final status
echo "=========================================="
print_success "Comprehensive system update and package management script completed successfully!"

# Show summary of installed packages
print_status "Summary of installed packages:"
if [ "$PKG_MANAGER" = "pacman" ]; then
    pacman -Q | wc -l | awk '{print "Total installed packages: " $1}'
elif [ "$PKG_MANAGER" = "apt" ]; then
    apt list --installed 2>/dev/null | wc -l | awk '{print "Total installed packages: " $1}'
fi

# Check if reboot is required
if [ -f /var/run/reboot-required ]; then
    print_warning "A system reboot is required to complete the updates."
    echo "You can reboot now using: sudo reboot"
fi

exit 0
