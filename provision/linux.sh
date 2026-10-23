#!/usr/bin/env bash
# Configure the Linux VM
set -e
echo "=== Linux setup started ==="

# 1. NETWORK
echo "--- Configuring network ---"
INTERFACE=$(ip route show default | awk '{print $5; exit}')
[ -z "$INTERFACE" ] && INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -vE '^(lo|tun|docker|veth)' | head -n1)
if ! ip addr show "$INTERFACE" | grep -q "10.0.2.15/24"; then
    ip addr add 10.0.2.15/24 dev "$INTERFACE" || true
fi
mkdir -p /etc/network/interfaces.d
cat > /etc/network/interfaces.d/01-static <<EOF
auto $INTERFACE
iface $INTERFACE inet static
    address 10.0.2.15
    netmask 255.255.255.0
EOF

# 2. TIME LOGGER SCRIPT
echo "--- Creating time logger ---"
cat > /usr/local/bin/time_logger.sh <<'EOF'
#!/bin/sh
while true; do
    date >> /var/log/time_logger.log
    sleep 10
done
EOF
chmod 755 /usr/local/bin/time_logger.sh
touch /var/log/time_logger.log

# 3. SYSTEMD SERVICE
echo "--- Configuring systemd service ---"
cat > /etc/systemd/system/time_logger.service <<'EOF'
[Unit]
Description=time_logger logging service
After=local-fs.target

[Service]
Type=simple
ExecStart=/usr/local/bin/time_logger.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now time_logger.service

# 4. STORAGE
echo "--- Configuring storage ---"
mkdir -p /data
if ! grep -qE '^[[:space:]]*tmpfs[[:space:]]+/var/tmp[[:space:]]' /etc/fstab; then
    echo "tmpfs /var/tmp tmpfs defaults,size=256M,mode=1777 0 0" >> /etc/fstab
fi
mountpoint -q /var/tmp || mount /var/tmp || true

# 5. PACKAGES
echo "--- Installing packages ---"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y curl jq vim htop rsync

echo "=== Linux setup completed successfully ==="
