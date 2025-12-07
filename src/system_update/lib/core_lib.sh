#!/bin/bash
#
# core_lib.sh - Core utilities and output formatting functions
#
# Provides color definitions, formatted output functions, and common utilities
# used across all package manager modules.
#
# Version: 0.5.0
# Author: mpb
# Repository: https://github.com/mpbarbosa/mpb_scripts
# License: MIT
#

#=============================================================================
# COLOR DEFINITIONS AND OUTPUT FORMATTING
#=============================================================================
# ANSI color codes for consistent, colored terminal output

RED='\033[0;31m'      # Error messages and critical issues
GREEN='\033[0;32m'    # Success messages and positive outcomes  
YELLOW='\033[1;33m'   # Warning messages and cautionary information
BLUE='\033[0;34m'     # Section headers and operation titles
CYAN='\033[0;36m'     # Informational messages and status updates
MAGENTA='\033[0;35m'  # User prompts and interactive elements
WHITE='\033[0;37m'    # White text for enhanced visibility and readability
NC='\033[0m'          # No Color - resets terminal color to default

#=============================================================================
# UTILITY FUNCTIONS FOR FORMATTED OUTPUT
#=============================================================================

print_operation_header() {
    echo -e "\n${BLUE}\033[1m$1\033[0m"
}

print_status() {
    echo -e "${CYAN}ℹ️${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️  [WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}❌ [ERROR]${NC} $1"
}

print_section_header() {
    local section_name="$1"
    local emoji=""
    
    case "$section_name" in
        *"APT"*) emoji="📦" ;;
        *"PACMAN"*) emoji="🏹" ;;
        *"DPKG"*) emoji="🔧" ;;
        *"SNAP"*) emoji="📱" ;;
        *"RUST"*|*"CARGO"*) emoji="🦀" ;;
        *"PYTHON"*|*"PIP"*) emoji="🐍" ;;
        *"NODE"*|*"NPM"*) emoji="📗" ;;
        *"KITTY"*) emoji="🐱" ;;
        *"COPILOT"*|*"GITHUB"*) emoji="🤖" ;;
        *"CALIBRE"*) emoji="📚" ;;
        *"SYSTEM"*|*"UPGRADE"*) emoji="⚡" ;;
        *"INFORMATION"*|*"SUMMARY"*) emoji="ℹ️" ;;
        *) emoji="🔧" ;;
    esac
    
    local section_with_emoji="$emoji $section_name"
    local line_length=80
    local padding_length=$(( (line_length - ${#section_with_emoji} - 2) / 2 ))
    local padding=$(printf "%*s" "$padding_length" "")
    
    echo -e "\033[44;37m${padding} ${section_with_emoji} ${padding}\033[0m"
}

#=============================================================================
# UTILITY HELPER FUNCTIONS
#=============================================================================

ask_continue() {
    if [ "$QUIET_MODE" = true ]; then
        return 0
    fi
    
    echo ""
    read -p "Press Enter to continue or Ctrl+C to exit..."
    echo ""
}

detect_package_manager() {
    if command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v apt-get &> /dev/null; then
        echo "apt"
    else
        echo "unknown"
    fi
}

compare_versions() {
    local version1="$1"
    local version2="$2"
    
    if [ "$version1" = "$version2" ]; then
        return 0
    fi
    
    # Use dpkg --compare-versions if available for better version comparison
    if command -v dpkg &>/dev/null; then
        if dpkg --compare-versions "$version1" eq "$version2" 2>/dev/null; then
            return 0
        elif dpkg --compare-versions "$version1" gt "$version2" 2>/dev/null; then
            return 1
        elif dpkg --compare-versions "$version1" lt "$version2" 2>/dev/null; then
            return 2
        fi
    fi
    
    # Fallback to custom comparison
    local IFS=.
    local i ver1=($version1) ver2=($version2)
    
    for ((i=0; i<${#ver1[@]} || i<${#ver2[@]}; i++)); do
        local part1=${ver1[i]:-0}
        local part2=${ver2[i]:-0}
        
        # Extract numeric and alphabetic parts separately
        local num1=$(echo "$part1" | sed 's/[^0-9].*$//')
        local num2=$(echo "$part2" | sed 's/[^0-9].*$//')
        local alpha1=$(echo "$part1" | sed 's/^[0-9]*//')
        local alpha2=$(echo "$part2" | sed 's/^[0-9]*//')
        
        # Default to 0 if empty
        num1=${num1:-0}
        num2=${num2:-0}
        
        # Compare numeric parts
        if ((10#$num1 > 10#$num2)); then
            return 1
        elif ((10#$num1 < 10#$num2)); then
            return 2
        fi
        
        # If numeric parts are equal, compare alphabetic suffixes
        if [ "$alpha1" != "$alpha2" ]; then
            if [ -z "$alpha1" ] && [ -n "$alpha2" ]; then
                # 3.6 < 3.6a (no suffix is less than any suffix)
                return 2
            elif [ -n "$alpha1" ] && [ -z "$alpha2" ]; then
                # 3.6a > 3.6
                return 1
            elif [[ "$alpha1" > "$alpha2" ]]; then
                return 1
            else
                return 2
            fi
        fi
    done
    
    return 0
}
