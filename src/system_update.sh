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
# - Multi-package-manager support (apt, snap, cargo, pip, npm)
# - Interactive and quiet modes
# - Intelligent handling of kept back packages
# - Comprehensive package listing and statistics
# - Calibre update checking
# - Detailed error analysis and recovery suggestions
# - Progress tracking and user confirmation options
# - Hierarchical output formatting with visual organization
# - Command output emoji marking for enhanced readability
#
# Output Structure:
# The script uses a three-tier hierarchical structure for output organization:
#   1. Package Manager Headers (white text on blue background):
#      "APT PACKAGE MANAGER", "SNAP PACKAGE MANAGER", etc.
#   2. Section Headers (bold blue text):
#      "Updating package list from repositories...", "Upgrading installed packages...", etc.
#   3. Sub-step Headers (regular blue text):
#      "Step 1: Attempting to fix broken dependencies...", "Updating rustup toolchain...", etc.
#
# Usage:
#   ./system_update.sh [OPTIONS]
#
# Dependencies:
#   - sudo access for system package operations (prompted when needed)
#   - Various package managers (detected automatically)
#   - Network connectivity for package updates and version checking
#
# Author: mpb
# Repository: https://github.com/mpbarbosa/mpb_scripts
# License: MIT
#

#=============================================================================
# SCRIPT VERSION AND METADATA
#=============================================================================
readonly SCRIPT_VERSION="0.2.0"
readonly SCRIPT_NAME="system_update.sh"
readonly SCRIPT_DESCRIPTION="Comprehensive Package Management and System Update Script"
readonly SCRIPT_AUTHOR="mpb"
readonly SCRIPT_REPOSITORY="https://github.com/mpbarbosa/mpb_scripts"

#=============================================================================
# COLOR DEFINITIONS AND OUTPUT FORMATTING
#=============================================================================
# ANSI color codes for consistent, colored terminal output
# These colors improve readability and help users quickly identify
# different types of messages using optimal color theory principles

RED='\033[0;31m'      # Error messages and critical issues
GREEN='\033[0;32m'    # Success messages and positive outcomes  
YELLOW='\033[1;33m'   # Warning messages and cautionary information
BLUE='\033[0;34m'     # Section headers and operation titles
CYAN='\033[0;36m'     # Informational messages and status updates
MAGENTA='\033[0;35m'  # User prompts and interactive elements
WHITE='\033[0;37m'    # White text for enhanced visibility and readability
NC='\033[0m'          # No Color - resets terminal color to default


[ -f ".bashrc" ] && source ".bashrc"

#=============================================================================
# UTILITY FUNCTIONS FOR FORMATTED OUTPUT
#=============================================================================
# These functions provide consistent, colored output formatting throughout
# the script. Each function prefixes messages with appropriate status indicators
# and uses corresponding colors to improve user experience and readability.

# Print main operation headers (Tier 2 - Bold blue)
# Used for: Major operations, primary process steps
print_operation_header() {
    echo -e "\n${BLUE}\033[1m$1\033[0m"
}

# Print informational messages in cyan with information emoji (Tier 3 - Sub-step Headers)
# Used for: Status updates, progress information, general notifications
print_status() {
    echo -e "${CYAN}ℹ️${NC} $1"
}

# Print success messages in green with checkmark emoji (streamlined)
# Used for: Completed operations, successful updates, positive confirmations
print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

# Print warning messages in yellow with [WARNING] prefix and warning emoji
# Used for: Non-critical issues, cautionary information, partial failures
print_warning() {
    echo -e "${YELLOW}⚠️  [WARNING]${NC} $1"
}

# Print error messages in red with [ERROR] prefix and error emoji
# Used for: Critical failures, system errors, operation failures
print_error() {
    echo -e "${RED}❌ [ERROR]${NC} $1"
}

