Vagrant.configure("2") do |config|

  config.vm.box = "debian/bookworm64"

 config.vm.provision "shell", path: "provision/linux.sh"
config.vm.provision "shell", path: "provision/login.sh"

end