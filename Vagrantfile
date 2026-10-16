# -*- mode: ruby -*-
# Стенд Vagrant + Ansible: web, log, elk.
# Фактически ДЗ выполнено на 2 физических ПК (inventory/hosts.ini),
# Vagrantfile использует тот же playbook site.yml.
MACHINES = {
  web: { ip: "192.168.56.10", mem: 1024 },
  log: { ip: "192.168.56.15", mem: 1024 },
  elk: { ip: "192.168.56.20", mem: 4096 },
}

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  MACHINES.each_with_index do |(name, opts), idx|
    config.vm.define name do |box|
      box.vm.hostname = name.to_s
      box.vm.network "private_network", ip: opts[:ip]
      box.vm.provider "virtualbox" do |vb|
        vb.memory = opts[:mem]
        vb.cpus = 2
      end

      # Ansible запускается один раз, после создания последней ВМ
      if idx == MACHINES.size - 1
        box.vm.provision "ansible" do |ansible|
          ansible.playbook = "site.yml"
          ansible.config_file = "ansible.cfg"
          ansible.limit = "all"
          ansible.become = true
          ansible.groups = {
            "webservers" => ["web"],
            "logservers" => ["log"],
            "elkservers" => ["elk"]
          }
          ansible.extra_vars = {
            web_ip: "192.168.56.10",
            log_server_ip: "192.168.56.15",
            elk_server_ip: "192.168.56.20",
            nginx_log_target: "elk"
          }
        end
      end
    end
  end
end
