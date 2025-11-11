#!/bin/bash
#
# apt_manager.sh - APT Package Manager Operations
#
# Handles all APT/DPKG package operations including updates, upgrades,
# dependency management, and cleanup operations.
#
# Version: 0.4.0
# Author: mpb
# Repository: https://github.com/mpbarbosa/mpb_scripts
# License: MIT
#

# Source core library if not already sourced
if [ -z "$BLUE" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/core_lib.sh"
fi

#=============================================================================
# APT PACKAGE MANAGER FUNCTIONS
#=============================================================================

update_package_list() {
    print_operation_header "🔄 Updating package list from repositories..."
    print_status "⏳ This may take a few moments depending on network speed and repository count"
    
    local apt_output
    apt_output=$(sudo apt-get update 2>&1)
    local exit_code=$?
    
    echo "$apt_output" | while IFS= read -r line; do
        case "$line" in
            Hit:*) echo "💻 $line" ;;
            Get:*) echo "💻 $line" ;;
            *"Reading package lists"*) echo "📖 $line" ;;
            *"Building dependency tree"*) echo "🌳 $line" ;;
            *"Reading state information"*) echo "🔍 $line" ;;
            *"ERROR"*|*"Error"*|*"error"*) echo "❌ $line" ;;
            *"WARNING"*|*"Warning"*|*"warning"*) echo "⚠️  $line" ;;
            *"W:"*) echo "⚠️  $line" ;;
            *"E:"*) echo "❌ $line" ;;
            "") echo "" ;;
            *) echo "💬 $line" ;;
        esac
    done
    
    if [ $exit_code -eq 0 ]; then
        print_success "📋 Package list updated successfully - local cache now current"
    else
        print_error "🌐 Failed to update package list"
        print_error "🔍 Common causes: network connectivity, repository issues, GPG key problems"
        print_error "🛠️  Check network connection and repository configuration"
        exit 1
    fi
    
    ask_continue
}

check_unattended_upgrades() {
    print_operation_header "🔒 Checking unattended upgrades configuration..."
    
    if [ ! -f "/etc/apt/apt.conf.d/20auto-upgrades" ]; then
        print_warning "Unattended upgrades configuration file not found"
        print_status "File: /etc/apt/apt.conf.d/20auto-upgrades"
        print_status "Unattended upgrades may not be configured on this system"
        return 0
    fi
    
    local unattended_config
    unattended_config=$(grep "APT::Periodic::Unattended-Upgrade" /etc/apt/apt.conf.d/20auto-upgrades 2>/dev/null | grep -o '"[0-9]*"' | tr -d '"')
    
    if [ -z "$unattended_config" ]; then
        print_warning "Unattended-Upgrade setting not found in configuration"
        print_status "The system may not have unattended upgrades properly configured"
        return 0
    fi
    
    print_status "Current unattended upgrades setting: $unattended_config"
    
    if [ "$unattended_config" = "1" ]; then
        print_success "✅ Unattended upgrades are ENABLED"
        print_status "🔒 Your system will automatically install security updates"
        print_status "📋 Configuration: APT::Periodic::Unattended-Upgrade \"1\""
    else
        print_warning "⚠️  Unattended upgrades are DISABLED"
        print_status "🔓 Your system will NOT automatically install security updates"
        print_status "📋 Current configuration: APT::Periodic::Unattended-Upgrade \"$unattended_config\""
        print_status ""
        
        if [[ "${QUIET_MODE:-false}" == "false" ]]; then
            print_status "💡 Enabling unattended upgrades is recommended for security"
            print_status "   • Automatic installation of security updates"
            print_status "   • Reduces exposure to known vulnerabilities"
            print_status "   • Only installs updates from security repositories"
            print_status ""
            
            echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Would you like to enable unattended upgrades? (y/N): "
            read -r enable_unattended
            
            case "$enable_unattended" in
                [Yy]|[Yy][Ee][Ss])
                    print_status "🔧 Enabling unattended upgrades..."
                    
                    if sudo cp /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades.backup.$(date +%Y%m%d_%H%M%S); then
                        print_status "📋 Configuration backup created"
                    fi
                    
                    if sudo sed -i 's/APT::Periodic::Unattended-Upgrade "0"/APT::Periodic::Unattended-Upgrade "1"/' /etc/apt/apt.conf.d/20auto-upgrades 2>/dev/null; then
                        local new_config
                        new_config=$(grep "APT::Periodic::Unattended-Upgrade" /etc/apt/apt.conf.d/20auto-upgrades 2>/dev/null | grep -o '"[0-9]*"' | tr -d '"')
                        
                        if [ "$new_config" = "1" ]; then
                            print_success "✅ Unattended upgrades successfully enabled!"
                            print_status "🔒 Your system will now automatically install security updates"
                            print_status "📅 Updates typically check daily and install during low-usage hours"
                            print_status "📝 You can check logs in: /var/log/unattended-upgrades/"
                        else
                            print_error "❌ Failed to verify unattended upgrades configuration change"
                        fi
                    else
                        print_error "❌ Failed to enable unattended upgrades"
                        print_status "You may need to manually edit: /etc/apt/apt.conf.d/20auto-upgrades"
                    fi
                    ;;
                *)
                    print_status "⏭️  Unattended upgrades remain disabled"
                    print_status "💡 You can enable them later by running: sudo dpkg-reconfigure unattended-upgrades"
                    ;;
            esac
        else
            print_status "💡 Consider enabling unattended upgrades for automatic security updates"
            print_status "   Command: sudo dpkg-reconfigure unattended-upgrades"
        fi
    fi
    
    ask_continue
}

