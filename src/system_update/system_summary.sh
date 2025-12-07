#!/bin/bash

# Color codes for consistent formatting (following system_update.sh standards)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

[ -f "~/.bashrc" ] && source "~/.bashrc"

# Utility function for section headers (Tier 1 - Package Manager Header style)
print_section_header() {
    local title="$1"
    echo -e "\n\033[37;44m$(printf "%*s" $(((80 + ${#title}) / 2)) "$title")$(printf "%*s" $(((80 - ${#title}) / 2)) "")${NC}"
}

# Utility function for main operation headers (Tier 2 - Bold blue)
print_operation_header() {
    echo -e "\n${BLUE}\033[1m$1\033[0m"
}

# Utility function for sub-step headers (Tier 3 - Regular white)
print_substep() {
    echo -e "${WHITE}$1${NC}"
}

# Main header following interface documentation standards
print_section_header "💻 SYSTEM INFORMATION SUMMARY"

print_operation_header "🐧 Operating System and Distribution Information"

if [ -f /etc/os-release ]; then
  source /etc/os-release
  
  # Create formatted table output for OS information
  echo -e "\n┌─────────────────────────────────────────────────────────────────────────────┐"
  echo -e "│                      OPERATING SYSTEM INFORMATION                          │"
  echo -e "├─────────────────────────────────────────────────────────────────────────────┤"
  printf "│ %-31s │ %-41s │\n" "📋 Distribution" "$NAME"
  printf "│ %-31s │ %-41s │\n" "📅 Version" "$VERSION"
  printf "│ %-31s │ %-41s │\n" "🆔 System ID" "$ID"
  printf "│ %-31s │ %-41s │\n" "🐧 Kernel Version" "$(uname -r)"
  printf "│ %-31s │ %-41s │\n" "⚙️  Kernel Architecture" "$(uname -m)"
  echo -e "└─────────────────────────────────────────────────────────────────────────────┘"
  
  # Additional distribution details if available
  if command -v lsb_release >/dev/null 2>&1; then
      print_substep "📋 Additional Distribution Details:"
      lsb_release -a 2>/dev/null | while read line; do
          if [ -n "$line" ]; then
              print_substep "  $line"
          fi
      done
  fi
  
  echo -e "${GREEN}✅${NC} Operating system and distribution information retrieved successfully"
else
  echo -e "${YELLOW}⚠️  [WARNING]${NC} Could not find /etc/os-release. Trying alternative methods..."
  
  # Fallback to lsb_release if os-release is not available
  if command -v lsb_release >/dev/null 2>&1; then
      print_substep "📋 Distribution Information (from lsb_release):"
      lsb_release -a 2>/dev/null | while read line; do
          if [ -n "$line" ]; then
              print_substep "  $line"
          fi
      done
      echo -e "${GREEN}✅${NC} Distribution information retrieved via lsb_release"
  else
      echo -e "${YELLOW}⚠️  [WARNING]${NC} Neither /etc/os-release nor lsb_release available"
  fi
fi

termux=$TERMUX_VERSION

print_operation_header "💾 Storage and File System Information"

# Create formatted table output following interface documentation standards
echo -e "\n┌─────────────────────────────────────────────────────────────────────────────┐"
echo -e "│                           DISK USAGE SUMMARY                                  │"
echo -e "├─────────────────────────────────────────────────────────────────────────────┤"
df -h -T | grep -E '^(/dev/|Filesystem)' | while read -r line; do
    echo -e "│ $line" | awk '{printf "%-75s", $0}' && echo " │"
done
echo -e "└─────────────────────────────────────────────────────────────────────────────┘"
echo -e "${GREEN}✅${NC} File system information retrieved successfully"

print_operation_header "🧠 Memory and System Resources"

# Enhanced memory information display
memory_info=$(free -h | awk '/^Mem/ {printf "Used: %s / Total: %s (%.1f%% utilization)", $3, $2, ($3/$2)*100}')
print_substep "📊 Memory Status: $memory_info"
echo -e "${GREEN}✅${NC} Memory information analyzed successfully"

print_operation_header "⚙️  System Environment"

print_substep "🖥️  Terminal Environment: $TERM"
print_substep "🛤️  System PATH: $PATH"
echo -e "${GREEN}✅${NC} System environment information collected"

if [ -n "$termux" ]; then
    print_operation_header "📱 Termux Mobile Environment"
    print_substep "� Analyzing Termux-specific configuration..."
    print_substep "�📱 Termux Version: $TERMUX_VERSION"
    echo -e "${GREEN}✅${NC} Termux environment information collected"
