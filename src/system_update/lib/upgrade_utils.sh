#!/bin/bash
#
# upgrade_utils.sh - Common Utilities for Upgrade Snippets
#
# Provides reusable functions for version checking and application updates
# to avoid code duplication across upgrade snippet modules.
#
# Version: 1.1.0
# Date: 2025-11-29
# Author: mpb
# Repository: https://github.com/mpbarbosa/mpb_scripts
# License: MIT
#
# Version History:
#   1.1.0 (2025-11-29) - Added apt package manager support
#                       - New function: get_apt_latest_version()
#                       - Added "apt" case in config_driven_version_check()
#   1.0.0 (2025-11-25) - Initial stable release
#

# Ensure core_lib.sh is loaded
if [ -z "$BLUE" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/core_lib.sh"
fi

#=============================================================================
# CONFIGURATION MANAGEMENT
#=============================================================================

# Read configuration values from YAML files using yq
# Usage: get_config "key.path" "config_file.yaml"
# Returns: configuration value
# Example: get_config "application.name" "$CONFIG_FILE"
get_config() {
    local key="$1"
    local config_file="${2:-$CONFIG_FILE}"
    
    if [ -z "$key" ]; then
        echo ""
        return 1
    fi
    
    if [ ! -f "$config_file" ]; then
        echo ""
        return 1
    fi
    
    yq -r ".$key" "$config_file" 2>/dev/null
}

# Config-driven application version check workflow
# Performs complete version check using configuration file
# Usage: config_driven_version_check
# Requires: CONFIG_FILE environment variable set
# Sets: CURRENT_VERSION, LATEST_VERSION, VERSION_STATUS, APP_DISPLAY_NAME
# Returns: 0 on success, 1 on failure
config_driven_version_check() {
    # Print operation header
    local checking_msg
    checking_msg=$(get_config "messages.checking_updates")
    print_operation_header "$checking_msg"
    
    # Check application installed
    local app_name
    app_name=$(get_config "application.name")
    local app_cmd
    app_cmd=$(get_config "application.command")
    local install_help
    install_help=$(get_config "messages.install_help")
    
    if ! check_app_installed_or_help "$app_name" "$app_cmd" "$install_help"; then
        return 1
    fi
    
    # Get current version
    local version_cmd
    version_cmd=$(get_config "version.command")
    local version_regex
    version_regex=$(get_config "version.regex")
    CURRENT_VERSION=$($version_cmd 2>/dev/null | head -1 | sed -E "s/$version_regex/\1/")
    
    if [ -z "$CURRENT_VERSION" ]; then
        local error_msg
        error_msg=$(get_config "messages.failed_version")
        if [ -z "$error_msg" ]; then
            error_msg=$(get_config "messages.failed_get_version")
        fi
        print_error "$error_msg"
        ask_continue
        return 1
    fi
    
    # Get latest version based on source
    local version_source
    version_source=$(get_config "version.source")
    
    case "$version_source" in
        "github")
            local github_owner
            github_owner=$(get_config "version.github_owner")
            local github_repo
            github_repo=$(get_config "version.github_repo")
            LATEST_VERSION=$(get_github_latest_version "$github_owner" "$github_repo")
            ;;
        "npm")
            local npm_package
            npm_package=$(get_config "application.npm_package")
            LATEST_VERSION=$(get_npm_latest_version "$npm_package" --verbose="${VERBOSE_MODE:-false}")
            ;;
        "apt")
            local package_name
            package_name=$(get_config "version.package_name")
            if [ -z "$package_name" ]; then
                package_name=$(get_config "application.name")
            fi
            LATEST_VERSION=$(get_apt_latest_version "$package_name" --verbose="${VERBOSE_MODE:-false}")
            ;;
        *)
            print_error "Unknown version source: $version_source"
            return 1
            ;;
    esac
    
    # Get display name
    APP_DISPLAY_NAME=$(get_config "application.display_name")
    if [ -z "$APP_DISPLAY_NAME" ]; then
        APP_DISPLAY_NAME="$app_name"
    fi
    
    # Compare and report versions
    compare_and_report_versions "$CURRENT_VERSION" "$LATEST_VERSION" "$APP_DISPLAY_NAME"
    VERSION_STATUS=$?
    
    return 0
}

#=============================================================================
# GITHUB API FUNCTIONS
#=============================================================================