# Print section headers with white text on blue background and relevant emojis
# Used for: Package manager section separators, visual organization
print_section_header() {
    local section_name="$1"
    local emoji=""
    
    # Add appropriate emoji based on section name
    case "$section_name" in
        *"APT"*) emoji="📦" ;;
        *"DPKG"*) emoji="🔧" ;;
        *"SNAP"*) emoji="📱" ;;
        *"RUST"*|*"CARGO"*) emoji="🦀" ;;
        *"PYTHON"*|*"PIP"*) emoji="🐍" ;;
        *"NODE"*|*"NPM"*) emoji="📗" ;;
        *"KITTY"*) emoji="🐱" ;;
        *"CALIBRE"*) emoji="📚" ;;
        *"SYSTEM"*|*"UPGRADE"*) emoji="⚡" ;;
        *"INFORMATION"*|*"SUMMARY"*) emoji="ℹ️" ;;
        *) emoji="🔧" ;;
    esac
    
    local section_with_emoji="$emoji $section_name"
    local line_length=80
    local padding_length=$(( (line_length - ${#section_with_emoji} - 2) / 2 ))
    local padding=$(printf "%*s" "$padding_length" "")
    
    # Section header without extra spacing - caller handles spacing context
    echo -e "\033[44;37m${padding} ${section_with_emoji} ${padding}\033[0m"
}

#=============================================================================
# UTILITY HELPER FUNCTIONS
#=============================================================================
# Helper functions for system operations that may require elevated privileges

# Display script version and metadata information
# Provides comprehensive script identification including version, author, and repository
show_version() {
    echo -e "${BLUE}${SCRIPT_NAME}${NC} - ${SCRIPT_DESCRIPTION}"
    echo -e "${CYAN}Version:${NC} ${SCRIPT_VERSION} (Alpha)"
    echo -e "${CYAN}Author:${NC} ${SCRIPT_AUTHOR}"
    echo -e "${CYAN}Repository:${NC} ${SCRIPT_REPOSITORY}"
    echo -e "${CYAN}License:${NC} MIT"
    echo ""
    echo -e "${YELLOW}Features:${NC}"
    echo "  • Multi-package-manager support (APT, Snap, Rust/Cargo, Python pip, Node.js npm)"
    echo "  • Interactive and quiet modes with hierarchical output formatting"
    echo "  • Intelligent handling of kept back packages and dependency conflicts"
    echo "  • Comprehensive package listing, statistics, and Calibre update checking"
    echo "  • Detailed error analysis, recovery suggestions, and progress tracking"
    echo ""
    echo -e "${GREEN}Package Managers Supported:${NC}"
    echo "  📦 APT/DPKG    🦀 Rust/Cargo    🐍 Python pip"
    echo "  📱 Snap        📗 Node.js npm   📚 Calibre"
}

#=============================================================================
# APT PACKAGE MANAGER FUNCTIONS
#=============================================================================
# APT (Advanced Package Tool) is the primary package manager for Debian-based
# systems including Ubuntu. These functions handle system package updates,
# upgrades, maintenance, and dependency management.

# Update the APT package list from configured repositories
# This operation:
# - Downloads latest package information from all enabled repositories
# - Updates the local package cache with current versions and dependencies
# - Is prerequisite for upgrade operations to ensure current package data
# - May fail due to network issues, repository problems, or key errors
#
# Critical for security: ensures latest security updates are available for installation
update_package_list() {

    print_operation_header "🔄 Updating package list from repositories..."
    print_status "⏳ This may take a few moments depending on network speed and repository count"
    
    # Capture apt-get update output for processing with emoji markers
    local apt_output
    apt_output=$(sudo apt-get update 2>&1)
    local exit_code=$?
    
    # Process and display command output with appropriate Unicode emojis
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
            "") echo "" ;;  # Preserve empty lines
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
    
    # Pause for user interaction if in stop mode
    ask_continue
}

# Check and configure unattended upgrades settings
# This function verifies if automatic security updates are enabled and offers to enable them
# if they're currently disabled. Unattended upgrades help keep the system secure by
# automatically installing security updates without user intervention.
check_unattended_upgrades() {
    print_operation_header "🔒 Checking unattended upgrades configuration..."
    
    # Check if the configuration file exists
    if [ ! -f "/etc/apt/apt.conf.d/20auto-upgrades" ]; then
        print_warning "Unattended upgrades configuration file not found"
        print_status "File: /etc/apt/apt.conf.d/20auto-upgrades"
        print_status "Unattended upgrades may not be configured on this system"
        return 0
    fi
    
    # Check the current configuration using the suggested grep command
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
        
        # Ask user if they want to enable unattended upgrades (only in interactive mode)
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
                    
                    # Create backup of current configuration
                    if sudo cp /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades.backup.$(date +%Y%m%d_%H%M%S); then
                        print_status "📋 Configuration backup created"
                    fi
                    
                    # Enable unattended upgrades by setting the value to "1"
                    if sudo sed -i 's/APT::Periodic::Unattended-Upgrade "0"/APT::Periodic::Unattended-Upgrade "1"/' /etc/apt/apt.conf.d/20auto-upgrades 2>/dev/null; then
                        # Verify the change was successful
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

# Check if there are packages available for upgrade using apt-check
# This function uses /usr/lib/update-notifier/apt-check to determine if updates are available
# before attempting the upgrade operation, avoiding unnecessary apt-get upgrade calls
#
# Returns:
#   0 - Updates are available and should proceed with upgrade
#   1 - No updates available, skip upgrade operation
check_updates_available() {
    print_operation_header "🔍 Checking for available package updates..."
    
    # Verify apt-check utility exists
    if [ ! -x "/usr/lib/update-notifier/apt-check" ]; then
        print_warning "apt-check utility not found at /usr/lib/update-notifier/apt-check"
        print_status "Proceeding with upgrade check using alternative method..."
        
        # Fallback: Use apt list --upgradable as alternative check
        local upgradable_count=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")
        if [ "$upgradable_count" -gt 0 ]; then
            print_status "Found $upgradable_count packages available for upgrade (via apt list)"
            return 0
        else
            print_success "No packages available for upgrade (via apt list)"
            return 1
        fi
    fi
    
    # Use apt-check to get update count
    # apt-check outputs: "updates;security_updates" to stderr
    local check_output
    check_output=$(/usr/lib/update-notifier/apt-check 2>&1)
    local check_exit_code=$?
    
    if [ $check_exit_code -ne 0 ]; then
        print_warning "apt-check returned error code $check_exit_code"
        print_status "Proceeding with upgrade operation anyway..."
        return 0
    fi
    
    # Parse the output: format is "updates;security_updates"
    local total_updates=$(echo "$check_output" | cut -d';' -f1)
    local security_updates=$(echo "$check_output" | cut -d';' -f2)
    
    # Validate that we got numeric values
    if ! [[ "$total_updates" =~ ^[0-9]+$ ]] || ! [[ "$security_updates" =~ ^[0-9]+$ ]]; then
        print_warning "Unable to parse apt-check output: '$check_output'"
        print_status "Proceeding with upgrade operation anyway..."
        return 0
    fi
    
    # Report the findings
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

# Upgrade all installed packages to their latest available versions
# This is the core function that handles package upgrades with intelligent
# analysis of upgrade results, including special handling for "kept back" packages
# which require additional intervention due to dependency conflicts or policy changes
#
# Hierarchical Classification: Complex Tier 2 Primary Function with Extensive Tier 3 Sub-operations
# - Uses Section Headers (Tier 2) for major operations with bold blue formatting
# - Extensive use of Sub-step Headers (Tier 3) via print_status(), print_success(), print_warning(), print_error()
# - Demonstrates advanced hierarchical structure with complex branching logic and comprehensive status reporting
# - Maintains visual hierarchy through success/failure paths and interactive elements
upgrade_packages() {
    # First check if there are any updates available before attempting upgrade
    if ! check_updates_available; then
        print_success "🎯 Skipping upgrade operation - no updates available"
        ask_continue
        return 0
    fi
    
    print_operation_header "🔄 Upgrading installed packages to latest versions..."
    
    # Capture both stdout and stderr from apt-get upgrade for comprehensive analysis
    # We need to analyze the output to detect special conditions like kept back packages
    local upgrade_output
    upgrade_output=$(sudo apt-get upgrade -y 2>&1)
    local upgrade_exit_code=$?
    
    # Process and display command output with appropriate Unicode emojis
    # Suppress consecutive duplicate lines to reduce redundancy
    local previous_line=""
    echo "$upgrade_output" | while IFS= read -r line; do
        # Skip consecutive duplicate lines to reduce redundant output
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
            "") echo "" ;;  # Preserve empty lines
            *) echo "💬 $line" ;;
        esac
    done
    
    # Analyze upgrade results and handle special cases
    if [ $upgrade_exit_code -eq 0 ]; then
        # SUCCESS CASE: apt-get upgrade completed without errors
        # However, we need to check for "kept back" packages which indicate
        # packages that couldn't be upgraded due to dependency changes
        
        if echo "$upgrade_output" | grep -q "kept back"; then
            # KEPT BACK PACKAGES DETECTED
            # These packages require manual intervention or dist-upgrade
            # Extract the list of kept back packages from the upgrade output
            local kept_back_packages=$(echo "$upgrade_output" | grep -A 1 "kept back:" | tail -1 | xargs)
            local kept_back_count=$(echo "$kept_back_packages" | wc -w)
            
            print_warning "$kept_back_count packages were kept back: $kept_back_packages"
            print_status "📝 Kept back packages usually need 'dist-upgrade' or have dependency conflicts"
            print_status "💡 This happens when upgrading would require installing/removing dependencies"
            
            # INTERACTIVE RESOLUTION OF KEPT BACK PACKAGES
            # Only prompt for user intervention if not in quiet mode
            # This allows automated scripts to run without hanging on prompts
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
                        
                        # Try to install the kept back packages individually
                        # This often resolves dependency issues that prevent normal upgrades
                        local dist_upgrade_output
                        dist_upgrade_output=$(sudo apt-get install "$kept_back_packages" -y 2>&1)
                        local dist_upgrade_exit_code=$?
                        
                        # Show the detailed output of the install attempt
                        echo "$dist_upgrade_output"
                        
                        # Analyze the results of the individual package installation attempt
                        if [ $dist_upgrade_exit_code -eq 0 ]; then
                            print_success "Successfully upgraded kept back packages"
                            print_success "All packages are now up to date"
                        else
                            # COMPLEX DEPENDENCY ISSUES DETECTED
                            # Individual installation failed, indicating deeper problems
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
                            
                            # DETAILED PACKAGE ANALYSIS
                            # Provide specific information about each problematic package
                            print_status ""
                            print_status "Analyzing individual kept back packages:"
                            for package in $kept_back_packages; do
                                print_status "Checking $package..."
                                local policy_output=$(apt-cache policy "$package" 2>/dev/null)
                                if echo "$policy_output" | grep -q "Installed:"; then
                                    # Extract version information for detailed reporting
                                    local installed_version=$(echo "$policy_output" | grep "Installed:" | awk '{print $2}')
                                    local candidate_version=$(echo "$policy_output" | grep "Candidate:" | awk '{print $2}')
                                    print_status "  $package: $installed_version → $candidate_version (upgrade available)"
                                fi
                            done
                        fi
                        ;;
                esac
            else
                # QUIET MODE HANDLING
                # In automated environments, don't prompt for user input
                # Provide information but skip interactive resolution
                print_status "In quiet mode - skipping interactive upgrade of kept back packages"
                print_status "Automated systems should handle kept back packages in post-processing"
                print_status "Manual intervention options:"
                print_status "  - Run 'apt-get dist-upgrade' to allow dependency changes"
                print_status "  - Install packages individually: apt install <package-name>"
                
                # QUIET MODE ANALYSIS
                # Still provide detailed analysis for logging/monitoring purposes
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
        
        # UPGRADE RESULTS ANALYSIS
        # Parse the upgrade output to provide detailed feedback on what was accomplished
        # This helps users understand the impact of the upgrade operation
        
        if echo "$upgrade_output" | grep -q "0 upgraded, 0 newly installed"; then
            # NO PACKAGES WERE MODIFIED
            if echo "$upgrade_output" | grep -q "kept back"; then
                print_warning "🔄 No packages were upgraded (some packages were kept back)"
                print_status "⚠️  System is partially up to date - manual intervention needed for kept back packages"
            else
                print_success "🎯 All packages are already up to date"
                print_success "🛡️  System is current with latest available package versions"
            fi
        else
            # PACKAGES WERE MODIFIED - Extract and report statistics
            local upgraded_count=$(echo "$upgrade_output" | grep -o '[0-9]\+ upgraded' | grep -o '[0-9]\+' | head -1)
            local installed_count=$(echo "$upgrade_output" | grep -o '[0-9]\+ newly installed' | grep -o '[0-9]\+' | head -1)
            
            # Report upgrade statistics with detailed feedback
            if [ -n "$upgraded_count" ] && [ "$upgraded_count" -gt 0 ]; then
                print_success "Successfully upgraded $upgraded_count packages to newer versions"
            fi
            if [ -n "$installed_count" ] && [ "$installed_count" -gt 0 ]; then
                print_success "Successfully installed $installed_count new dependency packages"
            fi
            
            print_success "Package upgrade operation completed successfully"
        fi
    else
        # UPGRADE OPERATION FAILED
        # apt-get upgrade returned a non-zero exit code indicating failure
        # Provide comprehensive troubleshooting guidance
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
    
    # Allow user to pause and review results before continuing
    ask_continue
}

# Perform a comprehensive system upgrade including dependency changes
# This function executes 'apt-get dist-upgrade' which is more aggressive than 'upgrade'
# and can install new packages or remove existing ones to resolve dependencies
#
# CRITICAL DIFFERENCES from regular upgrade:
# - Can install new packages required by upgrades
# - Can remove packages that conflict with upgrades  
# - Resolves complex dependency chains automatically
# - May significantly change system package configuration
#
# USE WITH CAUTION: This operation can modify system behavior more extensively
full_upgrade() {
    # First check if there are any updates available before attempting dist-upgrade
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
    
    # Capture dist-upgrade output for processing with emoji markers
    local dist_upgrade_output
    dist_upgrade_output=$(sudo apt-get dist-upgrade -y 2>&1)
    local exit_code=$?
    
    # Process and display command output with appropriate Unicode emojis
    # Suppress consecutive duplicate lines to reduce redundancy
    local previous_line=""
    echo "$dist_upgrade_output" | while IFS= read -r line; do
        # Skip consecutive duplicate lines to reduce redundant output
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
            "") echo "" ;;  # Preserve empty lines
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

#=============================================================================
# SYSTEM CLEANUP AND MAINTENANCE FUNCTIONS  
#=============================================================================

# Comprehensive system cleanup to reclaim disk space and remove unnecessary files
# This function performs multiple cleanup operations to maintain system health
# and free up valuable disk space used by obsolete packages and cached files
cleanup() {

    print_operation_header "🧹 Performing comprehensive system cleanup..."
    print_status "🗑️  This will remove unnecessary packages and clean cached files"
    
    # STEP 1: Remove orphaned packages
    # These are packages that were installed as dependencies but are no longer needed
    # because the packages that required them have been removed
    print_operation_header "📦 Removing orphaned packages (autoremove)..."
    print_status "🔍 Identifying packages that were automatically installed but are no longer needed"
    
    # Capture autoremove output for processing with emoji markers
    local autoremove_output
    autoremove_output=$(sudo apt-get autoremove -y 2>&1)
    local autoremove_exit_code=$?
    
    # Process and display autoremove output with emojis
    echo "$autoremove_output" | while IFS= read -r line; do
        case "$line" in
            *"Reading package lists"*) echo "📖 $line" ;;
            *"Building dependency tree"*) echo "🌳 $line" ;;
            *"Reading state information"*) echo "🔍 $line" ;;
            *"The following packages will be REMOVED:"*) echo "🗑️  $line" ;;
            *"upgraded,"*|*"newly installed,"*|*"to remove"*) echo "📊 $line" ;;
            *"After this operation"*) echo "💾 $line" ;;
            *"Removing"*) echo "🗂️  $line" ;;
            *"Processing triggers"*) echo "🔄 $line" ;;
            *"ERROR"*|*"Error"*|*"error"*) echo "❌ $line" ;;
            *"WARNING"*|*"Warning"*|*"warning"*) echo "⚠️  $line" ;;
            *"W:"*) echo "⚠️  $line" ;;
            *"E:"*) echo "❌ $line" ;;
            "") echo "" ;;  # Preserve empty lines
            *) echo "💬 $line" ;;
        esac
    done
    
    if [ $autoremove_exit_code -eq 0 ]; then
        print_success "🗂️  Successfully removed orphaned packages"
    else
        print_warning "⚠️  Some orphaned packages could not be removed"
    fi
    
    # STEP 2: Clean package cache (partial cleaning)
    # Removes package files that can no longer be downloaded (outdated versions)
    # Keeps current versions in cache for potential reinstallation
    print_operation_header "💾 Cleaning outdated package cache files (autoclean)..."
    print_status "🗄️  Removing cached packages that are no longer available in repositories"
    
    # Capture autoclean output for processing with emoji markers
    local autoclean_output
    autoclean_output=$(sudo apt-get autoclean 2>&1)
    local autoclean_exit_code=$?
    
    # Process and display autoclean output with emojis
    echo "$autoclean_output" | while IFS= read -r line; do
        case "$line" in
            *"Reading package lists"*) echo "📖 $line" ;;
            *"Del "*) echo "🧽 $line" ;;
            *"ERROR"*|*"Error"*|*"error"*) echo "❌ $line" ;;
            *"WARNING"*|*"Warning"*|*"warning"*) echo "⚠️  $line" ;;
            *"W:"*) echo "⚠️  $line" ;;
            *"E:"*) echo "❌ $line" ;;
            "") echo "" ;;  # Preserve empty lines
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

