
require 'json'; 

Facter.add(:weave_networked_containers) do
  setcode do
    containers_hash = {}
    containers_hash['container_ids'] = []
    docker_binary = Facter::Core::Execution.exec('/usr/bin/which docker') 
    if docker_binary !~ /docker/
      containers_hash['docker_host'] = 'not a docker host'
    else
      docker_hostname = Facter::Core::Execution.exec("hostname -f")
      containers_hash['docker_host']['hostname'] = docker_hostname 
      docker_weave_ip = Facter::Core::Execution.exec("/sbin/ip addr show dev weave | /bin/grep 'inet ' | /bin/sed \"s,^.* inet ,,\" | /bin/sed \"s, .*$,,\"")
      containers_hash['docker_host']['weave_ip'] = docker_weave_ip
      weave_mac = Facter::Core::Execution.exec("/usr/local/bin/weave status | /usr/bin/head -n1 | /bin/sed \"s,Our name is ,,\"")
      containers_hash['docker_host']['weave_mac'] = weave_mac
      peered_device = 'not_yet_implemented'
      containers_hash['docker_host']['peered_device'] = peered_device
      peered_ip = 'not_yet_implemented'
      containers_hash['docker_host']['peered_ip'] = peered_ip
      peers = 'not_yet_implemented'
      containers_hash['docker_host']['peers'] = peers
      container_array = Facter::Core::Execution.exec('/usr/local/bin/weave ps').chomp().split(/\n/)
      container_count = 0
      if container_array
        container_array.each do |container_array_entry|
          container_count += 1
          container = container_array_entry.split(/\s+/)
          container_hostname = Facter::Core::Execution.exec("/usr/bin/docker inspect -f \"{{ .Name }}\" #{container[0]}").sub(/^\//,"")
          if container_hostname
            containers_hash['by_host'][container_hostname]['container_id'] = container[0]
            containers_hash['by_host'][container_hostname]['weave_mac'] = container[1]
            containers_hash['by_host'][container_hostname]['weave_ip'] = container[2]
          end
          if container[2]
            containers_hash['by_ip'][container[2]]['container_id'] = container[0]
            containers_hash['by_ip'][container[2]]['weave_mac'] = container[1]
            containers_hash['by_ip'][container[2]]['hostname'] = container_hostname
          end
          if container[0]
            containers_hash['by_container_id'][container[0]]['weave_ip'] = container[2]
            containers_hash['by_container_id'][container[0]]['weave_mac'] = container[1]
            containers_hash['by_container_id'][container[0]]['hostname'] = container_hostname
          end
          containers_hash['container_ids'].push(container[0])
          containers_hash['mac_addresses'].push(container[1])
          containers_hash['weave_ips'].push(container[2])
          containers_hash['hostnames'].push(container_hostname)
        end
      end
      containers_hash['container_count'] = container_count
    end
    containers_hash
  end
end