check_updates_available() {
    print_operation_header "🔍 Checking for available package updates..."
    
    if [ ! -x "/usr/lib/update-notifier/apt-check" ]; then
        print_warning "apt-check utility not found at /usr/lib/update-notifier/apt-check"
        print_status "Proceeding with upgrade check using alternative method..."
        
        local upgradable_count=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")
        if [ "$upgradable_count" -gt 0 ]; then
            print_status "Found $upgradable_count packages available for upgrade (via apt list)"
            return 0
        else
            print_success "No packages available for upgrade (via apt list)"
            return 1
        fi
    fi
    
    local check_output
    check_output=$(/usr/lib/update-notifier/apt-check 2>&1)
    local check_exit_code=$?
    
    if [ $check_exit_code -ne 0 ]; then
        print_warning "apt-check returned error code $check_exit_code"
        print_status "Proceeding with upgrade operation anyway..."
        return 0
    fi
    
    local total_updates=$(echo "$check_output" | cut -d';' -f1)
    local security_updates=$(echo "$check_output" | cut -d';' -f2)
    
    if ! [[ "$total_updates" =~ ^[0-9]+$ ]] || ! [[ "$security_updates" =~ ^[0-9]+$ ]]; then
        print_warning "Unable to parse apt-check output: '$check_output'"
        print_status "Proceeding with upgrade operation anyway..."
        return 0
    fi
    
    if [ "$total_updates" -eq 0 ]; then
        print_success "✅ No package updates available - system is up to date"
        return 1
    else
        print_status "📊 Update summary:"
        print_status "  📦 Total updates available: $total_updates"
        if [ "$security_updates" -gt 0 ]; then
            print_status "  🔒 Security updates available: $security_updates"
            print_warning "Security updates should be installed promptly"
        else
            print_status "  🔒 Security updates available: 0"
        fi
        print_status "Proceeding with package upgrade operation..."
        return 0
    fi
}