# Detect and repair broken or partially configured packages
# This function performs comprehensive package integrity checks and repairs
# common package management issues that can occur during interrupted installations
# or system crashes during package operations
#
# Hierarchical Classification: Tier 2 Primary Function with Tier 3 Sub-operations
# - Uses Section Headers (Tier 2) for major steps with bold blue formatting
# - Uses Sub-step Headers (Tier 3) for status updates via print_status()
# - Maintains proper visual hierarchy with step-by-step progression
check_broken_packages() {
    print_operation_header "🔍 Performing comprehensive package integrity check..."
    
    # Use dpkg --audit to detect packages with problems
    # This command identifies packages that are not properly installed or configured
    local audit_output=$(dpkg --audit 2>/dev/null)
    
    if echo "$audit_output" | grep -q .; then
        # BROKEN PACKAGES DETECTED
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
        
        # Verify repair was successful
        local post_repair_audit=$(dpkg --audit 2>/dev/null)
        if echo "$post_repair_audit" | grep -q .; then
            print_warning "Some package issues remain after automatic repair"
            print_status "Consider manual package management for remaining issues"
        else
            print_success "All package integrity issues have been resolved"
        fi
    else
        # NO ISSUES DETECTED
        print_success "No broken packages found - system package integrity is good"
    fi
    
    ask_continue
}

#=============================================================================
# SNAP PACKAGE MANAGER FUNCTIONS
#=============================================================================
# Snap is Ubuntu's universal package management system for containerized
# applications. These functions handle Snap package updates and maintenance.

# Update all installed Snap packages to their latest versions
# Snap is Ubuntu's universal package management system for containerized applications
# This function handles Snap package updates with comprehensive availability and installation checking
#
# Hierarchical Classification: Validation-Focused Tier 2 Primary Function with Streamlined Tier 3 Sub-operations
# - Uses Section Headers (Tier 2) for major process announcements with bold blue formatting
# - Extensive use of Sub-step Headers (Tier 3) via print_status(), print_success(), print_warning()
# - Demonstrates validation-heavy design with multiple prerequisite checks and comprehensive user guidance
# - Features streamlined execution with clear Tier 2/Tier 3 distinction and error-resilient handling
# UI rule exception: No blank line echo needed - function immediately follows package manager header
update_snap_packages() {
    # Verify Snap package manager is installed and accessible
    # Snap is not available on all Linux distributions - primarily Ubuntu/Ubuntu-based
    if ! command -v snap &> /dev/null; then
        print_warning "📱 Snap package manager not installed - skipping Snap updates"
        print_status "🐧 Snap is primarily available on Ubuntu and Ubuntu-based distributions"
        print_status "💡 If you need Snap: install with 'sudo apt install snapd'"
        return 0
    fi
    
    print_operation_header "🔄 Initiating Snap package update process..."
    
    # Verify snap daemon is running and snap list is accessible
    # The snap list command will fail if snapd service is not running
    if ! snap list &> /dev/null; then
        print_warning "Snap daemon not accessible or no packages installed"
        print_status "Check if snapd service is running: 'systemctl status snapd'"
        return 0
    fi
    
    # Count installed snap packages (snap list includes header line)
    # We subtract 1 to get actual package count excluding the header
    local snap_count=$(snap list | wc -l)
    if [ "$snap_count" -le 1 ]; then
        print_warning "No snap packages currently installed - skipping updates"
        print_status "Install snap packages with: 'snap install <package-name>'"
        return 0
    fi
    
    print_status "Found $((snap_count - 1)) snap packages installed"
    print_operation_header "� Checking for available updates and refreshing all packages..."
    
    # Execute snap refresh to update all installed packages
    # This is equivalent to 'apt upgrade' but for containerized Snap applications
    # Snap handles rollbacks automatically if updates fail
    if snap refresh >/dev/null 2>&1; then
        print_success "All Snap packages updated successfully"
        print_status "Snap packages are automatically containerized and sandboxed"
        
        # Display updated package information for user verification
        print_status "Updated Snap package summary:"
        snap list --color=never 2>/dev/null | head -5
    else
        print_warning "Some Snap package updates failed or encountered issues"
        print_status "Common causes: network connectivity, package conflicts, or permission issues"
        print_status "Check detailed update status with: 'snap changes'"
        print_status "View specific package info with: 'snap info <package-name>'"
    fi
    
    ask_continue
}

#=============================================================================
# RUST/CARGO PACKAGE MANAGER FUNCTIONS
#=============================================================================
# Rust uses rustup for toolchain management and cargo for package installation.
# These functions handle both system Rust updates and user-installed cargo packages.

# Update rustup itself (the toolchain manager)
# This ensures we have the latest version of the installer/manager
# Follows Google style: single responsibility, proper error handling
update_rustup_toolchain() {
    print_operation_header "🛠️ Updating rustup toolchain manager..."
    
    if rustup self update >/dev/null 2>&1; then
        print_success "Rustup updated successfully to latest version"
        return 0
    else
        print_warning "Failed to update rustup - may affect subsequent operations"
        print_status "Check network connectivity and rustup permissions"
        return 1
    fi
}

# Update all installed Rust toolchains (stable, beta, nightly)
# This updates the actual Rust compiler and standard library
# Follows Google style: focused function with clear purpose
update_rust_toolchains() {
    print_operation_header "🦀 Updating all installed Rust toolchains..."
    
    if rustup update >/dev/null 2>&1; then
        print_success "All Rust toolchains updated successfully: $(rustup toolchain list | tr '\n' ' ')"
        return 0
    else
        print_warning "Some Rust toolchain updates failed"
        print_status "Check individual toolchain status with: 'rustup toolchain list'"
        return 1
    fi
}

# Install cargo-update utility for easier bulk package management
# Handles interactive installation prompt following Google style guidelines
install_cargo_update_utility() {
    # cargo-update not installed - offer to install it for easier future updates
    print_warning "cargo-update utility not found"
    print_status "cargo-update significantly simplifies cargo package management"
    
    # Interactive installation offer (only in interactive mode)
    if [[ "${QUIET_MODE:-false}" == "false" ]]; then
        echo
        print_status "cargo-update enables easy bulk updates of all cargo packages"
        echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Do you want to install cargo-update for future convenience? (Y/n): "
        read -r response
        case "$response" in
            [nN]|[nN][oO])
                print_status "Skipping cargo-update installation - will use manual method"
                return 1
                ;;
            *)
                print_operation_header "📥 Installing cargo-update utility..."
                if cargo install cargo-update >/dev/null 2>&1; then
                    print_success "cargo-update installed successfully"
                    return 0
                else
                    print_error "Failed to install cargo-update"
                    print_status "Network issues or cargo configuration problems may be the cause"
                    return 1
                fi
                ;;
        esac
    fi
    
    return 1
}

# Update common cargo packages manually when cargo-update is unavailable
# Follows Google style: array handling and proper local variable usage
update_common_cargo_packages() {
    print_status "Performing manual updates of commonly installed cargo packages..."
    
    # List of popular cargo packages users typically install
    # These are command-line tools commonly installed via 'cargo install'
    local -a common_packages=("ripgrep" "fd-find" "bat" "exa" "tokei" "hyperfine" "dust" "procs" "gitui" "bottom" "zoxide")
    local packages_updated=0
    local package
    
    for package in "${common_packages[@]}"; do
        # Check if this package is actually installed
        if cargo install --list | grep -q "^${package} "; then
            print_status "Updating ${package} to latest version..."
            # Force reinstall to get latest version
            if cargo install "${package}" --force >/dev/null 2>&1; then
                packages_updated=$((packages_updated + 1))
                print_success "${package} updated successfully"
            else
                print_warning "Failed to update ${package}"
            fi
        fi
    done
    
    if [[ "${packages_updated}" -gt 0 ]]; then
        print_success "Successfully updated ${packages_updated} cargo packages manually"
    else
        print_status "No recognized cargo packages found for manual update"
        print_status "Use 'cargo install --list' to see all installed packages"
    fi
    
    return 0
}