# Fetch latest version tag from GitHub releases
# Usage: get_github_latest_version "owner" "repo"
# Returns: version string (e.g., "3.4" or "0.0.361")
get_github_latest_version() {
    local owner="$1"
    local repo="$2"
    
    if [ -z "$owner" ] || [ -z "$repo" ]; then
        echo ""
        return 1
    fi
    
    local version
    version=$(curl -s "https://api.github.com/repos/$owner/$repo/releases/latest" | \
              grep '"tag_name"' | \
              sed -E 's/.*"([^"]+)".*/\1/' | \
              sed 's/^v//')
    
    echo "$version"
}

# Fetch latest version from npm registry
# Usage: get_npm_latest_version "package-name"
# Returns: version string (e.g., "0.0.361")
get_npm_latest_version() {
    local package="$1"
    local verbose="${2:-false}"
    
    if [ -z "$package" ]; then
        echo ""
        return 1
    fi

    if [ "$verbose" = "true" ]; then
        print_status "Fetching npm latest version for package: $package"
    fi
    
    local version
    version=$(npm view "$package" version 2>/dev/null)
    if [ -z "$version" ]; then
        print_error "Failed to get latest version from npm"
        ask_continue
        return 1
    fi
    
    if [ "$verbose" = "true" ]; then
        print_status "Latest version for $package: $version"
    fi
    
    echo "$version"
}

# Fetch latest version from apt repository
# Usage: get_apt_latest_version "package-name"
# Returns: version string (e.g., "141.0.7390.76-1")
get_apt_latest_version() {
    local package="$1"
    local verbose="${2:-false}"
    
    if [ -z "$package" ]; then
        echo ""
        return 1
    fi

    if [ "$verbose" = "true" ]; then
        print_status "Fetching apt latest version for package: $package"
    fi
    
    local version
    version=$(apt-cache policy "$package" 2>/dev/null | grep "Candidate:" | awk '{print $2}' | sed 's/-[0-9]*$//')
    if [ -z "$version" ]; then
        print_error "Failed to get latest version from apt"
        return 1
    fi
    
    if [ "$verbose" = "true" ]; then
        print_status "Latest version for $package: $version"
    fi
    
    echo "$version"
}

#=============================================================================
# USER INTERACTION FUNCTIONS
#=============================================================================

# Standardized yes/no prompt
# Usage: prompt_yes_no "Question text" "default"
# Returns: 0 for yes, 1 for no
prompt_yes_no() {
    local question="$1"
    local default="${2:-N}"
    
    if [ "$QUIET_MODE" = true ]; then
        [ "$default" = "Y" ] || [ "$default" = "y" ]
        return $?
    fi
    
    local prompt_suffix
    if [ "$default" = "Y" ] || [ "$default" = "y" ]; then
        prompt_suffix="(Y/n)"
    else
        prompt_suffix="(y/N)"
    fi
    
    echo -n -e "${MAGENTA}❓ [PROMPT]${NC} $question $prompt_suffix: "
    read -r response
    
    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        [Nn]|[Nn][Oo])
            return 1
            ;;
        "")
            [ "$default" = "Y" ] || [ "$default" = "y" ]
            return $?
            ;;
        *)
            return 1
            ;;
    esac
}

# Multiple choice prompt
# Usage: prompt_choice "Question" "option1|option2|option3" "default"
# Returns: selected option via echo
prompt_choice() {
    local question="$1"
    local options="$2"
    local default="$3"
    
    if [ "$QUIET_MODE" = true ]; then
        echo "$default"
        return 0
    fi
    
    echo -n -e "${MAGENTA}❓ [PROMPT]${NC} $question ($options): "
    read -r response
    
    if [ -z "$response" ]; then
        echo "$default"
    else
        echo "$response"
    fi
}

# Generic update confirmation prompt
# Usage: prompt_update_confirmation "application_name"
# Returns: 0 for yes (proceed with update), 1 for no (skip update)
# Example: prompt_update_confirmation "tmux"
prompt_update_confirmation() {
    local app_name="$1"
    prompt_yes_no "Update $app_name?"
}

#=============================================================================
# PACKAGE MANAGER FUNCTIONS
#=============================================================================