upgrade_packages() {
    if ! check_updates_available; then
        print_success "🎯 Skipping upgrade operation - no updates available"
        ask_continue
        return 0
    fi
    
    print_operation_header "🔄 Upgrading installed packages to latest versions..."
    
    local upgrade_output
    upgrade_output=$(sudo apt-get upgrade -y 2>&1)
    local upgrade_exit_code=$?
    
    local previous_line=""
    echo "$upgrade_output" | while IFS= read -r line; do
        if [ "$line" = "$previous_line" ]; then
            continue
        fi
        previous_line="$line"
        
        case "$line" in
            *"Reading package lists"*) echo "📖 $line" ;;
            *"Building dependency tree"*) echo "🌳 $line" ;;
            *"Reading state information"*) echo "🔍 $line" ;;
            *"Calculating upgrade"*) echo "🧮 $line" ;;
            *"The following packages will be upgraded:"*) echo "🔄 $line" ;;
            *"The following packages have been kept back:"*) echo "⏸️  $line" ;;
            *"The following NEW packages will be installed:"*) echo "🆕 $line" ;;
            *"The following packages will be REMOVED:"*) echo "🗑️  $line" ;;
            *"upgraded,"*|*"newly installed,"*|*"to remove"*) echo "📊 $line" ;;
            *"Need to get"*) echo "📥 $line" ;;
            *"After this operation"*) echo "💾 $line" ;;
            *"Get:"*) echo "💻 $line" ;;
            *"Fetched"*) echo "✅ $line" ;;
            *"Unpacking"*) echo "📦 $line" ;;
            *"Setting up"*) echo "⚙️  $line" ;;
            *"Processing triggers"*) echo "🔄 $line" ;;
            *"ERROR"*|*"Error"*|*"error"*) echo "❌ $line" ;;
            *"WARNING"*|*"Warning"*|*"warning"*) echo "⚠️  $line" ;;
            *"W:"*) echo "⚠️  $line" ;;
            *"E:"*) echo "❌ $line" ;;
            "") echo "" ;;
            *) echo "💬 $line" ;;
        esac
    done
    
    if [ $upgrade_exit_code -eq 0 ]; then
        if echo "$upgrade_output" | grep -q "kept back"; then
            local kept_back_packages=$(echo "$upgrade_output" | grep -A 1 "kept back:" | tail -1 | xargs)
            local kept_back_count=$(echo "$kept_back_packages" | wc -w)
            
            print_warning "$kept_back_count packages were kept back: $kept_back_packages"
            print_status "📝 Kept back packages usually need 'dist-upgrade' or have dependency conflicts"
            print_status "💡 This happens when upgrading would require installing/removing dependencies"
            
            if [ "$QUIET_MODE" = false ]; then
                echo
                print_status "💡 Kept back packages can often be resolved with targeted installation"
                echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Do you want to try upgrading kept back packages with individual install? (Y/n): "
                read -r response
                case "$response" in
                    [nN]|[nN][oO])
                        print_status "Skipping manual upgrade of kept back packages"
                        print_status "You can manually upgrade them later with: apt install <package-name>"
                        ;;
                    *)
                        print_operation_header "🔧 Attempting to upgrade kept back packages individually..."
                        print_status "🔧 Using 'apt-get install' instead of 'upgrade' to resolve dependencies"
                        
                        local dist_upgrade_output
                        dist_upgrade_output=$(sudo apt-get install $kept_back_packages -y 2>&1)
                        local dist_upgrade_exit_code=$?
                        
                        echo "$dist_upgrade_output"
                        
                        if [ $dist_upgrade_exit_code -eq 0 ]; then
                            print_success "Successfully upgraded kept back packages"
                            print_success "All packages are now up to date"
                        else
                            print_warning "Some kept back packages could not be upgraded"
                            print_status "This indicates complex dependency conflicts that require manual resolution"
                            print_status ""
                            print_status "Common reasons for upgrade failures:"
                            print_status "  - Complex dependency conflicts between packages"
                            print_status "  - Packages requiring manual configuration changes"
                            print_status "  - Packages pinned by system policy or held back intentionally"
                            print_status "  - Repository inconsistencies or missing dependencies"
                            print_status ""
                            print_status "Manual resolution options:"
                            print_status "Consider running 'apt-get install <package>' manually for each package"
                            print_status "Or try 'apt-get dist-upgrade' to allow dependency changes"
                            
                            print_status ""
                            print_status "Analyzing individual kept back packages:"
                            for package in $kept_back_packages; do
                                print_status "Checking $package..."
                                local policy_output=$(apt-cache policy "$package" 2>/dev/null)
                                if echo "$policy_output" | grep -q "Installed:"; then
                                    local installed_version=$(echo "$policy_output" | grep "Installed:" | awk '{print $2}')
                                    local candidate_version=$(echo "$policy_output" | grep "Candidate:" | awk '{print $2}')
                                    print_status "  $package: $installed_version → $candidate_version (upgrade available)"
                                fi
                            done
                        fi
                        ;;
                esac
            else
                print_status "In quiet mode - skipping interactive upgrade of kept back packages"
                print_status "Automated systems should handle kept back packages in post-processing"
                print_status "Manual intervention options:"
                print_status "  - Run 'apt-get dist-upgrade' to allow dependency changes"
                print_status "  - Install packages individually: apt install <package-name>"
                
                print_status ""
                print_status "Kept back package analysis (quiet mode):"
                for package in $kept_back_packages; do
                    local policy_output=$(apt-cache policy "$package" 2>/dev/null)
                    if echo "$policy_output" | grep -q "Installed:"; then
                        local installed_version=$(echo "$policy_output" | grep "Installed:" | awk '{print $2}')
                        local candidate_version=$(echo "$policy_output" | grep "Candidate:" | awk '{print $2}')
                        print_status "  $package: $installed_version → $candidate_version"
                    fi
                done
            fi
        fi
        
        if echo "$upgrade_output" | grep -q "0 upgraded, 0 newly installed"; then
            if echo "$upgrade_output" | grep -q "kept back"; then
                print_warning "🔄 No packages were upgraded (some packages were kept back)"
                print_status "⚠️  System is partially up to date - manual intervention needed for kept back packages"
            else
                print_success "🎯 All packages are already up to date"
                print_success "🛡️  System is current with latest available package versions"
            fi
        else
            local upgraded_count=$(echo "$upgrade_output" | grep -o '[0-9]\+ upgraded' | grep -o '[0-9]\+' | head -1)
            local installed_count=$(echo "$upgrade_output" | grep -o '[0-9]\+ newly installed' | grep -o '[0-9]\+' | head -1)
            
            if [ -n "$upgraded_count" ] && [ "$upgraded_count" -gt 0 ]; then
                print_success "Successfully upgraded $upgraded_count packages to newer versions"
            fi
            if [ -n "$installed_count" ] && [ "$installed_count" -gt 0 ]; then
                print_success "Successfully installed $installed_count new dependency packages"
            fi
            
            print_success "Package upgrade operation completed successfully"
        fi
    else
        print_error "Failed to upgrade packages - apt-get upgrade returned error code $upgrade_exit_code"
        print_error ""
        print_error "Common causes and solutions:"
        print_error "  - Network connectivity issues:"
        print_error "    * Check internet connection and DNS resolution"
        print_error "    * Verify repository URLs are accessible"
        print_error "  - Repository problems:"
        print_error "    * Run 'apt-get update' to refresh repository information"
        print_error "    * Check /etc/apt/sources.list for invalid entries"
        print_error "  - Dependency conflicts:"
        print_error "    * Try 'apt-get -f install' to fix broken dependencies"
        print_error "    * Consider 'apt-get dist-upgrade' for complex dependency changes"
        print_error "  - Insufficient disk space:"
        print_error "    * Check available space with 'df -h'"
        print_error "    * Clean package cache with 'apt-get clean'"
        print_error "  - Permission issues:"
        print_error "    * Ensure script is running with sufficient privileges"
        print_error ""
        print_error "Review the detailed output above for specific error messages"
        print_error "Manual intervention may be required to resolve the issue"
        exit 1
    fi
    
    ask_continue
}

