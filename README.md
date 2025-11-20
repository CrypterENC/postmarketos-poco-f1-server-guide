# PostmarketOS Setup Guide for Poco F1 as a Server

## Table of Contents
1. [Images](#images)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Driver Setup](#driver-setup)
   - [Post-Installation Configuration](#post-installation-configuration)
     - [1. Update System](#1-update-system)
     - [2. Change Device Hostname](#2-change-device-hostname)
     - [3. Create New User Account](#3-create-new-user-account)
    - [4. Enable SSH Server](#4-enable-ssh-server)
    - [5. Install and Set Up Docker](#5-install-and-set-up-docker)
    - [6. Set Up Firewall](#6-set-up-firewall)
    - [7. Set Up Monitoring with Prometheus and Grafana](#7-set-up-monitoring-with-prometheus-and-grafana)
5. [Hardware Setup](#hardware-setup)
   - [WiFi Driver Setup](#wifi-driver-setup)
     - [Check WiFi Status](#check-wifi-status)
     - [Connect to WiFi](#connect-to-wifi)
     - [Verify Connection](#verify-connection)
     - [WiFi Server Optimization (Power & Performance)](#wifi-server-optimization-power--performance)
   - [Bluetooth Driver Setup](#bluetooth-driver-setup)
   - [Audio Driver Setup](#audio-driver-setup)
   - [Camera and Sensors](#camera-and-sensors)
6. [Server Configuration](#server-configuration)
   - [1. Enable SSH Server](#1-enable-ssh-server)
   - [2. Install Web Server (Optional)](#2-install-web-server-optional)
   - [3. Install Database (Optional)](#3-install-database-optional)
   - [4. Install Node.js/Python (Optional)](#4-install-nodejspython-optional)
   - [4.2. Install Basic Development Tools](#42-install-basic-development-tools)
   - [4.5. Install and Set Up Docker (Optional)](#45-install-and-set-up-docker-optional)
   - [5. Set Up Firewall (Optional)](#5-set-up-firewall-optional)
     - [Recommended: UFW (Uncomplicated Firewall)](#recommended-ufw-uncomplicated-firewall)
     - [Alternatives](#alternatives)
   - [6. Enable Auto-Start Services](#6-enable-auto-start-services)
   - [7. Monitor System Resources](#7-monitor-system-resources)
   - [8. Set Up Static IP (Optional)](#8-set-up-static-ip-optional)
   - [9. Keep Screen Always On (Server Mode)](#9-keep-screen-always-on-server-mode)
7. [Troubleshooting](#troubleshooting)

## Images

### Screenshots


- **Node Monitoring Dashboard**: ![Grafana Dashboard](images/grafana_dashboard.jpg)
- **Docker Monitoring Dashboard**: ![Grafana Dashboard](images/grafana_dashboard.jpg)

---

## Prerequisites

### Hardware Requirements
- Xiaomi Poco F1 (xiaomi-beryllium)
- USB-C cable for connection to PC
- Charger (for power)
- SD card (optional, for testing)

### Software Requirements
- Linux PC or WSL (Windows Subsystem for Linux)
- `fastboot` and `adb` tools (Android SDK Platform Tools)
- `pmbootstrap` (for building from source, optional)
- Unlocked bootloader (follow [Xiaomi's official unlock process](https://en.miui.com/unlock/download_en.html))

### Important: Determine Panel Variant
Before installation, identify your display panel type (critical for kernel selection):

1. Boot into Android or TWRP recovery
2. Open terminal with root access:
   ```bash
   su
   cat /proc/cmdline
   ```
3. Look for `msm_drm.dsi_display0`:
   - `dsi_tianma_fhd_nt36672a_video_display` → **Tianma panel**
   - `dsi_ebbg_fhd_ft8719_video_display` → **EBBG panel**

---

## Installation

There are two main ways to install PostmarketOS on your Poco F1:

### Option 1: Building from Source with pmbootstrap

For a step-by-step video guide on building from source, watch: [PostmarketOS Installation Tutorial](https://www.youtube.com/watch?v=Rh0tA9-tVXE&t=422s)

#### Step 1: Install pmbootstrap
On Linux PC:
```bash
# Alpine Linux
sudo apk add pmbootstrap

# Debian/Ubuntu
pip install pmbootstrap

# Arch Linux
sudo pacman -S pmbootstrap
```

#### Step 2: Initialize pmbootstrap
```bash
pmbootstrap init
```

Respond to prompts:
- **Vendor**: `xiaomi`
- **Device**: `beryllium`
- **Kernel variant**: `tianma` or `ebbg` (based on your panel)
- **UI**: `console` (server) or `gnome-mobile` (desktop)
- **Branch**: `edge` (for latest drivers) or `master` (stable)
- **Additional options**: Enable FDE if desired (`--fde`)

#### Step 3: Build System
```bash
pmbootstrap install --filesystem f2fs
```

Note: `f2fs` is optimized for eMMC storage.

#### Step 4: Flash to Device
```bash
# Boot device into fastboot mode
sudo reboot bootloader

# Flash from pmbootstrap
pmbootstrap flasher flash_kernel
pmbootstrap flasher flash_rootfs --partition userdata
fastboot reboot
```

---

### Option 2: Using Prebuilt Images (Recommended for Beginners)

#### Step 1: Download Images
Download from [https://images.postmarketos.org](https://images.postmarketos.org):
- Select device: `xiaomi-beryllium`
- Select UI: `console` (for server) or `gnome-mobile` (for desktop)
- Select your panel variant (tianma or ebbg)
- Download both `-boot.img.xz` and `.img.xz` files

#### Step 2: Boot into Fastboot
On the device, run:
```bash
sudo reboot bootloader
```

Or manually: Power off → Hold Volume Down + Power until fastboot appears.

#### Step 3: Extract and Flash Images
On your PC:
```bash
# Extract boot image
unxz -v 20251107-1346-postmarketOS-v25.06-gnome-mobile-4-xiaomi-beryllium-tianma-boot.img.xz

# Extract system image
unxz -v 20251107-1346-postmarketOS-v25.06-gnome-mobile-4-xiaomi-beryllium-tianma.img.xz

# Erase existing data (optional but recommended)
fastboot erase userdata

# Flash boot image
fastboot flash boot 20251107-1346-postmarketOS-v25.06-gnome-mobile-4-xiaomi-beryllium-tianma-boot.img

# Flash system image
fastboot flash userdata 20251107-1346-postmarketOS-v25.06-gnome-mobile-4-xiaomi-beryllium-tianma.img

# Reboot
fastboot reboot
```

#### Step 4: Wait for Boot
The device will boot into PostmarketOS. First boot may take 2-5 minutes.

---

## Driver Setup

### Post-Installation Configuration

After PostmarketOS boots, connect via SSH or use the console:

```bash
# Default credentials (if set during install)
# User: user
# Password: (empty or set during install)
```

### 1. Update System
```bash
sudo apk update
sudo apk upgrade
```

### 2. Change Device Hostname
Customize the device name shown in prompts and SSH:

```bash
# Set new hostname (replace 'myserver' with your preferred name)
sudo hostnamectl set-hostname myserver

# Update /etc/hosts for consistency
sudo sed -i 's/xiaomi-beryllium/myserver/g' /etc/hosts

# Reboot to apply
sudo reboot
```

After reboot, your prompt will show `myserver:~$` instead of `xiaomi-beryllium:~$`.

### 3. Create New User Account
Change from the default "user" account to a custom username:

```bash
# Create new user (replace 'myuser' with your preferred name)
sudo adduser myuser

# Add to wheel group for sudo access
sudo addgroup myuser wheel

# Switch to new user
su - myuser

# Verify
whoami
```

**Note**: The default "user" account remains for backup. To remove it later: `sudo deluser user && sudo rm -rf /home/user`.

### 4. Enable SSH Server

#### Install SSH Server (if not present)
```bash
sudo apk add openssh
```

#### Check SSH Status
```bash
sudo systemctl status sshd
```

#### Start SSH
```bash
sudo systemctl start sshd
sudo systemctl enable sshd
```

#### Get Device IP
```bash
ip addr show
```

#### Connect from PC
```bash
ssh user@<DEVICE_IP>
```

**Troubleshooting SSH**: If `systemctl status sshd` shows "inactive (dead)", run `sudo systemctl start sshd` and `sudo systemctl enable sshd`.

### 5. Install and Set Up Docker
Run containers for applications:

```bash
# Install Docker
sudo apk add docker docker-cli docker-engine cgroup-tools

# Enable Docker
sudo systemctl enable --now docker

# Check Status
systemctl status docker

# Add user "idor" to the docker group
sudo addgroup idor docker

# Test Docker
docker run hello-world

# Restart session or run 'newgrp docker' to apply group changes
```

**Note**: Log out and back in after adding to docker group. For server use, manage containers with docker-compose. You may need to reboot later for group changes to take effect. If `newgrp docker` fails with "Operation not permitted", log out and back in instead.

### 6. Set Up Firewall

Set up a basic firewall using nftables to secure your server. This allows only necessary traffic and blocks unauthorized access.

1. **Install nftables**:
   ```bash
   doas apk add nftables
   ```

2. **Create the firewall rules file** (`/etc/nftables.conf`):
   ```bash
   #!/usr/sbin/nft -f

   table inet filter {
       chain input {
           type filter hook input priority 0;
           policy drop;

           # Allow loopback
           iif "lo" accept

           # Allow established connections
           ct state established,related accept

           # Allow SSH
           tcp dport 22 accept

           # Allow HTTP/HTTPS for web services
           tcp dport 80 accept
           tcp dport 443 accept

           # Allow Docker-related ports (e.g., for containers)
           tcp dport 8080 accept

           # Allow monitoring ports (add after setting up Prometheus/Grafana)
           # tcp dport 9090 accept  # Prometheus
           # tcp dport 9100 accept  # Node Exporter
           # tcp dport 3000 accept  # Grafana

           # Allow ping
           ip protocol icmp accept
       }

       chain forward {
           type filter hook forward priority 0;
           policy accept;
       }

       chain output {
           type filter hook output priority 0;
           policy accept;
       }
   }
   ```

3. **Apply the rules**:
   ```bash
   doas nft -f /etc/nftables.conf
   ```

4. **Enable nftables service**:
   ```bash
   doas systemctl enable nftables
   doas systemctl start nftables
   ```

5. **Verify the rules**:
   ```bash
   nft list ruleset
   ```

**Note**: Uncomment the monitoring ports after installing Prometheus and Grafana to allow access to those services. For Docker containers, add any additional ports as needed. This firewall drops all incoming traffic by default except what's explicitly allowed.

### 7. Set Up Monitoring with Prometheus and Grafana

For comprehensive monitoring of your server's performance, CPU, memory, storage, and Docker containers, install Prometheus, Node Exporter, Grafana, and optionally cAdvisor.

#### Install Monitoring Stack

1. **Download the deployment script** (from your project directory):
   ```bash
   wget https://raw.githubusercontent.com/your-repo/deploy-monitoring.sh -O deploy-monitoring.sh
   chmod +x deploy-monitoring.sh
   ```

2. **Run the script**:
   ```bash
   ./deploy-monitoring.sh
   ```

   This script will:
   - Update the system and enable the community repository
   - Install Prometheus (port 9090), Node Exporter (port 9100), and Grafana (port 3000)
   - Create systemd services for each
   - Configure Prometheus to scrape Node Exporter
   - Set up basic Grafana configuration

3. **Verify services are running**:
   ```bash
   doas systemctl status prometheus node-exporter grafana
   ```

#### Enable Container Monitoring (Optional, if using Docker)

If you have Docker containers (e.g., bots or applications), enable cAdvisor for dedicated container metrics monitoring:

1. **Run the enable script**:
   ```bash
   wget https://raw.githubusercontent.com/your-repo/enable-bot-monitoring.sh -O enable-bot-monitoring.sh
   chmod +x enable-bot-monitoring.sh
   ./enable-bot-monitoring.sh
   ```

   This will:
   - Ensure Docker is installed and running
   - Run cAdvisor in a container (port 8080)
   - Update Prometheus config to scrape cAdvisor

2. **Restart Prometheus**:
   ```bash
   doas systemctl restart prometheus
   ```

cAdvisor provides detailed metrics for each running container, including:
- CPU usage per container
- Memory usage and limits
- Network I/O
- Block I/O (disk usage)
- Container filesystem usage

3. **Import Container-Specific Dashboards**:
   - **Docker Dashboard (ID 193)**: Shows system and container metrics
   - **cAdvisor Dashboard (ID 14282)**: Dedicated container monitoring with graphs for CPU, memory, network, and disk I/O per container

4. **Monitor Specific Containers**:
   - In Grafana, filter dashboards by container name
   - Use Prometheus queries like `container_cpu_usage_seconds_total{container_label_com_docker_compose_service="your_service"}` for custom panels

5. **Container Logs and Health Checks**:
   - For logs: `docker logs <container_name>`
   - Add health checks in docker-compose.yml for automatic monitoring

#### Access Grafana

- **URL**: `http://<your-server-ip>:3000`
- **Default credentials**: Username: `admin`, Password: `admin`
- **Change password** on first login for security.

#### Set Up Dashboards

1. **Import Node Exporter Dashboard**:
   - In Grafana, go to Dashboards → Import
   - Enter ID: `1860` (Node Exporter Full)
   - Select Prometheus as data source

2. **Import Docker Dashboard (if using containers)**:
   - Import Dashboard ID: `193` (Docker and system monitoring)
   - Select Prometheus as data source

#### Firewall Configuration

Since you've set up nftables earlier, allow access to monitoring ports by uncommenting the lines in `/etc/nftables.conf`:

```bash
# Uncomment these lines in /etc/nftables.conf:
# tcp dport 9090 accept  # Prometheus
# tcp dport 9100 accept  # Node Exporter
# tcp dport 3000 accept  # Grafana
# tcp dport 8080 accept  # cAdvisor (if enabled, note: 8080 is already allowed for Docker)
```

Then reload the rules:
```bash
doas nft -f /etc/nftables.conf
```

If using UFW instead (alternative), allow the ports:
```bash
doas ufw allow 9090/tcp  # Prometheus
doas ufw allow 9100/tcp  # Node Exporter
doas ufw allow 3000/tcp  # Grafana
doas ufw allow 8080/tcp  # cAdvisor (if enabled)
```

#### Troubleshooting Monitoring

- **Services not starting**: Check logs with `journalctl -u <service-name>`
- **Grafana not accessible**: Verify IP and port with `ss -tuln | grep 3000`
- **Prometheus not scraping**: Check config at `/etc/prometheus/prometheus.yml` and restart

---

## 4. Hardware Setup

### WiFi Driver Setup

### Bluetooth Driver Setup

#### Install Bluetooth Tools
```bash
sudo apk add bluez
```

#### Enable Bluetooth Service
```bash
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
```

#### Pair Bluetooth Devices
```bash
bluetoothctl
```

### Audio Driver Setup

### Camera and Sensors

---

## 5. Server Configuration

### 1. Enable SSH Server

#### Install SSH Server (if not present)
```bash
sudo apk add openssh
```

#### Check SSH Status
```bash
sudo systemctl status sshd
```

#### Start SSH
```bash
sudo systemctl start sshd
sudo systemctl enable sshd
```

#### Get Device IP
```bash
ip addr show
```

#### Connect from PC
```bash
ssh user@<DEVICE_IP>
```

**Troubleshooting SSH**: If `systemctl status sshd` shows "inactive (dead)", run `sudo systemctl start sshd` and `sudo systemctl enable sshd`.

### 2. Install Web Server (Optional)

#### Install Nginx
```bash
sudo apk add nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### Configure Nginx
Edit `/etc/nginx/nginx.conf` and set root directory:
```nginx
server {
    listen 80 default_server;
    server_name _;
    root /var/www/html;
    index index.html;
}
```

#### Verify
```bash
curl http://localhost
```

### 3. Install Database (Optional)

#### SQLite (Lightweight)
```bash
sudo apk add sqlite
```

#### PostgreSQL
```bash
sudo apk add postgresql postgresql-client
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 4. Install Node.js/Python (Optional)

#### Node.js
```bash
sudo apk add nodejs npm
```

#### Python
```bash
sudo apk add python3 py3-pip
```

### 4.2. Install Basic Development Tools

For development and building software on your server, install essential tools like Git, Make, and compilers.

```bash
doas apk add git make gcc musl-dev build-base cmake autoconf automake libtool pkgconfig
```

**Common tools included**:
- `git`: Version control
- `make`: Build automation
- `gcc`: C/C++ compiler
- `musl-dev`: Development headers for musl libc
- `build-base`: Meta-package for build tools
- `cmake`: Cross-platform build system
- `autoconf/automake`: Build configuration tools
- `libtool`: Generic library support
- `pkgconfig`: Package configuration

**Additional tools as needed**:
- For Rust: `doas apk add rust cargo`
- For Go: `doas apk add go`
- For text editors: `doas apk add vim nano`
- For networking tools: `doas apk add curl wget openssh-client`

### 4.5. Install and Set Up Docker (Optional)
Run containers for applications:

```bash
# Install Docker
sudo apk add docker

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (run without sudo)
sudo addgroup $USER docker

# Test Docker
docker run hello-world

# Restart session or run 'newgrp docker' to apply group changes
```

**Note**: Log out and back in after adding to docker group. For server use, manage containers with docker-compose.

### 5. Set Up Firewall (Optional)

#### Recommended: UFW (Uncomplicated Firewall)
UFW is the best choice for most users—simple, user-friendly, and secure for servers. It's a front-end for iptables.

```bash
# Install UFW
sudo apk add ufw

# Start and enable
sudo systemctl start ufw
sudo systemctl enable ufw

# Allow essential services (SSH, HTTP, HTTPS)
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS

# Enable firewall (deny all by default, allow specified)
sudo ufw enable

# Check status
sudo ufw status
```

**Why UFW?** Easy to configure, prevents accidental misconfigurations, ideal for servers.

#### Alternatives
- **iptables**: Direct control (advanced users). More powerful but error-prone.
  ```bash
  sudo apk add iptables
  # Manual rules: iptables -A INPUT -p tcp --dport 22 -j ACCEPT
  ```

- **nftables**: Modern replacement for iptables (better performance).
  ```bash
  sudo apk add nftables
  # Use nft commands for rules
  ```

For a beginner server setup, stick with UFW. Always test rules before enabling!

### 6. Enable Auto-Start Services

#### systemd
```bash
sudo systemctl enable sshd
sudo systemctl enable nginx
sudo systemctl enable postgresql
```

### 7. Monitor System Resources

#### Install htop
```bash
sudo apk add htop
htop
```

#### Check Storage
```bash
df -h
du -sh /home/*
```

#### Check Temperature
```bash
cat /sys/class/thermal/thermal_zone0/temp
```

### 8. Set Up Static IP (Optional)
For consistent server access, set a static IP:

```bash
# Get current connection name
nmcli connection show

# Set static IP (replace <CONNECTION> with your WiFi name, e.g., "MyWiFi")
sudo nmcli connection modify "<CONNECTION>" ipv4.method manual ipv4.addresses "192.168.1.100/24" ipv4.gateway "192.168.1.1" ipv4.dns "8.8.8.8"

# Restart connection
sudo nmcli connection down "<CONNECTION>"
sudo nmcli connection up "<CONNECTION>"

# Verify
ip addr show
```

### 9. Keep Screen Always On (Server Mode)
For server use, prevent screen from turning off or blanking:

#### GNOME Mobile (Graphical)
```bash
# Install dconf if needed (for gsettings)
sudo apk add dconf

# Disable idle delay (screen off after inactivity)
gsettings set org.gnome.desktop.session idle-delay 0

# Disable screensaver
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
gsettings set org.gnome.desktop.screensaver lock-enabled false

# Disable power button suspend
gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'nothing'

# Alternative: Use dconf directly
dconf write /org/gnome/desktop/session/idle-delay 0
dconf write /org/gnome/desktop/screensaver/idle-activation-enabled false
```

**Note**: Run gsettings as regular user (not sudo). If not found, install `dconf`.

#### Console/Terminal
```bash
# Disable screen blanking
setterm -blank 0

# Or add to ~/.bashrc
echo "setterm -blank 0" >> ~/.bashrc
```

#### System-wide (DPMS)
```bash
# Disable DPMS (monitor power management)
xset -dpms
xset s off
```

**Note**: For headless server, consider running without display (`systemctl set-default multi-user.target`), but if you need the screen, use these settings.

### WiFi Not Connecting

1. Check driver:
   ```bash
   lsmod | grep wlan
   ```

2. Restart network manager:
   ```bash
   sudo systemctl restart NetworkManager
   ```

3. Check logs:
   ```bash
   dmesg | grep -i wifi
   ```

### Bluetooth Disconnects

1. Restart Bluetooth service:
   ```bash
   sudo systemctl restart bluetooth
   ```

2. Check logs:
   ```bash
   journalctl -u bluetooth -n 50
   ```

3. Re-pair device:
   ```bash
   bluetoothctl
   > remove <MAC_ADDRESS>
   > pair <MAC_ADDRESS>
   ```

### Slow Charging

This is a known limitation. Workarounds:
- Use EDL mode for faster offline charging
- Keep device plugged in longer
- Reduce power consumption (disable WiFi/Bluetooth when not needed)

### SSH Connection Issues

1. Check SSH is running:
   ```bash
   ps aux | grep sshd
   ```

2. Check firewall:
   ```bash
   sudo ufw status
   ```

3. Restart SSH:
   ```bash
   sudo systemctl restart sshd
   ```

### Device Won't Boot

1. Try recovery mode: Power off → Hold Volume Up + Power
2. Reflash bootloader (see PostmarketOS wiki)
3. Use EDL mode to restore

---

## Useful Commands

### System Info
```bash
uname -a
cat /etc/os-release
cat /proc/cpuinfo
```

### Network
```bash
ip addr show
ip route show
ss -tuln  # Open ports
```

### Processes
```bash
ps aux
top
htop
```

### Logs
```bash
dmesg
journalctl -n 50
```

### Power Management
```bash
sudo poweroff
sudo reboot
sudo reboot bootloader
```

---

## References

- [PostmarketOS Wiki - Poco F1](https://wiki.postmarketos.org/wiki/Xiaomi_Poco_F1_(xiaomi-beryllium))
- [PostmarketOS Documentation](https://docs.postmarketos.org/)
- [pmbootstrap Guide](https://docs.postmarketos.org/pmbootstrap/)
- [Xiaomi Unlock Process](https://en.miui.com/unlock/download_en.html)
- [LineageOS Poco F1 Wiki](https://wiki.lineageos.org/devices/beryllium/)

---

## Notes

- **First Boot**: May take 5-10 minutes. Be patient.
- **Storage**: Use `f2fs` filesystem for better eMMC performance.
- **Charging**: Limited to ~190mA; full fast charging requires kernel updates.
- **Sensors**: Not fully supported; requires SLPI driver development.
- **Updates**: Regularly run `apk upgrade` for latest drivers and security patches.

---

**Last Updated**: November 2025
**Device**: Xiaomi Poco F1 (xiaomi-beryllium)
**PostmarketOS Version**: v25.06+