# Update cargo-installed packages (user-installed Rust applications)
# Handles both cargo-update utility and manual fallback methods
# Follows Google style: proper error handling and local variable usage
update_cargo_packages() {
    if ! command -v cargo &> /dev/null; then
        # Cargo not available - this means Rust isn't properly installed
        print_warning "Cargo package manager not available - skipping cargo updates"
        print_status "Cargo should be installed automatically with Rust via rustup"
        print_status "If missing, reinstall Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        return 1
    fi
    
    print_operation_header "🔍 Scanning for cargo-installed packages to update..."
    
    # Check if cargo-update utility is installed (makes bulk updates easier)
    # cargo-update is a third-party tool that simplifies updating all cargo packages
    if cargo install --list | grep -q "cargo-update"; then
        print_operation_header "⚡ Using cargo-update for efficient bulk package updates..."
        if cargo install-update -a >/dev/null 2>&1; then
            print_success "All cargo packages updated successfully to their latest versions via cargo-update"
            return 0
        else
            print_warning "Some cargo package updates failed or were skipped"
            print_status "Check individual package status with: 'cargo install --list'"
            return 1
        fi
    else
        # Try to install cargo-update utility
        if install_cargo_update_utility; then
            echo
            print_status "Now updating all cargo packages with new utility..."
            if cargo install-update -a >/dev/null 2>&1; then
                print_success "All cargo packages updated successfully"
                return 0
            else
                print_warning "Some package updates encountered issues"
                return 1
            fi
        else
            # FALLBACK: Manual updates for common cargo packages
            # If cargo-update is unavailable, attempt to update popular packages individually
            update_common_cargo_packages
            return $?
        fi
    fi
}

# Update Rust toolchain and cargo-installed packages
# Rust uses rustup for toolchain management and cargo for package installation
# This function coordinates all Rust ecosystem updates following Google style guidelines
# 
# Hierarchical Classification: Refactored Tier 2 Primary Function with Modular Sub-functions
# - Uses Section Headers (Tier 2) for main coordination with bold blue formatting
# - Delegates to focused helper functions following single responsibility principle
# - Implements proper error handling and local variable usage per Google guidelines
# - Maintains visual hierarchy while improving maintainability and testability
update_rust_packages() {
    # Verify rustup (Rust toolchain installer) is available
    # Rustup is the standard way to install and manage Rust toolchains
    if ! command -v rustup &> /dev/null; then
        print_warning "🦀 Rustup not installed - skipping Rust toolchain updates"
        print_status "🌐 Install Rust from: https://rustup.rs/"
        print_status "💻 Command: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        return 0
    fi
    
    print_operation_header "🦀 Initiating Rust ecosystem update process..."
    
    # STEP 1: Update rustup itself (the toolchain manager)
    update_rustup_toolchain
    
    # STEP 2: Update all installed Rust toolchains (stable, beta, nightly)
    update_rust_toolchains
    
    # STEP 3: Update cargo-installed packages (user-installed Rust applications)
    update_cargo_packages
    
    ask_continue
}

# Perform comprehensive dpkg package database maintenance and integrity checks
# This function handles package database inconsistencies, configuration conflicts,
# and system integrity verification for Debian/Ubuntu package management
#
# Hierarchical Classification: Structured Tier 2 Primary Function with Systematic Tier 3 Sub-operations
# - Uses Section Headers (Tier 2) for main announcements and major step divisions with bold blue formatting
# - Systematic use of Sub-step Headers (Tier 3) via print_status(), print_success(), print_warning()
# - Demonstrates excellent four-step organization with clear information hierarchy from general to specific
# - Provides comprehensive status reporting and actionable user guidance throughout
maintain_dpkg_packages() {
    print_operation_header "🔧 Initiating comprehensive dpkg maintenance operations..."
    print_status "This process checks package integrity, configurations, and database consistency"
    
    # STEP 1: Identify and repair packages in inconsistent states
    # dpkg maintains packages in various states: ii (installed), rc (removed but config remains), etc.
    print_operation_header "🔍 Scanning package database for consistency issues..."
    local inconsistent_packages=$(dpkg -l | grep -E "^[^ii]" | wc -l)
    
    if [ "$inconsistent_packages" -gt 0 ]; then
        print_warning "Found $inconsistent_packages packages in inconsistent state"
        print_status "Common states: rc (removed config), iU (unpacked), iF (half-configured)"
        
        # Configure any packages that are unpacked but not configured
        print_status "Configuring partially installed packages..."
        if dpkg --configure -a >/dev/null 2>&1; then
            print_success "Successfully configured all pending packages"
        else
            print_warning "Some packages could not be configured automatically"
            print_status "Manual intervention may be required for complex configuration issues"
        fi
        
        # Repair broken dependencies that prevent proper package states
        print_status "Repairing broken package dependencies..."
        if sudo apt-get install -f -y >/dev/null 2>&1; then
            print_success "Successfully repaired all broken dependencies"
        else
            print_warning "Some dependency issues could not be automatically resolved"
            print_status "Consider using 'apt --fix-broken install' manually"
        fi
    else
        print_success "Package database is consistent - all packages properly installed"
    fi
    
    # STEP 2: Detect and report configuration file conflicts
    # During upgrades, dpkg may leave conflicting config files for manual resolution
    print_status "Scanning for configuration file conflicts..."
    local config_files=$(find /etc -name "*.dpkg-*" 2>/dev/null | wc -l)
    
    if [ "$config_files" -gt 0 ]; then
        print_warning "Found $config_files configuration file conflicts requiring attention"
        print_status "These files were preserved during package upgrades:"
        
        # Show first 10 conflict files to avoid overwhelming output
        find /etc -name "*.dpkg-*" 2>/dev/null | head -10
        if [ "$config_files" -gt 10 ]; then
            print_status "... and $((config_files - 10)) more conflict files"
        fi
        
        print_status "Conflict types: .dpkg-old (old version), .dpkg-new (new version)"
        print_status "Resolution: Compare files and manually merge/replace as needed"
    else
        print_success "No configuration file conflicts detected"
    fi
    
    # STEP 3: Verify integrity of critical system packages
    # These packages are essential for system stability and should be verified
    print_status "Verifying integrity of critical system packages..."
    local critical_packages=("libc6" "systemd" "ubuntu-minimal" "apt" "dpkg")
    local verification_failed=false
    
    for package in "${critical_packages[@]}"; do
        # Only verify packages that are actually installed
        if dpkg -l "$package" &>/dev/null; then
            print_status "Verifying $package..."
            if ! dpkg -V "$package" &>/dev/null; then
                print_warning "Package $package failed integrity verification"
                verification_failed=true
            fi
        fi
    done
    
    if [ "$verification_failed" = false ]; then
        print_success "All critical system packages passed integrity verification"
    else
        print_warning "Some critical packages failed verification"
        print_status "Consider reinstalling failed packages: 'apt reinstall <package>'"
        print_status "Check for filesystem corruption if multiple packages fail"
    fi
    
    # STEP 4: Generate comprehensive package database summary
    print_status "Generating dpkg database status summary..."
    local total_packages=$(dpkg -l | grep -c "^ii")
    local held_packages=$(dpkg -l | grep -c "^hi")
    local config_files_only=$(dpkg -l | grep -c "^rc")
    
    echo "  Total properly installed packages: $total_packages"
    if [ "$held_packages" -gt 0 ]; then
        echo "  Packages held from updates: $held_packages"
        print_status "Held packages won't be upgraded automatically"
    fi
    if [ "$config_files_only" -gt 0 ]; then
        echo "  Packages removed but config files remain: $config_files_only"
        print_status "Use 'apt purge <package>' to remove config files"
    fi
    
    ask_continue
}

#=============================================================================
# PYTHON PIP PACKAGE MANAGER FUNCTIONS
#=============================================================================
# Python package management via pip (Python Package Index). These functions
# handle pip itself and all user-installed Python packages with security
# vulnerability checking and interactive update control.

# Update Python packages installed via pip (Python Package Index)
# This function handles both pip itself and all user-installed Python packages
# with security vulnerability checking and interactive update control
update_pip_packages() {
    # Verify pip3 is available (Python 3 package installer)
    # Most modern systems use pip3 specifically for Python 3 packages
    if ! command -v pip3 &> /dev/null; then
        print_warning "🐍 pip3 not installed - skipping Python package updates"
        print_status "💻 Install Python 3 and pip: 'sudo apt install python3-pip'"
        print_status "📦 Alternative: use system packages 'apt install python3-<package>'"
        return 0
    fi
    
    print_operation_header "� Initiating Python pip package update process..."
    print_status "� This will update pip itself and all user-installed Python packages"
    
    # STEP 1: Update pip package manager itself first
    # An outdated pip can cause issues when updating other packages
    print_operation_header "🛠️ Updating pip package manager to latest version..."
    if pip3 install --upgrade pip --user >/dev/null 2>&1; then
        print_success "pip successfully updated to latest version with improved dependency resolution and security"
    else
        print_warning "Failed to update pip - continuing with existing version"
        print_status "Network issues or permission problems may be the cause"
    fi
    
    # STEP 2: Discover outdated packages that need updates
    print_operation_header "🔍 Scanning for outdated Python packages..."
    local outdated_packages=$(pip3 list --outdated 2>/dev/null | tail -n +3 | awk '{print $1}')
    
    if [ -z "$outdated_packages" ]; then
        print_success "All Python pip packages are current - no updates needed"
        print_status "Your Python package ecosystem is up to date"
    else
        local package_count=$(echo "$outdated_packages" | wc -l)
        print_status "Found $package_count outdated Python packages requiring updates: $(echo "$outdated_packages" | head -5 | tr '\n' ' ')"
        
        # Interactive confirmation for bulk updates (respects quiet mode)
        local update_all=true
        if [ "$QUIET_MODE" = false ]; then
            echo
            if [ "$package_count" -gt 5 ]; then
                print_status "... and $((package_count - 5)) more packages"
            fi
            echo
            echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Do you want to update all outdated pip packages? (Y/n): "
            read -r response
            case "$response" in
                [nN]|[nN][oO])
                    update_all=false
                    print_status "Skipping pip package updates per user request"
                    ;;
                *)
                    update_all=true
                    print_status "Proceeding with comprehensive pip package updates"
                    ;;
            esac
        fi
        
        # STEP 3: Perform individual package updates with error tracking
        if [ "$update_all" = true ]; then
            print_operation_header "🔄 Updating outdated pip packages individually for better error handling..."
            local updated_count=0
            local failed_count=0
            
            # Process each package individually to handle failures gracefully
            while IFS= read -r package; do
                if [ -n "$package" ]; then
                    print_status "Updating Python package: $package"
                    if pip3 install --upgrade "$package" --user >/dev/null 2>&1; then
                        updated_count=$((updated_count + 1))
                        print_success "Successfully updated $package"
                    else
                        print_warning "Failed to update $package"
                        failed_count=$((failed_count + 1))
                        print_status "Possible causes: dependency conflicts, network issues, or package deprecation"
                    fi
                fi
            done <<< "$outdated_packages"
            
            # Summary of update results
            if [ "$updated_count" -gt 0 ]; then
                print_success "Successfully updated $updated_count Python packages"
            fi
            if [ "$failed_count" -gt 0 ]; then
                print_warning "$failed_count Python packages failed to update"
                print_status "Review error messages above for specific failure causes"
                print_status "Consider manual updates: 'pip3 install --upgrade <package> --user'"
            fi
        fi
    fi
    
    # STEP 4: Security vulnerability assessment (optional pip-audit tool)
    # pip-audit scans installed packages for known security vulnerabilities
    if command -v pip-audit &> /dev/null; then
        print_status "Performing security vulnerability scan of Python packages..."
        if pip-audit --desc; then
            print_success "No known security vulnerabilities found in Python packages"
        else
            print_warning "Some Python packages have known security vulnerabilities"
            print_status "Review pip-audit output above and update vulnerable packages"
            print_status "Consider using 'pip-audit --fix' to automatically resolve issues"
        fi
    else
        print_status "pip-audit security scanner not installed (optional)"
        print_status "Install for vulnerability checking: 'pip3 install pip-audit --user'"
        print_status "pip-audit helps identify packages with known security issues"
    fi
    
    ask_continue
}

