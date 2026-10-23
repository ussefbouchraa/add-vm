#!/usr/bin/env bash
# Configure users, groups, sudo, and SSH security.
set -e
echo "===== LOGIN SETUP STARTED ====="

# 1. GROUPS
getent group developers || groupadd developers
getent group admin || groupadd admin

# 2. USERS
id alice >/dev/null 2>&1 || useradd -m -g developers alice
id bob >/dev/null 2>&1 || useradd -m bob
id carol >/dev/null 2>&1 || useradd -m -g admin carol

# 3. PASSWORDS
printf '%s\n' \
    'alice:123456789' \
    'bob:password' \
    'carol:987654321' | chpasswd

# Lock root password
passwd -l root

# 4. SUDO PERMISSIONS
cat > /etc/sudoers.d/90-developers <<'EOF'
%developers ALL=(ALL:ALL) ALL
%admin ALL=(ALL) NOPASSWD: /usr/bin/systemctl
EOF
chmod 440 /etc/sudoers.d/90-developers
visudo -c

# 5. SSH SECURITY
mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/90-hardening.conf <<'EOF'
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
EOF
sshd -t
systemctl restart ssh || true

# 6. SSH FILE PERMISSIONS
for user in alice bob carol; do
    HOME_DIR=$(getent passwd "$user" | cut -d: -f6)
    [ -d "$HOME_DIR/.ssh" ] && chmod 700 "$HOME_DIR/.ssh"
    [ -f "$HOME_DIR/.ssh/authorized_keys" ] && chmod 600 "$HOME_DIR/.ssh/authorized_keys"
done

# 7. VERIFICATION SCRIPT
if [ -f /vagrant/provision/verify.sh ]; then
    cp /vagrant/provision/verify.sh /usr/local/bin/verify.sh
    chmod 755 /usr/local/bin/verify.sh
fi

echo "===== LOGIN SETUP COMPLETED ====="