full_upgrade() {
    if ! check_updates_available; then
        print_success "🎯 Skipping dist-upgrade operation - no updates available"
        ask_continue
        return 0
    fi

    print_operation_header "⚡ Performing comprehensive system upgrade (dist-upgrade)..."
    print_status "WARNING: This operation may install new packages or remove existing ones"
    print_status "This is more aggressive than regular upgrade and can change system behavior"
    print_status ""
    print_operation_header "🚀 Starting dist-upgrade operation..."
    
    local dist_upgrade_output
    dist_upgrade_output=$(sudo apt-get dist-upgrade -y 2>&1)
    local exit_code=$?
    
    local previous_line=""
    echo "$dist_upgrade_output" | while IFS= read -r line; do
        if [ "$line" = "$previous_line" ]; then
            continue
        fi
        previous_line="$line"
        
        case "$line" in
            *"Reading package lists"*) echo "📖 $line" ;;
            *"Building dependency tree"*) echo "🌳 $line" ;;
            *"Reading state information"*) echo "🔍 $line" ;;
            *"Calculating upgrade"*) echo "🧮 $line" ;;
            *"The following packages will be upgraded:"*) echo "🔄 $line" ;;
            *"The following NEW packages will be installed:"*) echo "�� $line" ;;
            *"The following packages will be REMOVED:"*) echo "🗑️  $line" ;;
            *"upgraded,"*|*"newly installed,"*|*"to remove"*) echo "📊 $line" ;;
            *"Need to get"*) echo "📥 $line" ;;
            *"After this operation"*) echo "💾 $line" ;;
            *"Get:"*) echo "💻 $line" ;;
            *"Fetched"*) echo "✅ $line" ;;
            *"Unpacking"*) echo "📦 $line" ;;
            *"Setting up"*) echo "⚙️  $line" ;;
            *"Processing triggers"*) echo "🔄 $line" ;;
            *"ERROR"*|*"Error"*|*"error"*) echo "❌ $line" ;;
            *"WARNING"*|*"Warning"*|*"warning"*) echo "⚠️  $line" ;;
            *"W:"*) echo "⚠️  $line" ;;
            *"E:"*) echo "❌ $line" ;;
            "") echo "" ;;
            *) echo "💬 $line" ;;
        esac
    done
    
    if [ $exit_code -eq 0 ]; then
        print_success "Full system upgrade completed successfully"
        print_success "System has been upgraded with all available dependency changes"
        print_status "Some services may require restart to use new versions"
    else
        print_error "Failed to perform full system upgrade"
        print_error "This could indicate serious system issues or conflicts"
        print_error "Manual intervention may be required"
        print_error "Consider running 'apt-get -f install' to fix broken dependencies"
        exit 1
    fi
    
    ask_continue
}

