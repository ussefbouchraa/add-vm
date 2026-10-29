Vagrant.configure("2") do |config|

  # Debian VM use (Minimal Debian box as base image)
    config.vm.box = "debian/bookworm64"

    # Set the hostname 
    config.vm.hostname = "linux-server"

    # Configure the VirtualBox virtual machine.
    config.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
      vb.name = "linux-server"
    end

    config.vm.provision "file",
      source: "~/.ssh/id_rsa.pub",
      destination: "/tmp/vagrant_id_rsa.pub"

    # Network configuration
    config.vm.network "private_network", ip: "192.168.56.10"

  # Provisioning scripts
  config.vm.provision "shell", path: "provision/linux.sh"
  config.vm.provision "shell", path: "provision/login.sh"
end