#!/bin/bash
#
# update_github_copilot_cli.sh - GitHub Copilot CLI Update Manager
#
# Handles version checking and updates for GitHub Copilot CLI.
#

# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
source "$LIB_DIR/upgrade_utils.sh"

update_github_copilot_cli() {
    print_operation_header "Checking GitHub Copilot CLI updates..."
    
    # Check npm dependency
    if ! check_app_installed_or_help "npm" "npm" "Install npm first to use GitHub Copilot CLI"; then
        return 0
    fi
    
    # Check if Copilot CLI is installed
    if ! check_app_installed_or_help "copilot" "GitHub Copilot CLI" "Install: npm install -g @github/copilot
Requirements: Node.js v22+, npm v10+, active Copilot subscription"; then
        return 0
    fi
    
    # Get current version
    local current_version
    current_version=$(copilot --version 2>/dev/null | head -1 | sed -E 's/.*@([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
    
    if [ -z "$current_version" ]; then
        print_error "Failed to get current version"
        ask_continue
        return 1
    fi
    
    # Get latest version from npm registry
    local latest_version
    latest_version=$(get_npm_latest_version "@github/copilot" --verbose="${VERBOSE_MODE:-false}") 
    
    # Compare and report versions
    compare_and_report_versions "$current_version" "$latest_version" "GitHub Copilot CLI"
    local version_status=$?
    
    # Handle update workflow
    if ! handle_update_prompt "GitHub Copilot CLI" "$version_status" \
        "npm install -g --force @github/copilot@latest 2>&1 | tail -10 && \
         print_success 'GitHub Copilot CLI updated' && \
         show_installation_info 'copilot' 'GitHub Copilot CLI'"; then
        ask_continue
        return 1
    fi
}

update_github_copilot_cli