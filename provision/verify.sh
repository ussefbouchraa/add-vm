
#!/usr/bin/env bash
# Verify the add-vm project.
# Run with: sudo ./verify.sh

set -uo pipefail

# Root access is required.
if [ "$EUID" -ne 0 ]; then
    echo "Please run: sudo ./verify.sh"
    exit 1
fi

PASS=0
FAIL=0

# Run a check and display its result.
check() {
    local description="$1"
    shift

    if "$@"; then
        echo "PASS: $description"
        ((PASS += 1))
    else
        echo "FAIL: $description"
        ((FAIL += 1))
    fi
}

echo "================================"
echo "      ADD-VM VERIFICATION"
echo "================================"

# 1. USERS AND GROUPS
echo
echo "--- Users and groups ---"

check "ybouchra exists" id ybouchra
check "ussef exists" id ussef
check "bouchraa exists" id bouchraa

check "developers group exists" getent group developers
check "admin group exists" getent group admin
check "deploy group exists" getent group deploy

check "ybouchra belongs to developers" \
    bash -c 'id -nG ybouchra | grep -qw developers'

check "ussef belongs to admin" \
    bash -c 'id -nG ussef | grep -qw admin'

check "bouchraa belongs to deploy" \
    bash -c 'id -nG bouchraa | grep -qw deploy'


# 2. SUDO PERMISSIONS
echo
echo "--- Sudo permissions ---"

SUDOERS="/etc/sudoers.d/sudo_config"

check "sudoers file exists" test -f "$SUDOERS"
check "sudoers permissions are 440" \
    bash -c 'test "$(stat -c %a "$1")" = 440' _ "$SUDOERS"

check "sudoers syntax is valid" /usr/sbin/visudo -c

check "ussef has admin privileges" \
    bash -c 'sudo -l -U ussef 2>/dev/null | grep -q "ALL"'

check "ybouchra can restart time_logger" \
    bash -c 'sudo -l -U ybouchra 2>/dev/null | grep -Fq "time_logger.service"'

check "bouchraa can restart time_logger" \
    bash -c 'sudo -l -U bouchraa 2>/dev/null | grep -Fq "time_logger.service"'

check "ybouchra is not in sudo group" \
    bash -c '! id -nG ybouchra | grep -qw sudo'

check "bouchraa is not in sudo group" \
    bash -c '! id -nG bouchraa | grep -qw sudo'


# 3. SSH CONFIGURATION
echo
echo "--- SSH configuration ---"

SSH_CONFIG="/etc/ssh/sshd_config.d/ssh-security.conf"

check "SSH configuration exists" test -f "$SSH_CONFIG"

check "password login is disabled" \
    grep -Eq '^PasswordAuthentication no$' "$SSH_CONFIG"

check "public-key login is enabled" \
    grep -Eq '^PubkeyAuthentication yes$' "$SSH_CONFIG"

check "root SSH login is disabled" \
    grep -Eq '^PermitRootLogin no$' "$SSH_CONFIG"

check "SSH configuration is valid" /usr/sbin/sshd -t

for user in ybouchra ussef bouchraa; do
    HOME_DIR=$(getent passwd "$user" | cut -d: -f6)

    check "$user has authorized_keys" \
        test -s "$HOME_DIR/.ssh/authorized_keys"

    check "$user SSH directory permissions are 700" \
        bash -c 'test "$(stat -c %a "$1/.ssh")" = 700' _ "$HOME_DIR"

    check "$user authorized_keys permissions are 600" \
        bash -c 'test "$(stat -c %a "$1/.ssh/authorized_keys")" = 600' _ "$HOME_DIR"
done


# 4. NETWORK
echo
echo "--- Network ---"

check "private IP 192.168.56.10 exists" \
    bash -c 'ip -o -4 addr show | grep -q "192.168.56.10/24"'


# 5. SYSTEMD SERVICE
echo
echo "--- Systemd service ---"

check "time_logger.service exists" \
    test -f /etc/systemd/system/time_logger.service

check "time_logger.service is active" \
    systemctl is-active --quiet time_logger.service

check "time_logger log exists" \
    test -f /var/log/time_logger.log


# 6. STORAGE
echo
echo "--- Storage ---"

check "/data directory exists" test -d /data

check "/var/tmp uses tmpfs" \
    findmnt -rn -T /var/tmp -t tmpfs


# 7. PASSWORD POLICY
echo
echo "--- Password policy ---"

check "root password is locked" \
    bash -c 'passwd -S root | grep -q " L "'

for user in ybouchra ussef bouchraa; do
    check "$user password expires after 90 days" \
        bash -c 'chage -l "$1" | grep -q "Maximum.*90"' _ "$user"
done


# 8. RESULTS
echo
echo "================================"
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "================================"

if [ "$FAIL" -eq 0 ]; then
    echo "VERIFICATION PASSED"
else
    echo "VERIFICATION FAILED"
    exit 1
fi
