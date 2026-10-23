# add-vm

This project turns the hand-built Linux server into reproducible Infrastructure as Code using Vagrant.

## Goal
Rebuild the machine with a single vagrant up and no manual input. The rebuilt VM must pass provision/verify.sh.

## Repository Structure
```text
add-vm/
|-- README.md
|-- Vagrantfile
|-- provision/
|   |-- linux.sh
|   |-- login.sh
|   `-- verify.sh
`-- .gitignore
```

## Prerequisites
- Vagrant
- VirtualBox (x86_64/AMD64)
- Git

## Build Instructions
```bash
git clone <repo-url>
cd add-vm
vagrant up
```

## Verify
```bash
vagrant ssh
sudo /usr/local/bin/verify.sh
```

## Reproducibility
```bash
vagrant destroy -f
vagrant up
vagrant ssh -c "sudo /usr/local/bin/verify.sh"
```

## Architecture Notes
- x86_64/Intel/AMD: virtualbox + debian/bookworm64
- Apple Silicon (ARM64): use vagrant-qemu with arm64 box (VirtualBox not supported)

## Snapshot vs Rebuild
- Snapshot: experiment safely, quick rollback
- Rebuild from code: source of truth for audit/sharing

## Idempotency
Scripts guard existing resources to avoid duplicates on re-provision.