else
    print_operation_header "🌐 Network Configuration"
    
    ipv4_address=$(ip -4 addr | grep wlp | grep inet | awk '{print $2}' | cut -d/ -f1)
    if [ -n "$ipv4_address" ]; then
        print_substep "📡 IPv4 Address: $ipv4_address"
        echo -e "${GREEN}✅${NC} Network information retrieved successfully"
    else
        echo -e "${YELLOW}⚠️  [WARNING]${NC} Could not detect wireless network interface"
    fi
    
    # Continuation prompt to avoid scrolling
    echo -e "\n${CYAN}Press any key to continue...${NC}"
    read -r -n 1 -s

    
    print_operation_header "📦 Package Management System"
    
    package_managers_found=0
    total_packages=0
    
    # Generate package manager data and format with awk
    {
        echo "PackageManager Status Packages"
        
        # APT Package Manager
        if command -v apt >/dev/null 2>&1; then
            if command -v dpkg >/dev/null 2>&1; then
                apt_count=$(dpkg -l | grep "^ii" | wc -l)
                echo "APT_(Advanced_Package_Tool) Available $apt_count"
                total_packages=$((total_packages + apt_count))
            else
                echo "APT_(Advanced_Package_Tool) Available N/A"
            fi
            package_managers_found=$((package_managers_found + 1))
        else
            echo "APT_(Advanced_Package_Tool) Not_available N/A"
        fi
        
        # Snap Package Manager
        if command -v snap >/dev/null 2>&1 && snap list &>/dev/null; then
            snap_count=$(snap list | tail -n +2 | wc -l)
            echo "Snap_(Universal_packages) Available $snap_count"
            total_packages=$((total_packages + snap_count))
            package_managers_found=$((package_managers_found + 1))
        else
            echo "Snap_(Universal_packages) Not_available N/A"
        fi
        
        # Python pip
        if command -v pip3 >/dev/null 2>&1; then
            pip_count=$(pip3 list 2>/dev/null | tail -n +3 | wc -l)
            echo "pip_(Python_Package_Installer) Available $pip_count"
            total_packages=$((total_packages + pip_count))
            package_managers_found=$((package_managers_found + 1))
        else
            echo "pip_(Python_Package_Installer) Not_available N/A"
        fi
        
        # Node.js npm
        if command -v npm >/dev/null 2>&1; then
            npm_count=$(npm list -g --depth=0 2>/dev/null | grep -E "├──|└──" | wc -l)
            echo "npm_(Node_Package_Manager) Available ${npm_count}_global"
            total_packages=$((total_packages + npm_count))
            package_managers_found=$((package_managers_found + 1))
        else
            echo "npm_(Node_Package_Manager) Not_available N/A"
        fi
        
        # Rust Cargo
        if command -v cargo >/dev/null 2>&1; then
            cargo_count=$(cargo install --list 2>/dev/null | grep -E "^[a-zA-Z]" | wc -l)
            echo "Cargo_(Rust_Package_Manager) Available $cargo_count"
            total_packages=$((total_packages + cargo_count))
            package_managers_found=$((package_managers_found + 1))
        else
            echo "Cargo_(Rust_Package_Manager) Not_available N/A"
        fi
        
        echo "SUMMARY $package_managers_found $total_packages"
        
    } | awk '
    NR > 1 && $1 != "SUMMARY" {
        # Clean up package manager names (replace underscores with spaces)
        manager = $1
        gsub(/_/, " ", manager)
        
        # Format package count with emoji and varied terminology
        if ($3 == "N/A") {
            packages = "📊 N/A items"
        } else if ($3 ~ /_global$/) {
            gsub(/_global/, "", $3)
            packages = "📊 " $3 " global items"
        } else {
            # Use varied terminology based on package manager
            if (manager ~ /^APT/) {
                packages = "📊 " $3 " packages"
            } else if (manager ~ /^Snap/) {
                packages = "📊 " $3 " snaps"
            } else if (manager ~ /^pip/) {
                packages = "📊 " $3 " modules"
            } else if (manager ~ /^npm/) {
                packages = "📊 " $3 " global libraries"
            } else if (manager ~ /^Cargo/) {
                packages = "📊 " $3 " crates"
            } else {
                packages = "📊 " $3 " items"
            }
        }
        
        # Use tab separators for column -t formatting (removed status column)
        print manager "\t" packages
    }
    $1 == "SUMMARY" {
        print "─────────────────────────────────────────────────────────────────────────────"
        print "Summary: " $2 " managers available\tTotal: " $3 " packages"
    }
    ' | {
        echo -e "\n┌─────────────────────────────────────────────────────────────────────────────┐"
        echo -e "│                       PACKAGE MANAGER SUMMARY                              │"
        echo -e "├─────────────────────────────────┬───────────────────────────────────────────┤"
        echo -e "│ Package Manager                 │ Items Installed                           │"
        echo -e "├─────────────────────────────────┼───────────────────────────────────────────┤"
        
        # Process the AWK output with proper column formatting
        while IFS=$'\t' read -r manager packages; do
            if [[ "$manager" == "─"* ]]; then
                echo -e "├─────────────────────────────────┴───────────────────────────────────────────┤"
            elif [[ "$manager" == "Summary:"* ]]; then
                printf "│ %-75s │\n" "$manager $packages"
            else
                # Format each line as table row with fixed column widths
                printf "│ %-31s │ %-41s │\n" "$manager" "$packages"
            fi
        done
        
        echo -e "└─────────────────────────────────────────────────────────────────────────────┘"
    }
    echo -e "${GREEN}✅${NC} Package manager analysis completed"
    
    
    print_operation_header "⏰ System Runtime and Performance"
    uptime_info=$(uptime)
    print_substep "⏱️  System Status: $uptime_info"
    
    print_substep "🔐 User identification and permissions..."
    user_id=$(id -u)
    group_id=$(id -g)
    print_substep "👤 User Context: UID=$user_id, GID=$group_id"
    echo -e "${GREEN}✅${NC} System runtime analysis completed"
    
    print_operation_header "💾 APT Cache Storage Analysis"
    
    # Show disk usage for APT cache directory
    apt_cache_usage=$(du -sh /var/cache/apt/archives/ 2>/dev/null | cut -f1)
    if [ -n "$apt_cache_usage" ]; then
        print_substep "💽 Disk usage in /var/cache/apt/archives/: $apt_cache_usage"
        echo -e "${GREEN}✅${NC} APT cache storage information retrieved successfully"
    else
        echo -e "${YELLOW}⚠️  [WARNING]${NC} Could not access APT cache directory"
    fi
fi

# Final summary following interface documentation standards
print_section_header "📋 SYSTEM ANALYSIS COMPLETE"
