# === Auto-run Arch installer from /root ===
INSTALLER="./install.sh"

# Only try to run if the installer exists
if [[ -f "$INSTALLER" ]]; then
    # Make sure it is executable
    if [[ ! -x "$INSTALLER" ]]; then
        chmod +x "$INSTALLER"
    fi

    # Clear terminal for clean installer screen
    clear

    # Attempt to run installer
    "$INSTALLER"

    # Check if it ran successfully
    if [[ $? -ne 0 ]]; then
        echo "❌ Installer failed to run. Try manually:"
        echo "   chmod +x /root/install.sh && /root/install.sh"
    fi
else
    echo "❌ Installer script not found at $INSTALLER"
fi
