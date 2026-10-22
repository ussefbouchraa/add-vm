
#!/usr/bin/env bash

# Stop if a command fails.
set -e

echo "===== LOGIN SETUP STARTED ====="

# ==========================================
# 1. CREATE GROUPS
# ==========================================
echo "Creating groups..."

getent group developers || groupadd developers
getent group admin || groupadd admin


# ==========================================
# 2. CREATE USERS
# ==========================================
echo "Creating users..."

# Create ybouchra in the developers group.
id ybouchra >/dev/null 2>&1 || useradd -m -g developers ybouchra

# Create ussef in the admin group.
id ussef >/dev/null 2>&1 || useradd -m -g admin ussef


# ==========================================
# 3. SET PASSWORDS
# ==========================================
echo "Setting passwords..."

printf '%s\n' \
    'ybouchra:123456789' \
    'ussef:987654321' | chpasswd


# ==========================================
# 4. LOCK ROOT PASSWORD
# ==========================================
echo "Locking root password..."

passwd -l root


# ==========================================
# 5. CONFIGURE SUDO PERMISSIONS
# ==========================================
echo "Configuring sudo..."

cat > /etc/sudoers.d/90-developers <<'EOF'
%developers ALL=(ALL:ALL) ALL
%admin ALL=(ALL) NOPASSWD: /usr/bin/systemctl
EOF

chmod 440 /etc/sudoers.d/90-developers
visudo -c


# ==========================================
# 6. CONFIGURE SSH SECURITY
# ==========================================
echo "Configuring SSH..."

mkdir -p /etc/ssh/sshd_config.d

cat > /etc/ssh/sshd_config.d/90-hardening.conf <<'EOF'
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
EOF

# Check SSH configuration before restarting.
sshd -t
systemctl restart ssh


# ==========================================
# 7. PROTECT SSH FILES
# ==========================================
echo "Protecting SSH files..."

for user in ybouchra ussef; do
    HOME_DIR=$(getent passwd "$user" | cut -d: -f6)

    if [ -d "$HOME_DIR/.ssh" ]; then
        chmod 700 "$HOME_DIR/.ssh"

        if [ -f "$HOME_DIR/.ssh/authorized_keys" ]; then
            chmod 600 "$HOME_DIR/.ssh/authorized_keys"
        fi
    fi
done


# ==========================================
# 8. INSTALL VERIFICATION SCRIPT
# ==========================================
echo "Installing verification script..."

if [ -f /vagrant/provision/verify.sh ]; then
    cp /vagrant/provision/verify.sh /usr/local/bin/verify.sh
    chmod 755 /usr/local/bin/verify.sh
    echo "Verification script installed."
else
    echo "WARNING: verify.sh not found."
fi


# ==========================================
# FINISHED
# ==========================================
echo "===== LOGIN SETUP COMPLETED ====="
