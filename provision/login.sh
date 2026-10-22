
#!/usr/bin/env bash
# Configure users, groups, sudo, and SSH security.
set -e

echo "=== Login setup started ==="


# 1. GROUPS
echo "--- Creating groups"

for group in developers admin; do
    getent group "$group" || groupadd "$group"
done


# 2. USERS
echo "--- Creating users"

# Create each user only if missing.
id alice >/dev/null 2>&1 || useradd -m -g developers alice
id bob   >/dev/null 2>&1 || useradd -m -g developers bob
id carol >/dev/null 2>&1 || useradd -m -g admin carol

# Set passwords.
printf '%s\n' \
    'alice:SecurePass123!' \
    'bob:SecurePass456!' \
    'carol:SecurePass789!' | chpasswd

# Lock root password.
passwd -l root


# 3. SUDO PERMISSIONS
echo "--- Configuring sudo"

cat > /etc/sudoers.d/90-developers <<'EOF'
%developers ALL=(ALL:ALL) ALL
%admin ALL=(ALL) NOPASSWD: /usr/bin/systemctl
EOF

chmod 440 /etc/sudoers.d/90-developers
visudo -c


# 4. SSH SECURITY
echo "--- Configuring SSH"

mkdir -p /etc/ssh/sshd_config.d

cat > /etc/ssh/sshd_config.d/90-hardening.conf <<'EOF'
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
EOF

# Check the configuration before restarting SSH.
sshd -t
systemctl restart ssh


# 5. SSH FILE PERMISSIONS
echo "--- Protecting SSH files"

for user in alice bob carol; do
    HOME_DIR=$(getent passwd "$user" | cut -d: -f6)

    if [ -d "$HOME_DIR/.ssh" ]; then
        chmod 700 "$HOME_DIR/.ssh"

        if [ -f "$HOME_DIR/.ssh/authorized_keys" ]; then
            chmod 600 "$HOME_DIR/.ssh/authorized_keys"
        fi
    fi
done


# 6. VERIFICATION SCRIPT
echo "--- Checking verification script"

if [ -f /vagrant/provision/verify.sh ]; then
    cp /vagrant/provision/verify.sh /usr/local/bin/verify.sh
    chmod 755 /usr/local/bin/verify.sh
    echo "Verification script installed"
else
    echo "WARNING: verify.sh was not found"
fi


echo "=== Login setup complete ==="