#=============================================================================
# CALIBRE APPLICATION FUNCTIONS
#=============================================================================
# Calibre e-book management software update and version checking functions.
# Handles multiple installation methods including direct binary, apt, and snap.

# Detect if Calibre e-book management software is installed on the system
# Calibre can be installed via multiple methods: direct binary, apt package, or snap
# This function comprehensively checks all possible installation methods
check_calibre_installed() {
    # METHOD 1: Check for Calibre main executable in system PATH
    # This catches direct binary installations and most package manager installs
    if command -v calibre >/dev/null 2>&1; then
        return 0  # Found calibre executable - installation confirmed
    
    # METHOD 2: Check for calibre-debug utility (alternative detection method)  
    # calibre-debug is installed alongside calibre and may be available even if main executable isn't in PATH
    elif command -v calibre-debug >/dev/null 2>&1; then
        return 0  # Found calibre-debug - calibre installation confirmed
    
    # METHOD 3: Check apt/dpkg package database for calibre package
    # This detects installations via Ubuntu/Debian package manager
    elif dpkg -l | grep -q "^ii.*calibre"; then
        return 0  # Found calibre in dpkg database - apt installation confirmed
    
    # METHOD 4: Check snap package system for calibre installation
    # Snap packages are containerized and may not appear in standard PATH
    elif snap list | grep -q calibre 2>/dev/null; then
        return 0  # Found calibre in snap packages - snap installation confirmed
    
    # No installation method detected - Calibre is not installed
    else
        return 1  # Calibre installation not found via any supported method
    fi
}

# Extract the currently installed version of Calibre e-book management software
# Different installation methods store version information in different locations
# This function tries multiple detection methods to find the installed version
get_calibre_current_version() {
    local version=""
    
    # METHOD 1: Query calibre-debug for version information (most reliable)
    # calibre-debug provides consistent version output across all installation types
    if command -v calibre-debug >/dev/null 2>&1; then
        version=$(calibre-debug --version 2>/dev/null | head -1 | sed 's/.*calibre \([0-9]\+\.[0-9]\+\.[0-9]\+\|[0-9]\+\.[0-9]\+\).*/\1/' | grep -E "^[0-9]+\.[0-9]+(\.[0-9]+)?$")
    fi
    
    # METHOD 2: Query main calibre executable if debug tool didn't work
    # Some installations may have calibre but not calibre-debug in PATH
    if [ -z "$version" ] && command -v calibre >/dev/null 2>&1; then
        version=$(calibre --version 2>/dev/null | head -1 | sed 's/.*calibre \([0-9]\+\.[0-9]\+\.[0-9]\+\|[0-9]\+\.[0-9]\+\).*/\1/' | grep -E "^[0-9]+\.[0-9]+(\.[0-9]+)?$")
    fi
    
    # METHOD 3: Check package manager database for version (apt/dpkg installations)
    # Package manager maintains version info even if executable queries fail
    if [ -z "$version" ] && dpkg -l | grep -q "^ii.*calibre"; then
        version=$(dpkg -l | grep "^ii.*calibre " | awk '{print $3}' | head -1 | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+")
    fi
    
    # Return detected version or empty string if detection failed
    echo "$version"
}

# Retrieve the latest available version of Calibre from official sources
# This function checks multiple sources to determine the most current version
# Uses GitHub API as primary source with apt repository as fallback
get_calibre_latest_version() {
    local latest_version=""
    
    # PRIMARY METHOD: Query GitHub API for latest official release
    # Calibre releases are published on GitHub with version tags
    if command -v curl >/dev/null 2>&1; then
        print_status "Checking GitHub API for latest Calibre version..." >&2
        latest_version=$(curl -s --connect-timeout 10 "https://api.github.com/repos/kovidgoyal/calibre/releases/latest" 2>/dev/null | grep '"tag_name"' | sed 's/.*"tag_name": *"v*\([^"]*\)".*/\1/' | head -1)
        
        if [ -n "$latest_version" ]; then
            print_status "Retrieved latest version from GitHub: $latest_version" >&2
        fi
    fi
    
    # FALLBACK METHOD: Check apt repository candidate version
    # Repository version may be older but is more reliable when network issues occur
    if [ -z "$latest_version" ] && command -v apt >/dev/null 2>&1; then
        print_status "GitHub API unavailable - checking apt repository version..." >&2
        latest_version=$(apt-cache policy calibre 2>/dev/null | grep "Candidate:" | awk '{print $2}' | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+")
        
        if [ -n "$latest_version" ]; then
            print_status "Retrieved version from apt repository: $latest_version" >&2
            print_status "Note: Repository version may be older than GitHub release" >&2
        fi
    fi
    
    # Return detected version or empty string if all methods failed
    echo "$latest_version"
}

# Compare two semantic version strings to determine if an update is available
# Handles various version formats (x.y, x.y.z) and normalizes them for comparison
# Used specifically for Calibre version checking but could be used for other software
compare_versions() {
    local current="$1"   # Currently installed version
    local latest="$2"    # Latest available version
    
    # Input validation - both versions must be provided
    if [ -z "$current" ] || [ -z "$latest" ]; then
        return 2  # Cannot compare - insufficient data
    fi
    
    # STEP 1: Normalize version strings to consistent x.y.z format
    # This handles cases where versions may be x.y or x.y.z format
    local current_norm=$(echo "$current" | awk -F. '{printf "%s.%s.%s", $1, ($2?$2:0), ($3?$3:0)}')
    local latest_norm=$(echo "$latest" | awk -F. '{printf "%s.%s.%s", $1, ($2?$2:0), ($3?$3:0)}')
    
    # STEP 2: Convert normalized versions to comparable integer format
    # Format: MMMMIIIPPP where M=major, I=minor, P=patch (each zero-padded to 3 digits)
    # Example: 1.23.45 becomes 1023045, 2.0.1 becomes 2000001
    local current_num=$(echo "$current_norm" | awk -F. '{printf "%d%03d%03d\n", $1, $2, $3}')
    local latest_num=$(echo "$latest_norm" | awk -F. '{printf "%d%03d%03d\n", $1, $2, $3}')
    
    # STEP 3: Perform numerical comparison
    if [ "$current_num" -lt "$latest_num" ]; then
        return 0  # Update available - current version is older
    else
        return 1  # Up to date - current version is same or newer
    fi
}

# Download and install the latest version of Calibre directly from official sources
# This function handles the complete download and installation process including
# backup of current installation, verification, and cleanup
download_and_install_calibre() {
    local target_version="$1"   # Version to install (for verification)
    
    print_status "Initiating direct Calibre download and installation..."
    print_status "Target version: $target_version"
    print_status ""
    
    # STEP 1: Verify required tools are available
    if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
        print_error "Neither wget nor curl is available for downloading"
        print_error "Install wget: sudo apt install wget"
        print_error "Install curl: sudo apt install curl"
        return 1
    fi
    
    # STEP 2: Prepare temporary directory for download
    local temp_dir=$(mktemp -d -t calibre_update_XXXXXX)
    if [ ! -d "$temp_dir" ]; then
        print_error "Failed to create temporary directory for Calibre download"
        return 1
    fi
    
    print_status "Using temporary directory: $temp_dir"
    
    # STEP 3: Download the official Calibre installer
    print_status "Downloading Calibre installer from official source..."
    print_status "URL: https://download.calibre-ebook.com/linux-installer.sh"
    
    local installer_path="$temp_dir/calibre-installer.sh"
    local download_success=false
    
    # Try wget first, then curl as fallback
    if command -v wget >/dev/null 2>&1; then
        print_status "Using wget to download installer..."
        if wget --timeout=30 --tries=3 -O "$installer_path" "https://download.calibre-ebook.com/linux-installer.sh"; then
            download_success=true
        fi
    elif command -v curl >/dev/null 2>&1; then
        print_status "Using curl to download installer..."
        if curl --connect-timeout 30 --retry 3 -L -o "$installer_path" "https://download.calibre-ebook.com/linux-installer.sh"; then
            download_success=true
        fi
    fi
    
    if [ "$download_success" = false ]; then
        print_error "Failed to download Calibre installer"
        print_error "Please check your internet connection and try again"
        print_error "Manual download: https://calibre-ebook.com/download_linux"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # STEP 4: Verify installer was downloaded and is not empty
    if [ ! -s "$installer_path" ]; then
        print_error "Downloaded installer is empty or corrupted"
        print_error "Please try again or download manually"
        rm -rf "$temp_dir"
        return 1
    fi
    
    local installer_size=$(du -h "$installer_path" | cut -f1)
    print_success "✓ Calibre installer downloaded successfully ($installer_size)"
    
    # STEP 5: Make installer executable and verify it's a shell script
    chmod +x "$installer_path"
    
    if ! head -1 "$installer_path" | grep -q "#!/"; then
        print_error "Downloaded file doesn't appear to be a valid shell script"
        print_error "File may be corrupted or blocked by network filters"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # STEP 6: Create backup information of current installation (for rollback)
    print_status "Backing up current Calibre installation information..."
    local current_version_backup=$(get_calibre_current_version)
    local calibre_location=""
    
    if command -v calibre >/dev/null 2>&1; then
        calibre_location=$(which calibre)
        print_status "Current Calibre location: $calibre_location"
        print_status "Current version: $current_version_backup"
    fi
    
    # STEP 7: Provide user with final confirmation and safety information
    echo
    print_warning "⚠ IMPORTANT INSTALLATION NOTES ⚠"
    print_status "• This will replace your current Calibre installation"
    print_status "• The installer will download additional files (~100MB+)"
    print_status "• Installation requires root privileges"
    print_status "• Your Calibre libraries and settings will be preserved"
    print_status "• Installation typically takes 2-5 minutes depending on connection"
    echo
    echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Are you sure you want to proceed with the installation? (y/N): "
    read -r final_confirmation
    
    case "$final_confirmation" in
        [yY][eE][sS]|[yY])
            print_status "Proceeding with Calibre installation..."
            ;;
        *)
            print_status "Installation cancelled by user"
            rm -rf "$temp_dir"
            return 1
            ;;
    esac
    
    # STEP 8: Execute the Calibre installer
    print_status "Executing Calibre installer (this may take several minutes)..."
    print_status "The installer will download and install the latest Calibre version"
    echo
    
    # Run the installer with proper error handling
    if bash "$installer_path" >/dev/null 2>&1; then
        print_success "✓ Calibre installer completed successfully"
    else
        local install_exit_code=$?
        print_error "Calibre installation failed with exit code: $install_exit_code"
        print_error "Common causes:"
        print_error "  - Network connectivity issues during binary download"
        print_error "  - Insufficient disk space"
        print_error "  - Permission problems"
        print_error "  - Conflicting processes using Calibre"
        print_status "You can try running the installer manually:"
        print_status "  bash $installer_path"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # STEP 9: Verify the installation was successful
    print_status "Verifying new Calibre installation..."
    
    # Allow some time for installation to complete and binaries to be available
    sleep 2
    
    # Check if Calibre is still accessible
    if ! check_calibre_installed; then
        print_error "Calibre installation verification failed - command not found"
        print_error "Installation may have failed or Calibre needs to be added to PATH"
        print_status "Try running 'hash -r' or restart your terminal"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Get the newly installed version
    local new_version=$(get_calibre_current_version)
    if [ -z "$new_version" ]; then
        print_warning "Could not determine new Calibre version"
        print_status "Calibre appears to be installed but version detection failed"
    else
        print_success "✓ New Calibre version detected: $new_version"
        
        # Compare with what we expected to install
        if [ "$new_version" = "$target_version" ]; then
            print_success "✓ Successfully updated to target version $target_version"
        elif [ -n "$current_version_backup" ] && compare_versions "$current_version_backup" "$new_version"; then
            print_success "✓ Successfully upgraded from $current_version_backup to $new_version"
        else
            print_warning "Version check: expected $target_version, got $new_version"
            print_status "Installation succeeded but version may differ from expected"
        fi
    fi
    
    # STEP 10: Cleanup temporary files
    print_status "Cleaning up temporary installation files..."
    rm -rf "$temp_dir"
    
    # STEP 11: Final verification and user guidance
    print_success "🎉 Calibre installation completed!"
    print_status ""
    print_status "Installation summary:"
    if [ -n "$current_version_backup" ]; then
        print_status "  Previous version: $current_version_backup"
    fi
    if [ -n "$new_version" ]; then
        print_status "  Current version:  $new_version"
    fi
    print_status "  Installation method: Direct download from official source"
    print_status ""
    print_status "Next steps:"
    print_status "  • Launch Calibre to verify it works: calibre"
    print_status "  • Your library and settings should be preserved"
    print_status "  • Check Preferences > Plugins if you use custom plugins"
    print_status "  • Report any issues to: https://calibre-ebook.com/help"
    
    return 0
}

