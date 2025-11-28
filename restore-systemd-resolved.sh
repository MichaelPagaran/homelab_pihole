#!/bin/bash

# --- systemd-resolved Restoration Script ---
# This script re-enables and starts the systemd-resolved service,
# reversing the changes made to free up port 53 for Pi-hole.

echo "Re-enabling and starting systemd-resolved service..."

# 1. Restore the symbolic link for /etc/resolv.conf
# This ensures systemd-resolved can manage the system's DNS settings.
echo "Restoring /etc/resolv.conf symlink managed by systemd-resolved..."
# Remove any existing file or link at /etc/resolv.conf
sudo rm -f /etc/resolv.conf 
# Create the necessary symbolic link
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

# 2. Re-enable the service to ensure it starts on boot
# This creates the necessary symlinks for the service.
echo "Enabling service..."
sudo systemctl enable systemd-resolved

# 3. Start the service immediately
echo "Starting service..."
sudo systemctl start systemd-resolved

echo "Service operations complete. Verifying status..."

# 4. Check the status to confirm it is active and running
systemctl status systemd-resolved | grep -E 'Active|Loaded|Listening'

echo ""
echo "systemd-resolved has been re-enabled and started."
echo "If the 'Active' line above shows 'active (running)', the restoration was successful."
echo "If you restart your system, the service should start automatically."
