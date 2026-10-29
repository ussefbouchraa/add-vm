# add-vm

## Overview

This project transforms a manually configured Debian server into a reproducible Infrastructure as Code (IaC) environment using Vagrant and VirtualBox.

The goal is to rebuild a fully configured server with a single command, without manual configuration.

The project reproduces the work completed in the `linux` and `login` projects through automated provisioning scripts.

## Learning Objectives

- Automate server configuration without interactive input.
- Manage virtual machines using Vagrant.
- Configure networking and systemd services through scripts.
- Automate users, groups, permissions, sudo policies and SSH configuration.
- Write idempotent provisioning scripts.
- Prove reproducibility by destroying and rebuilding the virtual machine.
- Use snapshots and rollback safely.
- Understand the differences between x86-64 and ARM64 architectures.

## Repository Structure

```text
add-vm/
├── README.md
├── Vagrantfile
└── provision/
    ├── linux.sh
    └── login.sh
```

The project uses a minimal Debian base box, so a separate `preseed.cfg` or `cloud-init` directory is not required. The operating system comes from the base box, while the provisioning scripts configure the server automatically.

## Requirements

Install the following tools before starting:

- Git
- Vagrant
- VirtualBox on a compatible x86-64 machine

Check the installed versions:

```bash
git --version
vagrant --version
VBoxManage --version
```

## Architecture

### x86-64: Intel and AMD

The current configuration uses:

- **Provider:** VirtualBox
- **Base box:** `debian/bookworm64`
- **Operating system:** Debian 12 (Bookworm)
- **Memory:** 2048 MB
- **CPUs:** 2

The provider and base box must be compatible with the host CPU architecture.

### Apple Silicon: ARM64

VirtualBox is not supported as the virtualization provider on Apple Silicon Macs.

To support ARM64, use an ARM-compatible provider such as QEMU through `vagrant-qemu`, or VMware Fusion, and select a compatible ARM64 Debian base box.

The Vagrant workflow remains similar, but the provider, box and possibly provider-specific settings must change. The provisioning scripts should avoid unnecessary architecture-specific assumptions.

## Virtual Machine Configuration

The `Vagrantfile` defines the virtual machine, its resources, networking and provisioning scripts.

The machine is configured with:

- Hostname: `linux-server`
- Private IP address: `192.168.56.10`
- Memory: 2 GB
- CPUs: 2
- Provisioning scripts: `provision/linux.sh` and `provision/login.sh`

### Networking

The virtual machine uses two network interfaces:

| Interface | Purpose | Example address |
|---|---|---|
| NAT | Internet access and outbound connectivity | `10.0.2.15` |
| Private network | Communication between the host and VM | `192.168.56.10` |

The NAT interface normally receives its address through DHCP. The private interface uses the configured private address.

These addresses are examples of the expected configuration and should be verified after the VM starts.

To check the network configuration:

```bash
vagrant ssh
ip -br address
ip route
```

## Provisioning

### `provision/linux.sh`

This script reproduces the server configuration from the `linux` project.

Its responsibilities include the network configuration and custom systemd service, along with the other Linux settings implemented in the script.

The script should configure the machine automatically and avoid requiring manual input.

### `provision/login.sh`

This script reproduces the security and account configuration from the `login` project.

The intended configuration includes users, groups, sudo policy, file permissions and SSH settings.

The user and group names configured for this project include:

- Users: `ybouchra`, `ussef`, `bouchraa`
- Groups: `developers`, `deploy`, `admin`

The actual permissions and group memberships must match the provisioning script. Membership in a group should not automatically grant unrestricted sudo access unless explicitly intended.

SSH access should follow the public-key authentication policy configured by the script.

## Starting the Environment

Clone the repository:

```bash
git clone https://learn.zone01oujda.ma/git/ybouchra/add-vm
cd add-vm
```

Start the virtual machine:

```bash
vagrant up
```

Vagrant creates the virtual machine and runs the provisioning scripts.

The environment should reach its configured state without requiring manual input.

Connect to the VM:

```bash
vagrant ssh
```

Exit the VM:

```bash
exit
```

## Idempotency

Idempotency means that running a provisioning script multiple times produces the same intended configuration without duplicating resources or causing errors.

For example, a user should not be created repeatedly, and a configuration line should not be appended every time the script runs.

To test idempotency, start the VM and run provisioning again:

```bash
vagrant up
vagrant provision
```

Expected result:

- Provisioning completes without errors.
- Existing users and groups are not duplicated.
- Configuration files do not accumulate repeated entries.
- Services and permissions remain in the expected state.

If the second run changes the configuration unexpectedly or fails, the provisioning scripts need to be corrected.

## Reproducibility Test

Reproducibility proves that the complete server can be recreated from the repository rather than depending on a previously configured VM.

**Warning:** The following command permanently removes the current Vagrant-managed VM and its local state. Save any important data first.