# Check if Calibre e-book management software needs updating and optionally perform update
# This function combines detection, version comparison, and interactive update capabilities
# Handles both repository-based and direct download installation update paths
check_calibre_update() {
    print_operation_header "� Initiating Calibre update check process..."
    
    # STEP 1: Verify Calibre is actually installed before checking for updates
    if ! check_calibre_installed; then
        print_warning "📚 Calibre e-book management software not installed"
        print_status "💻 Install Calibre: 'sudo apt install calibre' or visit https://calibre-ebook.com/"
        return 1
    fi
    
    # STEP 2: Gather current and latest version information
    print_operation_header "🔍 Retrieving version information for comparison..."
    local current_version=$(get_calibre_current_version)
    local latest_version=$(get_calibre_latest_version)
    
    # Validate that we successfully retrieved version information
    if [ -z "$current_version" ]; then
        print_warning "🔍 Could not determine current Calibre version"
        print_status "Version detection failed - Calibre may be improperly installed"
        return 1
    fi
    
    if [ -z "$latest_version" ]; then
        print_warning "🌐 Could not retrieve latest Calibre version"
        print_status "📡 Network connectivity issues or GitHub API problems"
        return 1
    fi
    
    # STEP 3: Display version information for user awareness
    print_status "📊 Calibre version comparison:"
    print_status "  📦 Currently installed: $current_version"
    print_status "  🆕 Latest available:    $latest_version"
    
    # STEP 4: Compare versions and handle update availability
    if compare_versions "$current_version" "$latest_version"; then
        # UPDATE AVAILABLE - Enhanced user notification
        print_warning "🔔 >>> CALIBRE UPDATE AVAILABLE <<<"
        print_status "📈 Update path: $current_version → $latest_version"
        print_status ""
        print_status "🛠️  Available update methods:"
        print_status "  1️⃣  Package manager:  sudo apt update && sudo apt upgrade calibre"
        print_status "  2️⃣  Direct installer: Download and install latest from official source"
        print_status "  3️⃣  Manual download:  https://calibre-ebook.com/download_linux"
        
        # Interactive update offer (respects quiet mode)
        if [ "$QUIET_MODE" = false ]; then
            echo
            print_status "❓ How would you like to update Calibre?"
            print_status "  1️⃣  Try apt package manager first (faster, may be older version)"
            print_status "  2️⃣  Download and install latest version directly (newest, takes longer)"
            print_status "  3️⃣  Skip update"
            echo
            echo -n -e "${MAGENTA}❓ [PROMPT]${NC} 🤔 Choose update method (1/2/3): "
            read -r response
            
            case "$response" in
                1)
                    # Method 1: Try apt package manager first
                    print_status "📦 Attempting Calibre update via apt package manager..."
                    if sudo apt-get update >/dev/null 2>&1 && sudo apt-get upgrade calibre -y >/dev/null 2>&1; then
                        # VERIFICATION: Check if update was actually applied
                        local new_version=$(get_calibre_current_version)
                        if [ -n "$new_version" ] && [ "$new_version" != "$current_version" ]; then
                            print_success "✅ Calibre successfully updated via apt: $current_version → $new_version"
                            
                            # Check if we got the latest version
                            if compare_versions "$new_version" "$latest_version"; then
                                print_warning "⚠️  Apt version ($new_version) is still older than latest ($latest_version)"
                                echo -n -e "${MAGENTA}❓ [PROMPT]${NC} 💭 Would you like to download the latest version now? (y/N): "
                                read -r direct_response
                                case "$direct_response" in
                                    [yY][eE][sS]|[yY])
                                        download_and_install_calibre "$latest_version"
                                        ;;
                                    *)
                                        print_status "📦 Keeping apt-installed version $new_version"
                                        ;;
                                esac
                            else
                                print_success "✓ Calibre is now up to date with the latest version!"
                            fi
                        else
                            print_warning "🔄 Calibre version appears unchanged after apt update"
                            print_status "📥 Repository version may be outdated. Trying direct download..."
                            download_and_install_calibre "$latest_version"
                        fi
                    else
                        print_warning "❌ Apt package manager update failed. Trying direct download..."
                        download_and_install_calibre "$latest_version"
                    fi
                    ;;
                2)
                    # Method 2: Direct download and installation
                    download_and_install_calibre "$latest_version"
                    ;;
                3|*)
                    print_status "⏭️  Skipping Calibre update per user request"
                    print_status "💡 You can update manually later using any of the methods listed above"
                    ;;
            esac
        else
            # Quiet mode - provide instructions but don't perform update
            print_status "🔇 Quiet mode active - skipping interactive Calibre update"
            print_status "💻 Update manually: 'sudo apt update && sudo apt upgrade calibre'"
            print_status "🔗 Or download directly: https://calibre-ebook.com/download_linux"
        fi
        
        return 0  # Update was available (whether installed or not)
    else
        # NO UPDATE NEEDED
        print_success "✅ Calibre is up to date (version $current_version)"
        return 1  # No update needed
    fi
    
    ask_continue
}