cleanup() {
    print_operation_header "🧹 Performing comprehensive system cleanup..."
    print_status "🗑️  This will remove unnecessary packages and clean cached files"
    
    print_operation_header "📦 Removing orphaned packages (autoremove)..."
    print_status "🔍 Identifying packages that were automatically installed but are no longer needed"
    
    local autoremove_output
    autoremove_output=$(sudo apt-get autoremove -y 2>&1)
    local autoremove_exit_code=$?
    
    echo "$autoremove_output" | while IFS= read -r line; do
        case "$line" in
            *"Reading package lists"*) echo "📖 $line" ;;
            *"Building dependency tree"*) echo "🌳 $line" ;;
            *"Reading state information"*) echo "🔍 $line" ;;
            *"The following packages will be REMOVED:"*) echo "🗑️  $line" ;;
            *"upgraded,"*|*"newly installed,"*|*"to remove"*) echo "�� $line" ;;
            *"After this operation"*) echo "💾 $line" ;;
            *"Removing"*) echo "🗂️  $line" ;;
            *"Processing triggers"*) echo "🔄 $line" ;;
            *"ERROR"*|*"Error"*|*"error"*) echo "❌ $line" ;;
            *"WARNING"*|*"Warning"*|*"warning"*) echo "⚠️  $line" ;;
            *"W:"*) echo "⚠️  $line" ;;
            *"E:"*) echo "❌ $line" ;;
            "") echo "" ;;
            *) echo "💬 $line" ;;
        esac
    done
    
    if [ $autoremove_exit_code -eq 0 ]; then
        print_success "🗂️  Successfully removed orphaned packages"
    else
        print_warning "⚠️  Some orphaned packages could not be removed"
    fi
    
    print_operation_header "💾 Cleaning outdated package cache files (autoclean)..."
    print_status "🗄️  Removing cached packages that are no longer available in repositories"
    
    local autoclean_output
    autoclean_output=$(sudo apt-get autoclean 2>&1)
    local autoclean_exit_code=$?
    
    echo "$autoclean_output" | while IFS= read -r line; do
        case "$line" in
            *"Reading package lists"*) echo "📖 $line" ;;
            *"Del "*) echo "🧽 $line" ;;
            *"ERROR"*|*"Error"*|*"error"*) echo "❌ $line" ;;
            *"WARNING"*|*"Warning"*|*"warning"*) echo "⚠️  $line" ;;
            *"W:"*) echo "⚠️  $line" ;;
            *"E:"*) echo "❌ $line" ;;
            "") echo "" ;;
            *) echo "💬 $line" ;;
        esac
    done
    
    if [ $autoclean_exit_code -eq 0 ]; then
        print_success "🧽 Successfully cleaned outdated package cache"
    else
        print_warning "⚠️  Package cache cleaning encountered issues"
    fi
    
    print_success "🎉 System cleanup completed successfully"
    print_status "💽 Disk space has been reclaimed and system maintenance performed"
    
    ask_continue
}

check_broken_packages() {
    print_operation_header "🔍 Performing comprehensive package integrity check..."
    
    local audit_output=$(dpkg --audit 2>/dev/null)
    
    if echo "$audit_output" | grep -q .; then
        print_warning "Found broken or partially configured packages"
        print_status "Package integrity issues detected - attempting automatic repair"
        
        print_operation_header "🔧 Step 1: Attempting to fix broken dependencies..."
        if sudo apt-get install -f -y >/dev/null 2>&1; then
            print_success "Successfully fixed broken dependencies"
        else
            print_warning "Some dependency issues could not be automatically resolved"
        fi
        
        print_operation_header "⚙️ Step 2: Configuring partially installed packages..."
        if dpkg --configure -a >/dev/null 2>&1; then
            print_success "Successfully configured all pending packages"
        else
            print_warning "Some packages could not be properly configured"
            print_status "Manual intervention may be required for complex configuration issues"
        fi
        
        local post_repair_audit=$(dpkg --audit 2>/dev/null)
        if echo "$post_repair_audit" | grep -q .; then
            print_warning "Some package issues remain after automatic repair"
            print_status "Consider manual package management for remaining issues"
        else
            print_success "All package integrity issues have been resolved"
        fi
    else
        print_success "No broken packages found - system package integrity is good"
    fi
    
    ask_continue
}