# Update application via package manager
# Usage: update_via_package_manager "app-name"
# Returns: 0 on success, 1 if no package manager found
update_via_package_manager() {
    local app_name="$1"
    
    if command -v apt &> /dev/null; then
        print_status "Using apt package manager..."
        sudo apt update && sudo apt install --only-upgrade "$app_name" -y
        return $?
    elif command -v brew &> /dev/null; then
        print_status "Using Homebrew package manager..."
        brew upgrade "$app_name"
        return $?
    elif command -v dnf &> /dev/null; then
        print_status "Using dnf package manager..."
        sudo dnf upgrade "$app_name" -y
        return $?
    elif command -v yum &> /dev/null; then
        print_status "Using yum package manager..."
        sudo yum update "$app_name" -y
        return $?
    elif command -v pacman &> /dev/null; then
        print_status "Using pacman package manager..."
        sudo pacman -Syu "$app_name" --noconfirm
        return $?
    else
        print_warning "No supported package manager found"
        return 1
    fi
}

# Detect available package managers
# Usage: detect_available_package_managers
# Returns: space-separated list of available package managers
detect_available_package_managers() {
    local managers=""
    
    command -v apt &> /dev/null && managers="$managers apt"
    command -v brew &> /dev/null && managers="$managers brew"
    command -v dnf &> /dev/null && managers="$managers dnf"
    command -v yum &> /dev/null && managers="$managers yum"
    command -v pacman &> /dev/null && managers="$managers pacman"
    
    echo "$managers" | xargs
}

#=============================================================================
# VERSION CHECKING FUNCTIONS
#=============================================================================

# Check if application is installed
# Usage: check_app_installed "command-name" "app-name"
# Returns: 0 if installed, 1 if not
check_app_installed() {
    local command_name="$1"
    local app_name="${2:-$command_name}"
    
    if ! command -v "$command_name" &> /dev/null; then
        print_warning "$app_name not installed"
        return 1
    fi
    
    return 0
}

# Check if application is installed and show installation help if not
# Usage: check_app_installed_or_help "command-name" "app-name" "install-message"
# Returns: 0 if installed, 1 if not (and shows help + asks to continue)
check_app_installed_or_help() {
    local command_name="$1"
    local app_name="${2:-$command_name}"
    local install_message="$3"
    
    if ! check_app_installed "$command_name" "$app_name"; then
        if [ -n "$install_message" ]; then
            print_status "$install_message"
        fi
        ask_continue
        return 1
    fi
    
    return 0
}

# Extract version from command output
# Usage: extract_version "command output" "regex-pattern"
# Returns: extracted version string
extract_version() {
    local output="$1"
    local pattern="${2:-([0-9]+\.[0-9]+[a-z]?)}"
    
    echo "$output" | sed -E "s/.*$pattern.*/\1/"
}

# Compare and report version status
# Usage: compare_and_report_versions "current" "latest" "app-name"
# Returns: 0 if up-to-date, 1 if current > latest, 2 if update available
compare_and_report_versions() {
    local current_version="$1"
    local latest_version="$2"
    local app_name="${3:-Application}"
    
    print_status "Current version: $current_version"
    print_status "Latest version: $latest_version"
    
    if [ -z "$latest_version" ]; then
        print_error "Failed to fetch latest version"
        return 1
    fi
    
    compare_versions "$current_version" "$latest_version"
    local cmp_result=$?
    
    if [ $cmp_result -eq 2 ]; then
        print_warning "$app_name update available: $current_version → $latest_version"
        return 2
    elif [ $cmp_result -eq 1 ]; then
        print_status "$app_name version is newer than latest release"
        return 1
    else
        print_success "$app_name is up to date"
        return 0
    fi
}

# Handle update workflow after version comparison
# Usage: handle_update_prompt "app-name" version_status update_command_or_function
# Returns: 0 on success or skip, 1 on failure
# Note: Automatically calls ask_continue and returns from parent function if no update needed
handle_update_prompt() {
    local app_name="$1"
    local version_status="$2"
    local update_callback="$3"
    
    # If no update needed (version_status 0=equal, 1=current>latest)
    if [ "$version_status" -ne 2 ]; then
        ask_continue
        return 0
    fi
    
    # Update needed - prompt user
    if ! prompt_yes_no "Update $app_name?"; then
        print_status "Skipping $app_name update"
        ask_continue
        return 0
    fi
    
    # Execute update callback
    print_status "Updating $app_name..."
    
    if [ -n "$update_callback" ]; then
        if eval "$update_callback"; then
            return 0
        else
            return 1
        fi
    fi
    
    return 0
}

