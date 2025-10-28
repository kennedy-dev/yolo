Vagrant.configure("2") do |config|
  config.vm.box = "geerlingguy/ubuntu2004"
  config.vm.hostname = "yolo-server"
  config.vm.network "private_network", ip: "192.168.56.10"
  
  # Port forwarding
  config.vm.network "forwarded_port", guest: 3000, host: 8080
  config.vm.network "forwarded_port", guest: 5000, host: 8081
  
  config.vm.provider "virtualbox" do |vb|
    vb.name = "yolo-ansible"
    vb.memory = "2048"
    vb.cpus = 2
  end

  # Ansible provisioning
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbooks/site.yml"
    ansible.inventory_path = "inventory/hosts.yml"
    ansible.config_file = "ansible.cfg"
    ansible.verbose = "v"
    ansible.limit = "all"
  end
end