#=============================================================================
# KITTY TERMINAL EMULATOR
#=============================================================================
# Kitty is a fast, feature-rich, GPU-based terminal emulator. This section
# checks for and installs available Kitty updates using the official Kitty
# installer script.
#
# Features:
# - Detects if Kitty terminal emulator is installed on the system
# - Checks for available Kitty updates using version comparison
# - Installs updates using the official Kitty installer script
# - Provides informative feedback about the update process
#
# Note: Kitty uses a custom installer that downloads and installs the latest
# version directly from the Kitty GitHub releases. This is the recommended
# update method for Kitty installations.
#

check_kitty_update() {
    print_operation_header "Checking for Kitty terminal emulator updates..."
    
    # Check if Kitty is installed in common locations
    local kitty_bin=""
    local is_kitty_installed=$(command -v kitty >/dev/null 2>&1; echo $?)
    print_status "is_kitty_installed=$is_kitty_installed"
    if [ $is_kitty_installed -eq 0 ]; then
        kitty_bin="kitty"
    elif [ -x "$HOME/.local/kitty.app/bin/kitty" ]; then
        kitty_bin="$HOME/.local/kitty.app/bin/kitty"
    elif [ -x "/usr/local/bin/kitty" ]; then
        kitty_bin="/usr/local/bin/kitty"
    elif [ -x "/usr/bin/kitty" ]; then
        kitty_bin="/usr/bin/kitty"
    else
        print_status "Kitty terminal emulator is not installed on this system"
        return 0
    fi
    
    print_status "Found Kitty at: $kitty_bin"
    
    # Get current Kitty version
    local current_version
    current_version=$("$kitty_bin" --version 2>/dev/null | awk '{print $2}')
    
    if [ -z "$current_version" ]; then
        print_warning "Could not determine current Kitty version"
        return 1
    fi
    
    print_status "Current Kitty version: $current_version"
    
    # Check for latest version from GitHub releases
    print_status "Checking for latest Kitty version..."
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/kovidgoyal/kitty/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
    
    if [ -z "$latest_version" ]; then
        print_warning "Could not fetch latest Kitty version from GitHub"
        return 1
    fi
    
    print_status "Latest Kitty version: $latest_version"
    
    # Compare versions
    if [ "$current_version" = "$latest_version" ]; then
        print_success "Kitty is already up to date (version $current_version)"
        return 0
    fi
    
    print_status "A newer version of Kitty is available: $latest_version (current: $current_version)"
    
    # Install update using official installer
    print_operation_header "Installing Kitty update..."
    
    if curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin; then
        print_success "Kitty has been updated successfully to version $latest_version"
        
        # Verify the update
        local new_version
        new_version=$("$kitty_bin" --version 2>/dev/null | awk '{print $2}')
        if [ -n "$new_version" ]; then
            print_success "Verified new Kitty version: $new_version"
        fi
    else
        print_error "Failed to update Kitty terminal emulator"
        return 1
    fi
    
    return 0
}

#=============================================================================
# NODE.JS NPM PACKAGE MANAGER FUNCTIONS
#=============================================================================
# Node.js package management via npm (Node Package Manager). These functions
# handle npm itself and all globally installed Node.js packages.

# Function to update npm packages
update_npm_packages() {
    # Check if npm is installed
    if ! command -v npm &> /dev/null; then
        print_warning "📗 npm is not installed on this system, skipping npm package updates"
        return 0
    fi
    
    print_operation_header "� Updating npm packages..."
    
    # Update npm itself first
    print_status "� Updating npm to latest version..."
    if npm install -g npm@latest; then
        print_success "📗 npm updated successfully"
        
        # Check for funding message and provide info
        local funding_output=$(npm fund 2>/dev/null | head -5)
        if echo "$funding_output" | grep -q "packages are looking for funding"; then
            local funding_count=$(echo "$funding_output" | grep -o '[0-9]\+ packages are looking for funding' | grep -o '[0-9]\+')
            if [ -n "$funding_count" ]; then
                print_status "💰 $funding_count packages are looking for funding"
                print_status "💡 Run 'npm fund' to see funding opportunities for your packages"
            fi
        fi
    else
        print_warning "Failed to update npm, but continuing with package updates..."
    fi
    
    # Get list of outdated global packages
    print_status "🔍 Checking for outdated global packages..."
    local outdated_output=$(npm outdated -g --json 2>/dev/null)
    
    if [ -z "$outdated_output" ] || [ "$outdated_output" = "{}" ]; then
        print_success "📗 All global npm packages are up to date"
    else
        # Parse JSON to get package names
        local outdated_packages=$(echo "$outdated_output" | grep -o '"[^"]*"' | head -n -1 | tail -n +2 | tr -d '"' | grep -v "current\|wanted\|latest\|location")
        
        if [ -n "$outdated_packages" ]; then
            local package_count=$(echo "$outdated_packages" | wc -l)
            print_status "Found $package_count outdated global packages"
            
            # Ask user if they want to update all packages (unless in quiet mode)
            local update_all=true
            if [ "$QUIET_MODE" = false ]; then
                echo
                echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Do you want to update all outdated global npm packages? (Y/n): "
                read -r response
                case "$response" in
                    [nN]|[nN][oO])
                        update_all=false
                        print_status "Skipping npm package updates"
                        ;;
                    *)
                        update_all=true
                        ;;
                esac
            fi
            
            if [ "$update_all" = true ]; then
                print_operation_header "🔄 Updating outdated global npm packages..."
                local updated_count=0
                local failed_count=0
                
                # Alternative approach: use npm update -g for all packages
                local update_output=$(npm update -g 2>&1)
                if [ $? -eq 0 ]; then
                    print_success "Global npm packages updated successfully"
                    
                    # Handle funding message if present
                    if echo "$update_output" | grep -q "packages are looking for funding"; then
                        local funding_count=$(echo "$update_output" | grep -o '[0-9]\+ packages are looking for funding' | grep -o '[0-9]\+' | head -1)
                        if [ -n "$funding_count" ]; then
                            print_status "$funding_count packages are looking for funding"
                            print_status "Run 'npm fund' to see funding opportunities"
                        fi
                    fi
                else
                    print_warning "Some npm package updates may have failed"
                    
                    # Fallback: try individual package updates
                    print_status "Attempting individual package updates..."
                    while IFS= read -r package; do
                        if [ -n "$package" ]; then
                            print_status "Updating $package..."
                            local install_output=$(npm install -g "$package@latest" 2>&1)
                            if [ $? -eq 0 ]; then
                                updated_count=$((updated_count + 1))
                                
                                # Handle funding message for individual packages
                                if echo "$install_output" | grep -q "packages are looking for funding"; then
                                    local pkg_funding=$(echo "$install_output" | grep -o '[0-9]\+ packages are looking for funding' | grep -o '[0-9]\+' | head -1)
                                    if [ -n "$pkg_funding" ] && [ "$pkg_funding" -gt 0 ]; then
                                        print_status "($pkg_funding packages seeking funding after $package update)"
                                    fi
                                fi
                            else
                                print_warning "Failed to update $package"
                                failed_count=$((failed_count + 1))
                            fi
                        fi
                    done <<< "$outdated_packages"
                    
                    if [ "$updated_count" -gt 0 ]; then
                        print_success "Successfully updated $updated_count npm packages individually"
                    fi
                    if [ "$failed_count" -gt 0 ]; then
                        print_warning "$failed_count npm packages failed to update"
                    fi
                fi
            fi
        else
            print_success "All global npm packages are up to date"
        fi
    fi
    
    # Note: npm audit doesn't support global packages, so we skip this check
    print_status "Note: Security auditing is not available for global npm packages"
    print_status "Consider checking individual package security manually if needed"
    
    # Show funding summary if there are packages looking for funding
    print_status "Checking funding opportunities..."
    local total_funding=$(npm fund --json 2>/dev/null | grep -o '"funding"' | wc -l)
    if [ "$total_funding" -gt 0 ]; then
        print_status "Found $total_funding packages with funding opportunities"
        print_status "To support package maintainers, run: npm fund"
        print_status "This helps sustain the open-source ecosystem"
    else
        print_success "No specific funding requests found"
    fi
    
    # Clean up npm cache
    print_status "Cleaning npm cache..."
    if npm cache clean --force; then
        print_success "npm cache cleaned successfully"
    else
        print_warning "Failed to clean npm cache, but continuing..."
    fi
    
    ask_continue
}

# Function to show disk usage before and after
# Uses print_status() which classifies this as Tier 3 (Sub-step Headers) in the hierarchical output structure
show_disk_usage() {
    print_status "Disk usage in /var/cache/apt/archives/:"
    du -sh /var/cache/apt/archives/ 2>/dev/null || echo "Unable to check cache size"
}

# Function to ask user if they want to continue
ask_continue() {
    # Only prompt for user interaction in stop mode
    if [ "$STOP_MODE" = true ] && [ "$QUIET_MODE" = false ]; then
        echo -n -e "${MAGENTA}❓ [PROMPT]${NC} Do you want to continue? (Y/n): "
        read -r response
        case "$response" in
            [nN]|[nN][oO])
                print_warning "Operation cancelled by user."
                exit 0
                ;;
            *)
                return 0
                ;;
        esac
    fi
}

