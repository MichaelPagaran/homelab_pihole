#!/bin/bash

# --- systemd-resolved Disabling Script ---
# This script stops and disables systemd-resolved to free up TCP/UDP port 53,
# which is required for running a local DNS server like Pi-hole.

echo "Stopping and disabling systemd-resolved service to free up port 53..."

# 1. Stop and Disable the service immediately
# Using 'disable --now' is a robust way to stop and disable in one command.
echo "Stopping and disabling service..."
if sudo systemctl disable --now systemd-resolved; then
    echo "Successfully stopped and disabled systemd-resolved."
else
    echo "Warning: Failed to stop/disable systemd-resolved. Attempting fallback stop."
    sudo systemctl stop systemd-resolved
fi

# 2. Modify /etc/resolv.conf to use an external DNS server (e.g., Google DNS)
# This is crucial so the host machine can still resolve names (like fetching Docker images)
# before Pi-hole is fully operational.
echo "Replacing /etc/resolv.conf symlink with a temporary DNS configuration..."

# Remove the symbolic link or file managed by systemd-resolved
sudo rm -f /etc/resolv.conf

# Create a new, static resolv.conf file
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

echo "Configuration complete. Verifying status..."

# 3. Verify that the service is inactive
if systemctl status systemd-resolved | grep -q 'Active: inactive'; then
    echo "SUCCESS: systemd-resolved is inactive."
else
    echo "WARNING: systemd-resolved might still be active or listening."
fi

echo ""
echo "Port 53 is now available for Pi-hole. The host is using 8.8.8.8 for DNS."
echo "Remember to run your 'restore_systemd_resolved.sh' script if you ever remove Pi-hole."
