#!/bin/bash

# --- systemd-resolved Disabling Script ---
# This script stops and disables systemd-resolved to free up TCP/UDP port 53,
# which is required for running a local DNS server like Pi-hole.

echo "Stopping and disabling systemd-resolved service to free up port 53..."

# 1. Stop the service immediately
echo "Stopping service..."
sudo systemctl stop systemd-resolved

# 2. Disable the service so it doesn't start on boot
echo "Disabling service..."
sudo systemctl disable systemd-resolved

# 3. Modify /etc/resolv.conf to use an external DNS server (e.g., Google DNS)
# This is crucial so the host machine can still resolve names (like fetching Docker images)
# before Pi-hole is fully operational.
echo "Replacing /etc/resolv.conf symlink with a temporary DNS configuration..."

# Remove the symbolic link managed by systemd-resolved
sudo rm -f /etc/resolv.conf

# Create a new, static resolv.conf file
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

echo "Service operations complete. Verifying status..."

# 4. Verify that the service is inactive
systemctl status systemd-resolved | grep -E 'Active|Loaded|Listening'

echo ""
echo "systemd-resolved has been stopped and disabled."
echo "Port 53 is now available for Pi-hole."
echo "Remember to run your 'restore_systemd_resolved.sh' script if you ever remove Pi-hole."