# Function to list all installed packages by package manager
list_all_packages() {
    print_status "Listing all installed packages by package manager..."
    echo
    
    # APT/DPKG packages
    if command -v dpkg &> /dev/null; then
        print_status "APT/DPKG packages:"
        local apt_count=$(dpkg -l | grep "^ii" | wc -l)
        echo "  Total APT packages: $apt_count"
        if [ "$1" = "--detailed" ]; then
            echo "  Recent APT packages (last 10):"
            dpkg -l | grep "^ii" | tail -10 | awk '{printf "    %-30s %s\n", $2, $3}'
        fi
        echo
    fi
    
    # Snap packages
    if command -v snap &> /dev/null; then
        print_status "Snap packages:"
        if snap list &> /dev/null; then
            local snap_count=$(snap list | tail -n +2 | wc -l)
            echo "  Total Snap packages: $snap_count"
            if [ "$1" = "--detailed" ]; then
                echo "  Installed Snap packages:"
                snap list | tail -n +2 | awk '{printf "    %-30s %s\n", $1, $2}'
            fi
        else
            echo "  No Snap packages installed"
        fi
        echo
    fi
    
    # Flatpak packages
    if command -v flatpak &> /dev/null; then
        print_status "Flatpak packages:"
        if flatpak list &> /dev/null; then
            local flatpak_count=$(flatpak list --app | wc -l)
            echo "  Total Flatpak packages: $flatpak_count"
            if [ "$1" = "--detailed" ]; then
                echo "  Installed Flatpak packages:"
                flatpak list --app --columns=name,version | head -20
            fi
        else
            echo "  No Flatpak packages installed"
        fi
        echo
    fi
    
    # Cargo packages
    if command -v cargo &> /dev/null; then
        print_status "Cargo (Rust) packages:"
        if cargo install --list &> /dev/null; then
            local cargo_packages=$(cargo install --list | grep -E "^[a-zA-Z]" | wc -l)
            echo "  Total Cargo packages: $cargo_packages"
            if [ "$1" = "--detailed" ] && [ "$cargo_packages" -gt 0 ]; then
                echo "  Installed Cargo packages:"
                cargo install --list | grep -E "^[a-zA-Z]" | head -20
            fi
        else
            echo "  No Cargo packages installed"
        fi
        echo
    fi
    
    # Python pip packages (global)
    if command -v pip3 &> /dev/null; then
        print_status "Python pip packages (global):"
        local pip_count=$(pip3 list 2>/dev/null | tail -n +3 | wc -l)
        echo "  Total pip packages: $pip_count"
        if [ "$1" = "--detailed" ]; then
            echo "  Recent pip packages (last 10):"
            pip3 list 2>/dev/null | tail -10 | awk '{printf "    %-30s %s\n", $1, $2}'
        fi
        echo
    fi
    
    # Node.js npm packages (global)
    if command -v npm &> /dev/null; then
        print_status "Node.js npm packages (global):"
        local npm_packages=$(npm list -g --depth=0 2>/dev/null | grep -E "├──|└──" | wc -l)
        echo "  Total global npm packages: $npm_packages"
        if [ "$1" = "--detailed" ] && [ "$npm_packages" -gt 0 ]; then
            echo "  Installed global npm packages:"
            npm list -g --depth=0 2>/dev/null | grep -E "├──|└──" | head -20
        fi
        echo
    fi
    
    # Calibre application
    if check_calibre_installed; then
        print_status "Calibre:"
        local calibre_version=$(get_calibre_current_version)
        if [ -n "$calibre_version" ]; then
            echo "  Installed version: $calibre_version"
            if [ "$1" = "--detailed" ]; then
                local latest_version=$(get_calibre_latest_version)
                if [ -n "$latest_version" ]; then
                    echo "  Latest available: $latest_version"
                    if compare_versions "$calibre_version" "$latest_version"; then
                        echo "  Status: Update available"
                    else
                        echo "  Status: Up to date"
                    fi
                else
                    echo "  Status: Could not check latest version"
                fi
            fi
        else
            echo "  Status: Installed (version unknown)"
        fi
        echo
    fi
    
    # AppImage files
    local appimage_dirs=("$HOME/Applications" "$HOME/.local/share/applications" "/opt" "$HOME/AppImages")
    local appimage_count=0
    for dir in "${appimage_dirs[@]}"; do
        if [ -d "$dir" ]; then
            appimage_count=$((appimage_count + $(find "$dir" -name "*.AppImage" 2>/dev/null | wc -l)))
        fi
    done
    
    if [ "$appimage_count" -gt 0 ]; then
        print_status "AppImage applications:"
        echo "  Total AppImage files: $appimage_count"
        if [ "$1" = "--detailed" ]; then
            echo "  AppImage locations:"
            for dir in "${appimage_dirs[@]}"; do
                if [ -d "$dir" ]; then
                    find "$dir" -name "*.AppImage" 2>/dev/null | head -10 | sed 's/^/    /'
                fi
            done
        fi
        echo
    fi
    
    # Summary
    print_success "Package Manager Summary:"
    local total_packages=0
    
    if command -v dpkg &> /dev/null; then
        local apt_total=$(dpkg -l | grep "^ii" | wc -l)
        echo "  APT/DPKG: $apt_total packages"
        total_packages=$((total_packages + apt_total))
    fi
    
    if command -v snap &> /dev/null && snap list &> /dev/null; then
        local snap_total=$(snap list | tail -n +2 | wc -l)
        echo "  Snap: $snap_total packages"
        total_packages=$((total_packages + snap_total))
    fi
    
    if command -v flatpak &> /dev/null && flatpak list &> /dev/null; then
        local flatpak_total=$(flatpak list --app | wc -l)
        echo "  Flatpak: $flatpak_total packages"
        total_packages=$((total_packages + flatpak_total))
    fi
    
    if command -v cargo &> /dev/null; then
        local cargo_total=$(cargo install --list | grep -E "^[a-zA-Z]" | wc -l)
        echo "  Cargo: $cargo_total packages"
        total_packages=$((total_packages + cargo_total))
    fi
    
    if command -v pip3 &> /dev/null; then
        local pip_total=$(pip3 list 2>/dev/null | tail -n +3 | wc -l)
        echo "  Pip: $pip_total packages"
        total_packages=$((total_packages + pip_total))
    fi
    
    if command -v npm &> /dev/null; then
        local npm_total=$(npm list -g --depth=0 2>/dev/null | grep -E "├──|└──" | wc -l)
        echo "  NPM (global): $npm_total packages"
        total_packages=$((total_packages + npm_total))
    fi
    
    if [ "$appimage_count" -gt 0 ]; then
        echo "  AppImage: $appimage_count applications"
        total_packages=$((total_packages + appimage_count))
    fi
    
    if check_calibre_installed; then
        echo "  Calibre: 1 application"
        total_packages=$((total_packages + 1))
    fi
    
    echo "  ─────────────────────────────"
    echo "  Total: $total_packages packages/applications"
}

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -v, --version       Show script version and information"
    echo "      --simple        Simple update and upgrade only"
    echo "  -s, --stop          Interactive mode - ask user to continue after each step"
    echo "  -f, --full          Full upgrade including dist-upgrade (runs system_summary.sh first)"
    echo "  -c, --cleanup-only  Only perform cleanup operations"
    echo "  -l, --list          List all installed packages by package manager"
    echo "      --list-detailed List all installed packages with details"
    echo "  -q, --quiet         Quiet mode (less verbose output)"
    echo ""
    echo "Default behavior: update apt packages, update snap packages, update Rust packages, dpkg maintenance, update pip packages, update npm packages, check Calibre updates, upgrade, autoremove, and autoclean"
}

# Parse command line arguments
SIMPLE_MODE=false
FULL_MODE=false
CLEANUP_ONLY=false
QUIET_MODE=false
STOP_MODE=false
LIST_MODE=false
LIST_DETAILED=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        --simple)
            SIMPLE_MODE=true
            shift
            ;;
        -s|--stop)
            STOP_MODE=true
            shift
            ;;
        -f|--full)
            FULL_MODE=true
            shift
            ;;
        -c|--cleanup-only)
            CLEANUP_ONLY=true
            shift
            ;;
        -l|--list)
            LIST_MODE=true
            shift
            ;;
        --list-detailed)
            LIST_MODE=true
            LIST_DETAILED=true
            shift
            ;;
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Redirect output if quiet mode
if [ "$QUIET_MODE" = true ]; then
    exec > /dev/null 2>&1
fi

# Main execution
print_status "Starting comprehensive system update and package management script..."
echo "=========================================="

# Handle list mode
if [ "$LIST_MODE" = true ]; then
    print_status "Package listing mode activated"
    echo "=========================================="
    if [ "$LIST_DETAILED" = true ]; then
        list_all_packages --detailed
    else
        list_all_packages
    fi
    exit 0
fi

# Note: This script will prompt for sudo password when needed for system operations

# Execute system_summary.sh if full mode is enabled
if [ "$FULL_MODE" = true ]; then
    print_status "Full mode enabled - executing system_summary.sh first..."
    if [ -f "$(dirname "$0")/system_summary.sh" ]; then
        if bash "$(dirname "$0")/system_summary.sh"; then
            true # system_summary.sh completed successfully
        else
            print_warning "system_summary.sh execution failed, continuing with apt operations..."
        fi
    else
        print_warning "system_summary.sh not found in script directory, skipping..."
    fi
    ask_continue
fi

if [ "$CLEANUP_ONLY" = true ]; then
    print_status "Running in cleanup-only mode"
    cleanup
else
    # Check for broken packages first
    check_broken_packages
    # APT Package Manager Operations
    print_section_header "APT PACKAGE MANAGER"
    check_unattended_upgrades
    update_package_list
    upgrade_packages
    
    # DPKG Package Manager Operations
    print_section_header "DPKG PACKAGE MANAGER"
    maintain_dpkg_packages
    
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
    
    # Kitty Terminal Emulator Updates
    print_section_header "KITTY TERMINAL EMULATOR"
    check_kitty_update
    
    # Calibre Application Updates
    print_section_header "CALIBRE APPLICATION"
    check_calibre_update
    
    # System Upgrade Operations (only in full mode)
    if [ "$FULL_MODE" = true ]; then
        print_section_header "SYSTEM UPGRADE"
        full_upgrade
    fi
    
    # Cleanup unless in simple mode
    if [ "$SIMPLE_MODE" = false ]; then
        cleanup
    fi
fi

# Final status
echo "=========================================="
print_success "Comprehensive system update and package management script completed successfully!"

# Show summary of installed packages
print_status "Summary of installed packages:"
apt list --installed 2>/dev/null | wc -l | awk '{print "Total installed packages: " $1}'

# Check if reboot is required
if [ -f /var/run/reboot-required ]; then
    print_warning "A system reboot is required to complete the updates."
    echo "You can reboot now using: sudo reboot"
fi

exit 0