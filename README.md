# Pi-hole Ad-Blocking Gateway Documentation

This document outlines the configuration and troubleshooting steps for the Homelab's ad-blocking DNS server using **Pi-hole in a Docker container**, managed by **OPNsense** on the 192.168.1.0/24 subnet.

## 1\. Network Topology Summary

| **Device** | **Role** | **IP Address (Static)** | **Operating System / Service** |
| **OPNsense VM** | Firewall/Router/DHCP Server | 192.168.1.1 | OPNsense |
| **Pi-hole Server VM** | Ad-Blocking DNS Server | 192.168.1.10 | Ubuntu / Docker |
| **Lubuntu Client VM** | Test Workstation | DHCP Assigned (e.g., 192.168.1.100) | Lubuntu |

The network flow is: **Client** \$\\rightarrow\$ **Pi-hole (DNS)** \$\\rightarrow\$ **OPNsense (Gateway)** \$\\rightarrow\$ **Internet.**

## 2\. Pi-hole Docker Configuration (docker-compose.yml)

The Pi-hole Docker container is configured to use the **Host Network Mode** to resolve complex port 53 (DNS) communication issues between the host server and the container. This bypasses Docker's internal NAT rules, which were causing connection timeouts from the client.

**Location:** /docker/pihole/docker-compose.yml
```yaml
version: "3"  
<br/>services:  
pihole:  
container_name: pihole  
image: pihole/pihole:latest  
\# CRITICAL FIX: Use host network mode to bypass Docker's internal NAT/Firewall  
network_mode: host  
hostname: pihole  
<br/>environment:  
\# CRITICAL: Set the Pi-hole's IP explicitly for DNS replies  
SERVERIP: 192.168.1.10  
TZ: \${TZ}  
WEBPASSWORD: \${WEBPASSWORD} # Password from .env file  
<br/>volumes:  
\- './etc-pihole:/etc/pihole'  
\- './etc-dnsmasq.d:/etc/dnsmasq.d'  
<br/>restart: unless-stopped  
cap_add:  
\- NET_ADMIN  
```

### Environment Variables (.env)

These variables are required to run the Pi-hole container:

| **Variable** | **Description** | **Example Value** |
| SERVERIP | The static IP of the Pi-hole Server host. | 192.168.1.10 |
| TZ  | The correct timezone. | America/Chicago |
| WEBPASSWORD | Password for the Pi-hole Web Interface. | YourSecretPassword |

## 3. OPNsense Firewall/DHCP Configuration

OPNsense must be configured to advertise the Pi-hole Server as the only DNS server for the LAN.

### DHCPv4

\$\$LAN\$\$

Configuration (Services > ISC DHCPv4 >

\$\$LAN\$\$

)

- **DNS servers:** Set to **192.168.1.10**
- **Gateway:** Set to **192.168.1.1** (This is the default for OPNsense)

This ensures all devices receiving a DHCP lease on the LAN are automatically instructed to use the Pi-hole for DNS lookups.

## 4\. Troubleshooting & Critical Fixes

The following steps were necessary to ensure end-to-end DNS functionality, particularly resolving the **communications error to 192.168.1.10#53: timed out** from the client.

### A. Pi-hole Server VM (192.168.1.10)

| **Issue** | **Resolution** | **Commands** |
| **Outbound Internet Access** | Confirmed the Pi-hole server itself could resolve and reach the internet. | ping 8.8.8.8 (Test IP) then ping cnn.com (Test DNS) |
| **Docker DNS Timeout** | Reconfigured docker-compose.yml to use network_mode: host to prevent the Docker NAT layer from blocking incoming DNS traffic on port 53. | sudo docker-compose down followed by sudo docker-compose up -d |
| **Host Firewall Block** | Verified the host firewall (UFW) was not interfering with the traffic reaching the Docker host. | sudo ufw status (Ensure Status: inactive) |

### B. Lubuntu Client VM (DHCP)

| **Issue** | **Resolution** | **Commands** |
| **Local DNS Stub Resolver** | The client's NetworkManager was using 127.0.0.53 (systemd-resolved) instead of the DHCP-assigned Pi-hole IP (192.168.1.10). This must be disabled for the client to work correctly. | 1\. sudo systemctl disable systemd-resolved 2. sudo systemctl stop systemd-resolved 3. sudo rm /etc/resolv.conf 4. \`echo "nameserver 192.168.1.10" |

## 5\. System Verification

After all configurations are complete and the Pi-hole container is running in host mode, verification should be performed on the **Lubuntu Client VM**.

| **Test** | **Purpose** | **Expected Result** |
| ping cnn.com | Confirms system-wide internet connectivity and successful Pi-hole resolution. | Successful ping replies. |
| dig doubleclick.net | Confirms Pi-hole's ad-blocking functionality is active. | Returns 192.168.1.10 or 0.0.0.0 as the resolved IP. |
| Access Pi-hole Dashboard | Confirms the web interface is accessible via the client. | **<http://192.168.1.10/admin>** loads successfully. |
