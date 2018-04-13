# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu/xenial64"

  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    #   vb.gui = true
    vb.name = "my_vm"
    
	# Example: Customize the amount of memory on the VM:
    vb.memory = "1024"
	# Example: Use VBoxManage to customize the VM. For example to change memory or VCPU
    vb.customize ["modifyvm", :id, "--cpus", "1"]
  end
end
