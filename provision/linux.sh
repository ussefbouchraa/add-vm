
#!/usr/bin/env bash
# Configure network, service, storage, and packages.
set -e

echo "=== Linux setup started ==="

# 1. NETWORK
echo "--- Configuring network"

INTERFACE=$(ip route show default | awk '{print $5; exit}')

if [ -z "$INTERFACE" ]; then
    echo "ERROR: No network interface found"
    exit 1
fi

# Add the IP only if it is not already configured.
if ! ip addr show "$INTERFACE" | grep -q "10.0.2.15/24"; then
    ip addr add 10.0.2.15/24 dev "$INTERFACE"
fi

# Save the configuration for future boots.
mkdir -p /etc/network/interfaces.d

cat > /etc/network/interfaces.d/01-static <<EOF
auto $INTERFACE
iface $INTERFACE inet static
    address 10.0.2.15
    netmask 255.255.255.0
EOF


# 2. SYSTEMD SERVICE
echo "--- Installing heartbeat service"

# One file: the service writes a message every 10 seconds.
cat > /etc/systemd/system/heartbeat.service <<'EOF'
[Unit]
Description=Heartbeat logging service

[Service]
Type=simple
ExecStart=/bin/sh -c 'while true; do date >> /var/log/heartbeat.log; sleep 10; done'
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now heartbeat.service


# 3. STORAGE
echo "--- Configuring storage"

mkdir -p /data

# Make /var/tmp temporary, with a maximum size of 256 MB.
if ! grep -qE '^[[:space:]]*tmpfs[[:space:]]+/var/tmp[[:space:]]' /etc/fstab; then
    echo "tmpfs /var/tmp tmpfs defaults,size=256M,mode=1777 0 0" >> /etc/fstab
fi

mountpoint -q /var/tmp || mount /var/tmp


# 4. PACKAGES
echo "--- Installing packages"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y curl jq vim htop rsync


# FINISHED
echo "=== Linux setup complete ==="
systemctl --no-pager status heartbeat.service
