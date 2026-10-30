
#!/usr/bin/env bash
# Configure network, service, storage, and packages.
set -e

echo "=== Linux setup started ==="


# 1. NETWORK
echo "--- Configuring network"

INTERFACE="enp0s8"

# Save the configuration for future boots.
mkdir -p /etc/network/interfaces.d

cat > /etc/network/interfaces.d/01-static <<EOF
auto $INTERFACE
iface $INTERFACE inet static
    address 192.168.56.10
    netmask 255.255.255.0
EOF


# 2. SYSTEMD SERVICE
echo "--- Installing time_logger service"

# One file: the service writes a message every 10 seconds.
cat > /etc/systemd/system/time_logger.service <<'EOF'
[Unit]
Description=time_logger logging service

[Service]
Type=simple
ExecStart=/bin/sh -c 'while true; do date >> /var/log/time_logger.log; sleep 10; done'
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now time_logger.service


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
apt-get install -y curl jq vim htop rsync sudo openssh-server


# FINISHED
echo "=== Linux setup complete ==="
systemctl --no-pager status time_logger.service
