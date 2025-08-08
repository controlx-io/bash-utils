#!/bin/bash

# ==============================================================================
# pm2alt - A simple pm2-like wrapper for systemd
# v4: Changed 'logs' to 'log'
# ==============================================================================

# --- Color Definitions ---
C_RESET='\033[0m'
C_BRIGHT='\033[1m'
C_CYAN='\033[0;36m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_RED='\033[0;31m'

# --- Helper Functions ---
function usage() {
    echo -e "${C_BRIGHT}pm2alt - A simple process manager using systemd.${C_RESET}"
    echo
    echo -e "${C_YELLOW}USAGE:${C_RESET}"
    echo "  pm2alt <command> [options]"
    echo
    echo -e "${C_YELLOW}COMMANDS:${C_RESET}"
    echo -e "  ${C_GREEN}start${C_RESET}    (sudo) Start a new application service."
    echo -e "  ${C_GREEN}stop${C_RESET}     (sudo) Stop and disable an application service."
    echo -e "  ${C_GREEN}restart${C_RESET}  (sudo) Restart an application service."
    echo -e "  ${C_GREEN}status${C_RESET}   Display the status of a service."
    echo -e "  ${C_GREEN}log${C_RESET}     View the live logs of a service."
    echo
    echo -e "${C_YELLOW}EXAMPLE:${C_RESET}"
    echo "  sudo pm2alt start -n my-api -s \"deno run --allow-net main.ts\" -u username -w /home/username/my-api"
    echo "  pm2alt status my-api"
    exit 1
}

COMMAND="$1"
# --- Handle non-sudo commands first ---
case "$COMMAND" in
    status)
        SERVICE_NAME="$2"
        if [ -z "$SERVICE_NAME" ]; then echo -e "${C_RED}Error: Service name is required.${C_RESET}"; usage; fi
        systemctl status "${SERVICE_NAME}.service" --no-pager
        exit 0
        ;;
    log)
        SERVICE_NAME="$2"
        if [ -z "$SERVICE_NAME" ]; then echo -e "${C_RED}Error: Service name is required.${C_RESET}"; usage; fi
        journalctl -u "${SERVICE_NAME}.service" -f
        exit 0
        ;;
esac

# --- Check for root privileges for all modifying commands ---
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${C_RED}Error: Command '${COMMAND}' must be run as root or with sudo.${C_RESET}"
    exit 1
fi

# --- Handle sudo-required commands ---
shift # Shift arguments to the left
case "$COMMAND" in
    start)
        RUN_USER="nodeapp"
        WORKING_DIR="$(pwd)"
        SERVICE_NAME=""
        EXEC_START=""

        while [[ "$#" -gt 0 ]]; do
            case $1 in
                -n|--name) SERVICE_NAME="$2"; shift ;;
                -s|--script) EXEC_START="$2"; shift ;;
                -u|--user) RUN_USER="$2"; shift ;;
                -w|--cwd) WORKING_DIR="$2"; shift ;;
                *) echo "Unknown parameter passed: $1"; usage ;;
            esac
            shift
        done

        if [ -z "$SERVICE_NAME" ] || [ -z "$EXEC_START" ]; then
            echo -e "${C_RED}Error: --name and --script are required for the start command.${C_RESET}"; usage;
        fi

        EXECUTABLE=$(echo "$EXEC_START" | awk '{print $1}')
        ARGS=$(echo "$EXEC_START" | cut -d' ' -f2-)

        if [[ "$EXECUTABLE" != /* ]]; then
            FULL_PATH_EXEC=$(command -v "$EXECUTABLE")
            if [ -n "$FULL_PATH_EXEC" ]; then
                EXEC_START="${FULL_PATH_EXEC} ${ARGS}"
            else
                echo -e "${C_YELLOW}Warning: Could not find full path for '${EXECUTABLE}'. The service may fail.${C_RESET}"
            fi
        fi

        SERVICE_FILE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
        echo -e "\n${C_CYAN}Creating service file: ${SERVICE_FILE_PATH}${C_RESET}"

        # --- Create the service file ---
        tee "$SERVICE_FILE_PATH" > /dev/null <<EOF
[Unit]
Description=${SERVICE_NAME} - Managed by pm2alt
After=network.target
[Service]
User=${RUN_USER}
Group=${RUN_USER}
WorkingDirectory=${WORKING_DIR}
ExecStart=${EXEC_START}
Restart=on-failure
RestartSec=10s
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SERVICE_NAME}
[Install]
WantedBy=multi-user.target
EOF

        echo -e "${C_GREEN}✔ Service file created.${C_RESET}"
        systemctl daemon-reload
        echo "Enabling service '${SERVICE_NAME}' to start on boot..."
        systemctl enable "${SERVICE_NAME}.service"
        echo "Starting service '${SERVICE_NAME}'..."
        systemctl start "${SERVICE_NAME}.service"
        echo -e "\n${C_GREEN}✔ Service started successfully.${C_RESET}"
        systemctl status "${SERVICE_NAME}.service" --no-pager
        ;;

    stop)
        SERVICE_NAME="$1"
        if [ -z "$SERVICE_NAME" ]; then echo -e "${C_RED}Error: Service name is required.${C_RESET}"; usage; fi

        systemctl stop "${SERVICE_NAME}.service"
        systemctl disable "${SERVICE_NAME}.service"

        SERVICE_FILE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
        if [ -f "$SERVICE_FILE_PATH" ]; then
            read -p "Do you want to delete the service file? [y/N]: " confirm
            if [[ "$confirm" =~ ^[yY](es)?$ ]]; then
                rm "$SERVICE_FILE_PATH"
                systemctl daemon-reload
                echo "Service file deleted."
            fi
        fi
        echo -e "${C_GREEN}✔ Service '${SERVICE_NAME}' has been stopped and disabled.${C_RESET}"
        ;;

    restart)
        SERVICE_NAME="$1"
        if [ -z "$SERVICE_NAME" ]; then echo -e "${C_RED}Error: Service name is required.${C_RESET}"; usage; fi
        systemctl restart "${SERVICE_NAME}.service"
        echo -e "${C_GREEN}✔ Service restarted.${C_RESET}"
        systemctl status "${SERVICE_NAME}.service" --no-pager
        ;;

    *)
        usage
        ;;
esac
