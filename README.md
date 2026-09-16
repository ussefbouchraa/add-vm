1. 📦 Vagrant


Vagrant helps you:

create a VM
start it
stop it
connect to it
destroy it
configure it automatically

Important commands:

vagrant up : create new VM
vagrant ssh
vagrant status : give thr current status of my VM
vagrant destroy | -f : delete VM


**************** Vagrant is the tool that create/manages the VM for you.

--------------------------------------------------------------------------------------------

2. 📜 Vagrantfile

The Vagrantfile is the configuration/recipe for your VM.

It tells Vagrant things like:

Which operating system/base box to use
How much RAM/CPU
Network configuration
Which scripts to run
Which provider to use


**************** Vagrantfile = instructions for how my VM should be created and configured.

--------------------------------------------------------------------------------------------


3. ⚙️ Provisioning


Creating the VM is not enough.

You also need to configure it:

install packages
create users
create groups
configure SSH
configure sudo
configure network
create services
configure permissions

You can put these instructions in scripts such as:

provision/
├── linux.sh
└── login.sh


*******************  Vagrant creates the machine. Provisioning configures the machine 

--------------------------------------------------------------------------------------------

          ┌─────────────┐
          │ Vagrantfile │
          └──────┬──────┘
                 │
                 ▼
             VAGRANT
                 │
        ┌────────┴────────┐
        ▼                 ▼
      Create VM      Provision VM
                          │
                          ▼
                 linux.sh / login.sh
                          │
                          ▼
                Configured Server