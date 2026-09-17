Vagrant.configure("2") do |config|

  # Debian VM use (Minimal Debian box as base image)
  config.vm.box = "debian/bookworm64"

  # CPU and RAM
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end

  # Network configuration
  config.vm.network "private_network", ip: "***********"

  # Provisioning scripts
  config.vm.provision "shell", path: "provision/linux.sh"
  config.vm.provision "shell", path: "provision/login.sh"

end