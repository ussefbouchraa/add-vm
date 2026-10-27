
#!/usr/bin/env bash
# verify.sh — regression test for the add-vm project.
# Run after provisioning the VM.
set -uo pipefail

PASS=0
FAIL=0

check() {
    local desc="$1"
    shift

    if "$@"; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "============================================"
echo " Verification — add-vm "
echo "============================================"
echo

# 1. Users and groups
echo "--- Users and groups ---"

check "user ybouchra exists" id ybouchra
check "user ussef exists" id ussef
check "user bouchraa exists" id bouchraa

check "group developers exists" getent group developers
check "group admin exists" getent group admin
check "group deploy exists" getent group deploy

check "ybouchra belongs to developers" \
    id -nG ybouchra | grep -qw developers
check "ussef belongs to admin" \
    id -nG ussef | grep -qw admin
check "bouchraa belongs to deploy" \
    id -nG bouchraa | grep -qw deploy

# 2. Sudo policy
echo
echo "--- Sudo policy ---"

SUDOERS_FILE="/etc/sudoers.d/sudo_config"

check "sudoers file exists" test -f "$SUDOERS_FILE"
check "sudoers permissions are 440" \
    test "$(stat -c '%a' "$SUDOERS_FILE" 2>/dev/null)" = "440"
check "sudoers syntax is valid" \
    visudo -cf "$SUDOERS_FILE"

check "admin has unrestricted sudo" \
    sudo -l -U ussef 2>/dev/null |
    grep -Eq '\(ALL(:ALL)?\)[[:space:]]+ALL'

check "developer can restart only time_logger.service" \
    sudo -l -U ybouchra 2>/dev/null |
    grep -Fq '/usr/bin/systemctl restart time_logger.service'

check "deploy can restart only time_logger.service" \
    sudo -l -U bouchraa 2>/dev/null |
    grep -Fq '/usr/bin/systemctl restart time_logger.service'

check "developer is not in sudo group" \
    ! id -nG ybouchra | grep -qw sudo
check "deploy is not in sudo group" \
    ! id -nG bouchraa | grep -qw sudo

# 3. SSH configuration
echo
echo "--- SSH configuration ---"

SSHD_SNIPPET="/etc/ssh/sshd_config.d/ssh-security.conf"

check "SSH security snippet exists" test -f "$SSHD_SNIPPET"
check "password authentication disabled" \
    grep -Eq '^[[:space:]]*PasswordAuthentication[[:space:]]+no([[:space:]]|$)' "$SSHD_SNIPPET"
check "public-key authentication enabled" \
    grep -Eq '^[[:space:]]*PubkeyAuthentication[[:space:]]+yes([[:space:]]|$)' "$SSHD_SNIPPET"
check "root SSH login disabled" \
    grep -Eq '^[[:space:]]*PermitRootLogin[[:space:]]+no([[:space:]]|$)' "$SSHD_SNIPPET"

check "effective SSH configuration is valid" sshd -t

for user in ybouchra ussef bouchraa; do
    HOME_DIR=$(getent passwd "$user" | cut -d: -f6)
    check "$user has an authorized_keys file" \
        test -s "$HOME_DIR/.ssh/authorized_keys"
done

# 4. Network configuration
echo
echo "--- Network configuration ---"

INTERFACE=$(
    ip -o -4 addr show |
    awk '$4 == "10.0.2.15/24" {print $2; exit}'
)

check "static address 10.0.2.15/24 is present" \
    test -n "$INTERFACE"

# Note: this verifies the address is present, not that its
# configuration survives reboot as a static address.

# 5. Systemd service
echo
echo "--- Systemd service ---"

check "time_logger.service exists" \
    test -f /etc/systemd/system/time_logger.service
check "time_logger.service is active" \
    systemctl is-active --quiet time_logger.service
check "time_logger script is executable" \
    test -x /usr/local/bin/time_logger.sh
check "time_logger log exists" \
    test -f /var/log/time_logger.log

# 6. Storage layout
echo
echo "--- Storage layout ---"

check "/data directory exists" test -d /data
check "/var/tmp is mounted as tmpfs" \
    findmnt -rn -T /var/tmp -t tmpfs

# 7. Root account and password policy
echo
echo "--- Root and password policy ---"

check "root password is locked" \
    passwd -S root | awk '$2 == "L" {found=1} END {exit !found}'

for user in ybouchra ussef bouchraa; do
    check "$user password expiry is 90 days" \
        chage -l "$user" |
        grep -q 'Maximum number of days between password change.*90'
done

# 8. Summary
echo
echo "============================================"
echo " Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
    echo "VERIFICATION FAILED"
    exit 1
else
    echo "VERIFICATION PASSED"
    exit 0
fi
