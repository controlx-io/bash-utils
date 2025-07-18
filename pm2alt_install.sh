#!/bin/bash

# ==============================================================================
# pm2alt_install.sh
# Downloads and installs the pm2alt script to /usr/local/bin.
#
# Usage:
#   curl -sL <URL_TO_THIS_SCRIPT> | sudo -E bash -
# ==============================================================================

# --- Configuration ---
# The URL to the raw pm2alt script on GitHub.
# IMPORTANT: Replace this with your actual raw GitHub URL.
SCRIPT_URL="https://raw.githubusercontent.com/controlx-io/bash-utils/refs/heads/main/pm2alt.sh"
INSTALL_PATH="/usr/local/bin/pm2alt"

# --- Color Definitions ---
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_RED='\033[0;31m'
C_YELLOW='\033[0;33m'

# --- Main Logic ---

# 1. Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${C_RED}Error: This installer must be run as root or with sudo.${C_RESET}"
    echo "Please run like this:"
    echo "curl -sL ... | sudo -E bash -"
    exit 1
fi

echo "Starting pm2alt installation..."

# 2. Download the script using curl
echo "Downloading script from ${SCRIPT_URL}..."
if ! curl -sL --fail "${SCRIPT_URL}" -o "${INSTALL_PATH}"; then
    echo -e "${C_RED}Error: Failed to download the script.${C_RESET}"
    echo "Please check the URL in the installer script and your internet connection."
    exit 1
fi

# 3. Make the script executable
echo "Setting execute permissions on ${INSTALL_PATH}..."
if ! chmod +x "${INSTALL_PATH}"; then
    echo -e "${C_RED}Error: Failed to set execute permissions.${C_RESET}"
    exit 1
fi

# 4. Final success message
echo
echo -e "${C_GREEN}✔ pm2alt was installed successfully!${C_RESET}"
echo
echo "You can now use it like this:"
echo -e "${C_YELLOW}sudo pm2alt start -n my-app -s \"deno run --allow-all main.ts\"${C_RESET}"
echo -e "${C_YELLOW}sudo pm2alt status my-app${C_RESET}"
echo -e "${C_YELLOW}sudo pm2alt logs my-app${C_RESET}"
echo -e "${C_YELLOW}sudo pm2alt stop my-app${C_RESET}"
