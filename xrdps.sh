#!/bin/bash

# Tool name
tool_name="xrdps"

# Color codes for output (consider using a more portable method like tput)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions (unified logging with level)
log() {
    local level="$1"
    local message="$2"
    local color=""

    case "$level" in
        INFO)  color="$GREEN";;
        WARN)  color="$YELLOW";;
        ERROR) color="$RED";;
        *)     color="";; #Default to no color
    esac

    echo -e "${color}[${level}]${NC} $message" >&2
}

# Install script
install() {
  install_dir="/usr/local/bin"
  if ! sudo mkdir -p "$install_dir" 2>/dev/null || ! sudo chown "$USER":"$USER" "$install_dir"; then
    log ERROR "Error creating directory $install_dir. Ensure you have sudo privileges."
    exit 1
  fi
  install_path="$install_dir/$tool_name"
  if ! sudo cp "$0" "$install_path" || ! sudo chmod +x "$install_path"; then
      log ERROR "Error installing $tool_name. Ensure you have sudo privileges."
      exit 1
  fi
  log INFO "$tool_name installed to $install_path."
}

# Uninstall script
uninstall() {
  uninstall_path="/usr/local/bin/$tool_name"
  if [[ -f "$uninstall_path" ]]; then
    if ! sudo rm "$uninstall_path"; then
      log ERROR "Error uninstalling $tool_name. Ensure you have sudo privileges."
      exit 1
    fi
    log INFO "$tool_name successfully uninstalled."
  else
    log WARN "$tool_name is not installed in /usr/local/bin."
  fi
}

# Function to install and configure XRDP for the current user
setup_xrdp() {

  log INFO "Updating package list..."
  if ! sudo apt update -y; then
      log ERROR "Failed to update package list."
      exit 1
  fi

  log INFO "Installing XRDP and XFCE..."
  if ! sudo apt install -y xrdp xfce4 xfce4-goodies; then
      log ERROR "Failed to install XRDP and XFCE."
      exit 1
  fi

  log INFO "Enabling and starting the XRDP service..."
  if ! sudo systemctl enable xrdp --now || ! sudo systemctl is-active xrdp; then
      log ERROR "Failed to enable/start XRDP service."
      exit 1
  fi

  log INFO "Creating XFCE session for $USER..."
  if ! sudo sh -c "echo 'xfce4-session' > /home/$USER/.xsession" || ! sudo chown "$USER":"$USER" "/home/$USER/.xsession"; then
      log ERROR "Failed to create XFCE session. Please manually create /home/$USER/.xsession and add the line 'xfce4-session'."
      exit 1
  fi

  log INFO "Checking XRDP status..."
  status=$(sudo systemctl status xrdp | grep 'Active: ')
  log INFO "XRDP daemon is: ${status##*Active: }"

  log INFO "XRDP setup is complete for user $USER. You can now connect to this machine via RDP using the IP address and username '$USER'."

  # Client-side instruction
  echo "To connect remotely:"
  echo "1. **Find your VM's address.** You can usually find this in your cloud provider's control panel or by running 'ip addr show' on the VM. For Tailscale use 'tailscale ip'."
  echo "2. **Install a Remote Desktop Client:**"
  echo "   * **Windows:** Download the Microsoft Remote Desktop app from the Microsoft Store: [https://apps.microsoft.com/store/detail/microsoft-remote-desktop/9WZDNCRFJ3PS](https://apps.microsoft.com/store/detail/microsoft-remote-desktop/9WZDNCRFJ3PS)"
  echo "   * **macOS:** Download the Microsoft Remote Desktop app from the Mac App Store: [https://apps.apple.com/ca/app/microsoft-remote-desktop/id1295203466](https://apps.apple.com/ca/app/microsoft-remote-desktop/id1295203466)"
  echo "   * **Linux:** Use a client like Remmina: [https://remmina.org/](https://remmina.org/)"
  echo "3. **Open the Remote Desktop Client and enter:**"
  echo "   * **Computer:** Your VM's address"
  echo "   * **Username:** $USER"
  echo "   * **Password:** Your user's password"
  echo "4. **Connect!** You should now be able to access your remote desktop."
}

interactive_menu() {
    log INFO "Entering interactive menu..."
    while true; do
        echo
        echo "What would you like to do?"
        echo "1. Set up XRDP"
        echo "2. Exit"
        read -p "Please enter your choice [1-2]: " choice

        case $choice in
            1)
                setup_xrdp
                log INFO "Setup for XRDP for $tool_name is complete. Exiting interactive menu..."
                break
                ;;
            2)
                log INFO "Exiting interactive menu..."
                break
                ;;
            *)
                log WARN "Invalid choice. Please enter a number between 1 and 2."
                ;;
        esac
    done
}

# Main execution
case "$1" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        interactive_menu
        ;;
esac