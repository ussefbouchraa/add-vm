
#!/usr/bin/env bash

# Stop if a command fails.
set -e

echo "===== LOGIN SETUP STARTED ====="

# ==========================================
# 1. CREATE GROUPS
# ==========================================
echo "Creating groups..."

getent group developers || groupadd developers
getent group deploy     || groupadd deploy
getent group admin      || groupadd admin


# ==========================================
# 2. CREATE USERS
# ==========================================
echo "Creating users..."

# 2. Create users if they do not exist
id ybouchra >/dev/null 2>&1 || useradd -m -g developers ybouchra
id ussef >/dev/null 2>&1 || useradd -m -g admin ussef
id bouchraa >/dev/null 2>&1 || useradd -m -g deploy bouchraa


# ==========================================
# 3. SET PASSWORDS
# ==========================================
echo "Setting passwords..."

printf '%s\n' \
    'ybouchra:A123456789' \
    'bouchraa:B123456789' \
    'ussef:C123456789' | chpasswd


# Password expiry policy: 90 days, minimum 1 day, warning 7 days
for user in ybouchra ussef bouchraa; do
    chage -M 90 -m 1 -W 7 "$user"
done

# ==========================================
# 4. LOCK ROOT PASSWORD
# ==========================================
echo "Locking root password..."

passwd -l root


# ==========================================
# 5. CONFIGURE SUDO PERMISSIONS
# ==========================================
echo "Configuring sudo..."

cat > /etc/sudoers.d/sudo_config <<'EOF'
%admin ALL=(ALL:ALL) ALL
%developers ALL=(root) /usr/bin/systemctl restart time_logger.service
%deploy ALL=(root) /usr/bin/systemctl restart time_logger.service
EOF

chmod 440 /etc/sudoers.d/sudo_config
visudo -c


# ==========================================
# 6. CONFIGURE SSH SECURITY
# ==========================================
echo "Configuring SSH..."

mkdir -p /etc/ssh/sshd_config.d

cat > /etc/ssh/sshd_config.d/ssh-security.conf <<'EOF'
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

PUBLIC_KEY_FILE="/tmp/vagrant_id_ed25519.pub"

if [ ! -s "$PUBLIC_KEY_FILE" ]; then
    echo "ERROR: Public key not found" >&2
    exit 1
fi

for user in ybouchra ussef bouchraa; do
    HOME_DIR=$(getent passwd "$user" | cut -d: -f6)
    USER_GROUP=$(id -gn "$user")

    install -d -m 700 -o "$user" -g "$USER_GROUP" \
        "$HOME_DIR/.ssh"

    install -m 600 -o "$user" -g "$USER_GROUP" \
        "$PUBLIC_KEY_FILE" "$HOME_DIR/.ssh/authorized_keys"
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