# Generic installer script update handler
# Handles common pattern of downloading and running an installer script
# Usage: handle_installer_script_update
# Requires: CONFIG_FILE with update.installer_url, update.output_lines, messages.*
# Returns: 0 on success, 1 on failure
handle_installer_script_update() {
    # Load config values
    local installer_url
    installer_url=$(get_config "update.installer_url")
    local output_lines
    output_lines=$(get_config "update.output_lines")
    local downloading_msg
    downloading_msg=$(get_config "messages.downloading_installer")
    local success_msg
    success_msg=$(get_config "messages.update_success")
    local app_name
    app_name=$(get_config "application.name")
    local install_method
    install_method=$(get_config "update.method")
    
    # Build update command based on method
    local update_cmd
    case "$install_method" in
        "curl_installer")
            if ${VERBOSE_MODE:-false}; then
                update_cmd="curl -L '$installer_url' | sh /dev/stdin"
            else
                update_cmd="curl -L '$installer_url' | sh /dev/stdin 2>&1 | tail -$output_lines"
            fi
            ;;
        "wget_installer")
            if ${VERBOSE_MODE:-false}; then
                update_cmd="wget -nv -O- '$installer_url' | sh /dev/stdin"
            else
                update_cmd="wget -nv -O- '$installer_url' | sh /dev/stdin 2>&1 | tail -$output_lines"
            fi
            ;;
        "wget_sudo_installer")
            if ${VERBOSE_MODE:-false}; then
                update_cmd="sudo -v && wget -nv -O- '$installer_url' | sudo sh /dev/stdin"
            else
                update_cmd="sudo -v && wget -nv -O- '$installer_url' | sudo sh /dev/stdin 2>&1 | tail -$output_lines"
            fi
            ;;
        *)
            print_error "Unknown install method: $install_method"
            return 1
            ;;
    esac
    
    # Execute update via handle_update_prompt
    if ! handle_update_prompt "$APP_DISPLAY_NAME" "$VERSION_STATUS" \
        "print_status '$downloading_msg' && \
         $update_cmd && \
         print_success '$success_msg' && \
         show_installation_info '$app_name' '$APP_DISPLAY_NAME'"; then
        ask_continue
        return 1
    fi
    
    return 0
}

# Handle .deb package download and installation
# Used by scripts that install via downloadable .deb packages
# Reads configuration from CONFIG_FILE YAML
handle_deb_package_update() {
    # Load config values
    local redirect_url
    redirect_url=$(get_config "update.redirect_url")
    local temp_file
    temp_file=$(get_config "update.temp_file")
    local output_lines
    output_lines=$(get_config "update.output_lines")
    local success_msg
    success_msg=$(get_config "messages.update_success")
    local app_name
    app_name=$(get_config "application.name")
    local fix_deps
    fix_deps=$(get_config "update.fix_dependencies")
    
    # Get actual download URL from redirect
    local download_url
    download_url=$(curl -sL "$redirect_url" -I 2>/dev/null | \
                   grep -i 'location:' | \
                   awk '{print $2}' | \
                   tr -d '\r')
    
    if [ -z "$download_url" ]; then
        local error_msg
        error_msg=$(get_config "messages.failed_download_url")
        print_error "$error_msg"
        ask_continue
        return 1
    fi
    
    # Build download and install command
    local downloading_msg
    downloading_msg=$(get_config "messages.downloading")
    downloading_msg="${downloading_msg/\{url\}/$download_url}"
    
    local installing_msg
    installing_msg=$(get_config "messages.installing")
    
    local update_cmd
    if ${VERBOSE_MODE:-false}; then
        update_cmd="print_status '$downloading_msg' && \
                    wget --show-progress -O '$temp_file' '$download_url' && \
                    print_status '$installing_msg' && \
                    sudo -v && \
                    sudo dpkg -i '$temp_file' && \
                    sudo $fix_deps &> /dev/null && \
                    rm -f '$temp_file'"
    else
        update_cmd="print_status '$downloading_msg' && \
                    wget -q --show-progress -O '$temp_file' '$download_url' && \
                    print_status '$installing_msg' && \
                    sudo -v && \
                    sudo dpkg -i '$temp_file' 2>&1 | tail -$output_lines && \
                    sudo $fix_deps &> /dev/null && \
                    rm -f '$temp_file'"
    fi
    
    # Execute update via handle_update_prompt
    if ! handle_update_prompt "$APP_DISPLAY_NAME" "$VERSION_STATUS" \
        "$update_cmd && \
         print_success '$success_msg' && \
         show_installation_info '$app_name' '$APP_DISPLAY_NAME'"; then
        # Cleanup on failure
        rm -f "$temp_file" 2>/dev/null
        ask_continue
        return 1
    fi
    
    return 0
}