Destroy the virtual machine:

```bash
vagrant destroy -f
```

Recreate it:

```bash
vagrant up
```

The rebuild should complete without manual input.

### Verification

Run the verification script from the `login` project unchanged.

If the script is installed at `/usr/local/bin/verify.sh`, execute:

```bash
vagrant ssh
sudo /usr/local/bin/verify.sh
```

The verification script must pass all its existing assertions.

If it fails after a clean rebuild, some required configuration may be missing from the repository or provisioning scripts.

Record the actual results and the rebuild time during testing.

## Snapshots and Rollback

A snapshot saves a point-in-time state of a virtual machine. It allows you to return to that state after an experiment goes wrong.

### Creating a Snapshot

Start with a working virtual machine and save a snapshot before making risky changes:

```bash
vagrant snapshot save before-experiment
```

### Listing Snapshots

```bash
vagrant snapshot list
```

### Making a Change

For example, temporarily change a configuration file inside the VM. Verify that the change is visible before restoring the snapshot.

### Rolling Back

```bash
vagrant snapshot restore before-experiment
```

Check the machine afterwards to confirm that the previous state has been restored.

Snapshot commands and their exact behavior depend on the installed Vagrant version and provider. Test these commands with the configured VirtualBox provider.

### When to Use a Snapshot

Use a snapshot when:

- Testing a risky configuration change.
- Experimenting with network or SSH settings.
- You need a quick way to return to a known working state.

### When to Rebuild from Code

Use a clean rebuild when:

- Proving that the project is reproducible.
- Testing whether provisioning contains every required step.
- Checking that another student can create the same environment.
- Validating changes made to the repository.

A snapshot preserves a particular state. Infrastructure as Code describes the intended state.

**A snapshot is not a replacement for Git or a reliable external backup.** It may preserve existing errors, and it may be lost if the host's storage fails.

## Git and Version Control

All configuration must be tracked in Git so another student can reproduce the environment.

Check the repository status:

```bash
git status
```

Review the changes:

```bash
git diff
```

Commit meaningful changes:

```bash
git add Vagrantfile provision/ README.md
git commit -m "Add reproducible Vagrant server configuration"
```

Do not commit private SSH keys, passwords or other secrets.

## Troubleshooting

### Virtual machine does not start

Check that VirtualBox and Vagrant are installed and compatible with the host architecture.

```bash
vagrant status
vagrant up
```

### SSH connection fails

Try the standard Vagrant connection:

```bash
vagrant ssh
```

Check the SSH service and account configuration inside the VM.

### Provisioning fails

Inspect the error output, correct the relevant script, and run:

```bash
vagrant provision
```

### Rebuild fails verification

Compare the expected state with the provisioning scripts. Ensure the required users, groups, permissions, services and SSH settings are recreated from scratch.

### Snapshot restoration fails

Check the snapshot name and provider support:

```bash
vagrant snapshot list
vagrant status
```

Consult the Vagrant documentation for provider-specific limitations.

## Audit Checklist

Before submitting the project, verify each requirement:

- [ ] Repository contains the Vagrantfile and provisioning scripts.
- [ ] Configuration is committed to Git.
- [ ] `vagrant up` completes without manual input.
- [ ] The provider and base box match the host architecture.
- [ ] Network configuration and the custom service are reproduced.
- [ ] Users, groups, permissions, sudo policy and SSH settings are reproduced.
- [ ] Provisioning can run again without errors or duplication.
- [ ] `vagrant destroy -f` followed by `vagrant up` succeeds.
- [ ] The unchanged `login` verification script passes after rebuilding.
- [ ] A snapshot can be created, a visible change made, and the change rolled back.
- [ ] Documentation explains when to snapshot and when to rebuild.
- [ ] Architecture differences and rebuild evidence are documented.

## References

- [Vagrant Documentation](https://developer.hashicorp.com/vagrant/docs)
- [Vagrant Snapshot Commands](https://developer.hashicorp.com/vagrant/docs/cli/snapshot)
- [Vagrant QEMU Provider](https://github.com/ppggff/vagrant-qemu)
- [Vagrant VMware Provider](https://developer.hashicorp.com/vagrant/docs/providers/vmware)
- [Debian Preseed Guide](https://wiki.debian.org/DebianInstaller/Preseed)
- [cloud-init Documentation](https://cloud-init.readthedocs.io/)
- [Packer Documentation](https://developer.hashicorp.com/packer/docs)

## Conclusion

The `add-vm` project turns a manually configured server into a reproducible environment described in version-controlled files.

Vagrant manages the virtual machine, provisioning scripts configure the operating system, idempotency makes repeated runs safe, and a clean destroy-and-rebuild cycle proves that the configuration is complete.

Snapshots provide a convenient rollback mechanism for experiments, while the repository remains the source of truth for rebuilding the server.
