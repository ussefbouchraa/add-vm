Vagrant.configure("2") do |config|

  # Debian VM use (Minimal Debian box as base image)
  config.vm.box = "debian/bookworm64"

    # Set the hostname 
    config.vm.hostname = "linux-server"

    # Configure the VirtualBox virtual machine.
    config.vm.provider "virtualbox" do |vb|

    # Allocate 2 GB of RAM.
    vb.memory = 2048

    # Give the VM 2 CPU cores.
    vb.cpus = 2

    # Set a recognizable name in VirtualBox.
    vb.name = "linux-server"
  end

  # # Network configuration
  # config.vm.network "private_network", ip: "***********"

  # Provisioning scripts
  config.vm.provision "shell", path: "provision/linux.sh"
  config.vm.provision "shell", path: "provision/login.sh"
end