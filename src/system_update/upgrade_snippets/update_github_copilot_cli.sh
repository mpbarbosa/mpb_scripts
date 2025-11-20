#!/bin/bash
#
# update_github_copilot_cli.sh - GitHub Copilot CLI Update Manager
#
# Handles version checking and updates for GitHub Copilot CLI.
#

update_github_copilot_cli() {
    print_operation_header "Checking GitHub Copilot CLI updates..."
    
    if ! command -v npm &> /dev/null; then
        print_warning "npm not installed - skipping Copilot CLI update"
        print_status "Install npm first to use GitHub Copilot CLI"
        ask_continue
        return 0
    fi
    
    # Check if Copilot CLI is installed
    if ! command -v copilot &> /dev/null; then
        print_warning "GitHub Copilot CLI not installed"
        print_status "Install: npm install -g @github/copilot"
        print_status "Requirements: Node.js v22+, npm v10+, active Copilot subscription"
        ask_continue
        return 0
    fi
    
    local current_version
    local latest_version
    
    # Get current version
    if command -v copilot &> /dev/null; then
        current_version=$(copilot --version 2>/dev/null | head -1 | sed -E 's/.*@([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
    else
        print_error "GitHub Copilot CLI not found"
        ask_continue
        return 1
    fi
    
    # Get latest version from npm registry
    latest_version=$(npm view @github/copilot version 2>/dev/null)
    
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
        print_warning "GitHub Copilot CLI update available: $current_version → $latest_version"
        
        if [ "$QUIET_MODE" = false ]; then
            echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Update GitHub Copilot CLI? (y/N): "
            read -r response
            case "$response" in
                [Yy]|[Yy][Ee][Ss])
                    print_status "Updating GitHub Copilot CLI..."
                    npm update -g @github/copilot 2>&1 | tail -10
                    print_success "GitHub Copilot CLI updated"
                    ;;
                *)
                    print_status "Skipping GitHub Copilot CLI update"
                    ;;
            esac
        fi
    else
        print_success "GitHub Copilot CLI is up to date"
    fi
    
    ask_continue
}
