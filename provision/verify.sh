#!/usr/bin/env bash
# verify.sh — regression test for the add-vm project.
# Run this AFTER `vagrant up` to confirm the rebuilt machine is correctly configured.
# Every assertion must pass. If any fail, the configuration was not fully captured in code.
set -euo pipefail

PASS=0
FAIL=0
check() {
  local desc="$1"
  shift
  if "$@"; then
    echo "  PASS: ${desc}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: ${desc}"
    FAIL=$((FAIL + 1))
  fi
}

echo "============================================"
echo "  Verification — add-vm (login project)"
echo "============================================"
echo ""

# ---------------------------------------------------------------------------
# 1. Users and groups
# ---------------------------------------------------------------------------
echo "--- Users and groups ---"
check "user alice exists"        id alice
check "user bob exists"          id bob
check "user carol exists"        id carol
check "group developers exists"  getent group developers
check "group admin exists"       getent group admin
# check "alice in developers"      grep -q "^alice:" /etc/group | grep developers || id alice | grep -q developers
check "alice in developers" id -nG alice | grep -qw developers
check "carol in admin"           id carol | grep -q admin

# ---------------------------------------------------------------------------
# 2. Sudo policy
# ---------------------------------------------------------------------------
echo "--- Sudo policy ---"
SUDOERS_FILE="/etc/sudoers.d/90-developers"
check "sudoers file exists"      test -f "${SUDOERS_FILE}"
check "sudoers readable"         test -r "${SUDOERS_FILE}"
check "sudoers permissions 440"  test "$(stat -c '%a' ${SUDOERS_FILE})" = "440"
check "sudoers syntax valid"     visudo -c -q -f "${SUDOERS_FILE}"

# ---------------------------------------------------------------------------
# 3. SSH configuration
# ---------------------------------------------------------------------------
echo "--- SSH configuration ---"
SSHD_SNIPPET="/etc/ssh/sshd_config.d/90-hardening.conf"
check "SSH hardening snippet exists"  test -f "${SSHD_SNIPPET}"
check "PasswordAuthentication disabled" grep -q "^PasswordAuthentication no" "${SSHD_SNIPPET}"
check "PubkeyAuthentication enabled"   grep -q "^PubkeyAuthentication yes" "${SSHD_SNIPPET}"
check "PermitRootLogin disabled"        grep -q "^PermitRootLogin no" "${SSHD_SNIPPET}"

# ---------------------------------------------------------------------------
# 4. Network configuration
# ---------------------------------------------------------------------------
echo "--- Network configuration ---"
INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -vE '^(lo|tun|docker|veth)' | head -n1)
check "static address 10.0.2.15/24 present" \
  ip addr show "${INTERFACE}" | grep -q "10.0.2.15/24"

# ---------------------------------------------------------------------------
# 5. Systemd service
# ---------------------------------------------------------------------------
echo "--- Systemd service ---"
check "time_logger.service exists"        test -f /etc/systemd/system/time_logger.service
check "time_logger.service is active"     systemctl is-active --quiet time_logger.service
check "time_logger script exists"          test -x /usr/local/bin/time_logger.sh
check "time_logger log is being written"   test -f /var/log/time_logger.log

# ---------------------------------------------------------------------------
# 6. Storage layout
# ---------------------------------------------------------------------------
echo "--- Storage layout ---"
check "/data directory exists"           test -d /data
check "/var/tmp is a tmpfs mount"        mount | grep -q "/var/tmp.*tmpfs"

# ---------------------------------------------------------------------------
# 7. Root account
# ---------------------------------------------------------------------------
echo "--- Root account ---"
# Root should be locked (no password login)
check "root account is locked"           passwd -S root | grep -q "L"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo "  Results: ${PASS} passed, ${FAIL} failed"
echo "============================================"

if [ "${FAIL}" -gt 0 ]; then
  echo "VERIFICATION FAILED — configuration not fully captured in code."
  exit 1
else
  echo "VERIFICATION PASSED — machine is correctly provisioned."
  exit 0
fi