#=============================================================================
# BUILD FROM SOURCE UTILITIES
#=============================================================================

# Check for build dependencies
# Usage: check_build_dependencies "dep1" "dep2" "dep3"
# Returns: 0 if all present, 1 if any missing (prints missing deps)
check_build_dependencies() {
    local missing_deps=()
    
    for dep in "$@"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing build dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# Create temporary build directory
# Usage: BUILD_DIR=$(create_build_directory "app-name")
create_build_directory() {
    local app_name="$1"
    local build_dir="/tmp/${app_name}-build-$$"
    
    mkdir -p "$build_dir"
    echo "$build_dir"
}

# Cleanup build directory
# Usage: cleanup_build_directory "/path/to/build/dir" "previous-dir"
cleanup_build_directory() {
    local build_dir="$1"
    local previous_dir="${2:-.}"
    
    cd "$previous_dir" > /dev/null 2>&1 || true
    [ -d "$build_dir" ] && rm -rf "$build_dir"
}

#=============================================================================
# INSTALLATION INFO DISPLAY
#=============================================================================

# Show detailed installation information in verbose mode
# Usage: show_installation_info "command-name" "App Name"
show_installation_info() {
    local command_name="$1"
    local app_name="${2:-$command_name}"
    
    # Only show if VERBOSE_MODE is enabled
    if [ "${VERBOSE_MODE:-false}" != "true" ]; then
        return 0
    fi
    
    print_status "Installation Information:"
    
    # Use whereis to show all installation paths (binary, source, man pages)
    local whereis_output
    whereis_output=$(whereis "$command_name" 2>/dev/null)
    
    if [ -n "$whereis_output" ]; then
        echo -e "${CYAN}   📍 Locations:${NC}"
        # Parse whereis output and display formatted
        local locations
        locations=$(echo "$whereis_output" | cut -d: -f2- | xargs -n1)
        
        while IFS= read -r location; do
            [ -n "$location" ] && echo -e "${CYAN}             ${NC}  $location"
        done <<< "$locations"
    else
        # Fallback to which if whereis returns nothing
        local binary_path
        binary_path=$(which "$command_name" 2>/dev/null)
        [ -n "$binary_path" ] && echo -e "${CYAN}   📍 Binary:${NC}  $binary_path"
    fi
    
    # Show version
    local version_output
    case "$command_name" in
        copilot)
            version_output=$("$command_name" --version 2>/dev/null | head -1)
            [ -n "$version_output" ] && echo -e "${CYAN}   📦 Version:${NC} $version_output"
            ;;
        tmux)
            version_output=$("$command_name" -V 2>/dev/null)
            [ -n "$version_output" ] && echo -e "${CYAN}   📦 Version:${NC} $version_output"
            ;;
        kitty)
            version_output=$("$command_name" --version 2>/dev/null)
            [ -n "$version_output" ] && echo -e "${CYAN}   📦 Version:${NC} $version_output"
            ;;
        *)
            version_output=$("$command_name" --version 2>/dev/null | head -1)
            [ -n "$version_output" ] && echo -e "${CYAN}   📦 Version:${NC} $version_output"
            ;;
    esac
    
    # Show config directory if exists
    local config_paths=()
    [ -d "$HOME/.config/$command_name" ] && config_paths+=("$HOME/.config/$command_name")
    [ -d "$HOME/.$command_name" ] && config_paths+=("$HOME/.$command_name")
    [ -f "$HOME/.${command_name}rc" ] && config_paths+=("$HOME/.${command_name}rc")
    [ -f "$HOME/.config/${command_name}.conf" ] && config_paths+=("$HOME/.config/${command_name}.conf")
    
    if [ ${#config_paths[@]} -gt 0 ]; then
        echo -e "${CYAN}   ⚙️  Config:${NC}"
        for cfg_path in "${config_paths[@]}"; do
            echo -e "${CYAN}            ${NC}  $cfg_path"
        done
    fi
    
    echo ""
}

