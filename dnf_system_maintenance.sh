#!/usr/bin/env bash

# ============================================================
#        AUTOMATIC SYSTEM UPDATE & CLEANUP
# ============================================================

set -euo pipefail

# ---------- Colors ----------
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'
readonly RESET='\033[0m'
readonly BOLD='\033[1m'

# ---------- Helper Functions ----------
print_header() {
    local title="$1"
    local len=${#title}
    local pad=$(( (44 - len) / 2 ))
    local rpad=$(( 44 - len - pad ))
    local l_space="" r_space=""
    [[ $pad -gt 0 ]] && printf -v l_space '%*s' "$pad" ''
    [[ $rpad -gt 0 ]] && printf -v r_space '%*s' "$rpad" ''
    
    echo -e "\n${BLUE}${BOLD}┌────────────────────────────────────────────┐${RESET}"
    echo -e "${BLUE}${BOLD}│${l_space}${title}${r_space}│${RESET}"
    echo -e "${BLUE}${BOLD}└────────────────────────────────────────────┘${RESET}\n"
}

print_success() {
    echo -e "${GREEN}✔ $1${RESET}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${RESET}"
}

print_error() {
    echo -e "${RED}✖ $1${RESET}"
}

check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        if ! command -v sudo &> /dev/null; then
            print_error "Root privileges required, and 'sudo' is not installed."
            exit 1
        fi
        SUDO="sudo"
    else
        SUDO=""
    fi
}

run_command() {
    local cmd_name="$1"
    shift
    if "$@"; then
        print_success "$cmd_name completed successfully."
    else
        print_error "$cmd_name failed. Please check the system logs."
        exit 1
    fi
}

# ---------- Main Operations ----------

update_dnf() {
    if command -v dnf &> /dev/null; then
        print_header "Upgrading DNF Packages"
        run_command "DNF Upgrade" $SUDO dnf upgrade -y
        
        print_header "Removing Unused DNF Packages"
        run_command "DNF Autoremove" $SUDO dnf autoremove -y
        
        print_header "Cleaning DNF Cache"
        run_command "DNF Clean All" $SUDO dnf clean all
    fi
}

update_snap() {
    if command -v snap &> /dev/null; then
        print_header "Updating Snap Packages"
        run_command "Snap Refresh" $SUDO snap refresh
    fi
}

update_flatpak() {
    if command -v flatpak &> /dev/null; then
        print_header "Updating Flatpak Packages"
        run_command "Flatpak Update" flatpak update -y
        run_command "Flatpak Uninstall Unused" flatpak uninstall --unused -y
    fi
}

# ---------- Start ----------
main() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "╔════════════════════════════════════════════╗"
    echo "║        AUTOMATIC SYSTEM MAINTENANCE        ║"
    echo "╚════════════════════════════════════════════╝"
    echo -e "${RESET}"
    
    print_info "Started: $(date)"
    
    check_sudo
    
    update_dnf
    update_snap
    update_flatpak
    
    print_header "Maintenance Complete"
    echo -e "${GREEN}${BOLD}✔ System maintenance completed successfully!${RESET}\n"
    print_info "Finished: $(date)\n"
    
    read -rp "Press ENTER to clear the screen..."
    clear
}

main "$@"
