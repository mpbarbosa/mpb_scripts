#!/bin/bash
#
# update_oh_my_bash.sh - Oh-My-Bash Update Manager
#
# Handles version checking and updates for oh-my-bash framework.
# Reference: https://github.com/ohmybash/oh-my-bash
#
# Version: 1.0.0-alpha
# Date: 2025-11-27
# Author: mpb
# Repository: https://github.com/mpbarbosa/mpb_scripts
# Status: Non-production (Alpha)
#
# Version History:
#   1.0.0-alpha (2025-11-27) - Aligned with upgrade script pattern v1.1.0
#                            - Uses Method 3: Custom Update Logic
#                            - Git commit-based versioning
#                            - Git pull update mechanism
#
# Dependencies:
#   - git (version control)
#

# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
source "$LIB_DIR/upgrade_utils.sh"

# Load configuration
CONFIG_FILE="$SCRIPT_DIR/oh_my_bash.yaml"

# Check if oh-my-bash is installed
check_oh_my_bash_installed() {
    local install_dir
    install_dir=$(eval echo "$(get_config "application.installation_dir")")
    
    if [ ! -d "$install_dir" ]; then
        local not_installed_msg
        not_installed_msg=$(get_config "messages.not_installed")
        print_error "$not_installed_msg"
        
        local install_help
        install_help=$(get_config "messages.install_help")
        print_status "$install_help"
        return 1
    fi
    
    # Check if it's a git repository
    if [ ! -d "$install_dir/.git" ]; then
        local not_git_msg
        not_git_msg=$(get_config "messages.not_git_repo")
        print_error "$not_git_msg"
        
        local reinstall_prompt
        reinstall_prompt=$(get_config "prompts.reinstall.message")
        if prompt_yes_no "$reinstall_prompt"; then
            print_status "Please backup your configuration, then run:"
            print_status "  rm -rf $install_dir"
            print_status "  bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)\""
        fi
        return 1
    fi
    
    return 0
}

# Get current Git commit hash
get_current_commit() {
    local install_dir
    install_dir=$(eval echo "$(get_config "application.installation_dir")")
    
    if [ ! -d "$install_dir/.git" ]; then
        return 1
    fi
    
    local current_commit
    current_commit=$(cd "$install_dir" && git rev-parse --short HEAD 2>/dev/null)
    
    if [ -z "$current_commit" ]; then
        return 1
    fi
    
    echo "$current_commit"
    return 0
}

# Get remote commit hash
get_remote_commit() {
    local install_dir
    install_dir=$(eval echo "$(get_config "application.installation_dir")")
    local branch
    branch=$(get_config "update.branch")
    
    if [ ! -d "$install_dir/.git" ]; then
        return 1
    fi
    
    local checking_remote_msg
    checking_remote_msg=$(get_config "messages.checking_remote")
    print_status "$checking_remote_msg"
    
    # Fetch latest from remote
    if ! (cd "$install_dir" && git fetch origin "$branch" 2>/dev/null); then
        local fetch_failed_msg
        fetch_failed_msg=$(get_config "messages.fetch_failed")
        print_error "$fetch_failed_msg"
        return 1
    fi
    
    local remote_commit
    remote_commit=$(cd "$install_dir" && git rev-parse --short "origin/$branch" 2>/dev/null)
    
    if [ -z "$remote_commit" ]; then
        return 1
    fi
    
    echo "$remote_commit"
    return 0
}

# Perform oh-my-bash update via git pull
perform_oh_my_bash_update() {
    local install_dir
    install_dir=$(eval echo "$(get_config "application.installation_dir")")
    local branch
    branch=$(get_config "update.branch")
    
    local pulling_msg
    pulling_msg=$(get_config "messages.pulling_updates")
    print_status "$pulling_msg"
    
    # Perform git pull
    if ! (cd "$install_dir" && git pull origin "$branch"); then
        local pull_failed_msg
        pull_failed_msg=$(get_config "messages.pull_failed")
        print_error "$pull_failed_msg"
        return 1
    fi
    
    local success_msg
    success_msg=$(get_config "messages.update_success")
    print_success "$success_msg"
    
    # Show new commit
    local new_commit
    new_commit=$(get_current_commit)
    if [ -n "$new_commit" ]; then
        local commit_msg
        commit_msg=$(get_config "messages.commit_info")
        commit_msg="${commit_msg/\{commit\}/$new_commit}"
        print_status "$commit_msg"
    fi
    
    return 0
}

# Custom version check for oh-my-bash (Git commit-based)
oh_my_bash_version_check() {
    local checking_msg
    checking_msg=$(get_config "messages.checking_updates")
    print_status "$checking_msg"
    
    # Check if installed
    if ! check_oh_my_bash_installed; then
        return 1
    fi
    
    # Get current commit
    local current_commit
    current_commit=$(get_current_commit)
    
    if [ -z "$current_commit" ]; then
        local failed_msg
        failed_msg=$(get_config "messages.failed_get_version")
        print_error "$failed_msg"
        return 1
    fi
    
    # Get remote commit
    local remote_commit
    remote_commit=$(get_remote_commit)
    
    if [ -z "$remote_commit" ]; then
        print_error "Failed to fetch remote commit information"
        return 1
    fi
    
    # Export for use by other functions
    export CURRENT_VERSION="$current_commit"
    export LATEST_VERSION="$remote_commit"
    export APP_DISPLAY_NAME="Oh-My-Bash"
    
    # Show commit information
    local commit_msg
    commit_msg=$(get_config "messages.commit_info")
    commit_msg="${commit_msg/\{commit\}/$current_commit}"
    print_status "$commit_msg"
    
    local remote_msg
    remote_msg=$(get_config "messages.remote_commit_info")
    remote_msg="${remote_msg/\{commit\}/$remote_commit}"
    print_status "$remote_msg"
    
    # Compare commits
    # 0 = equal (up-to-date), 2 = update available
    if [ "$current_commit" = "$remote_commit" ]; then
        export VERSION_STATUS=0
        local already_updated_msg
        already_updated_msg=$(get_config "messages.already_updated")
        print_success "$already_updated_msg"
    else
        export VERSION_STATUS=2
        print_status "oh-my-bash update available: $current_commit → $remote_commit"
    fi
    
    return 0
}

# Update oh-my-bash framework
# Uses Method 3: Custom Update Logic (see upgrade_script_pattern_documentation.md)
update_oh_my_bash() {
    # Perform custom version check (Git commit-based)
    if ! oh_my_bash_version_check; then
        ask_continue
        return 0
    fi
    
    # Skip if already up-to-date
    if [ "$VERSION_STATUS" -eq 0 ]; then
        ask_continue
        return 0
    fi
    
    # Handle update workflow with custom perform_oh_my_bash_update logic
    local updating_msg
    updating_msg=$(get_config "messages.updating")
    local app_name
    app_name=$(get_config "application.name")
    local app_display
    app_display=$(get_config "application.display_name")
    
    if ! handle_update_prompt "$APP_DISPLAY_NAME" "$VERSION_STATUS" \
        "print_status '$updating_msg' && \
         perform_oh_my_bash_update && \
         show_installation_info '$app_name' '$app_display'"; then
        ask_continue
        return 1
    fi
}

update_oh_my_bash
