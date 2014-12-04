
Facter.add(:weave_networked_containers) do
  setcode do
    containers_hash = {}
    docker_binary = Facter::Core::Execution.exec('/usr/bin/which docker') 
    if docker_binary !~ /docker/
      containers_hash['docker_host'] = 'not a docker host'
    else
      containers_hash['docker_host'] = {} 
      docker_hostname = Facter::Core::Execution.exec("/bin/hostname -f")
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
      containers_hash['by_ip'] = {}
      containers_hash['by_mac'] = {}
      containers_hash['by_host'] = {}
      containers_hash['by_container_id'] = {}
      containers_hash['weave_ips'] = []
      containers_hash['hostnames'] = []
      containers_hash['container_ids'] = []
      containers_hash['mac_addresses'] = []
      if container_array
        container_array.each do |container_array_entry|
          container_count += 1
          container = container_array_entry.split(/\s+/)
          container_id = container[0]
          containers_hash['by_container_id'][container_id] = {}
          weave_mac = container[1]
          containers_hash['by_mac'][weave_mac] = {}
          weave_ip = container[2]
          containers_hash['by_ip'][weave_ip] = {}
          container_hostname = Facter::Core::Execution.exec("/usr/bin/docker inspect -f \"{{ .Name }}\" #{container_id}").sub(/^\//,"")
          containers_hash['by_host'][container_hostname] = {}
          if container_hostname
            containers_hash['by_host'][container_hostname]['container_id'] = container_id
            containers_hash['by_host'][container_hostname]['weave_mac'] = weave_mac
            containers_hash['by_host'][container_hostname]['weave_ip'] = weave_ip
          end
          if weave_ip
            containers_hash['by_ip'][weave_ip]['container_id'] = container_id 
            containers_hash['by_ip'][weave_ip]['weave_mac'] = weave_mac
            containers_hash['by_ip'][weave_ip]['hostname'] = container_hostname
          end
          if weave_mac
            containers_hash['by_mac'][weave_mac]['container_id'] = container_id 
            containers_hash['by_mac'][weave_mac]['weave_ip'] = weave_ip
            containers_hash['by_mac'][weave_mac]['hostname'] = container_hostname
          end
          if container_id
            containers_hash['by_container_id'][container_id]['weave_ip'] = weave_ip 
            containers_hash['by_container_id'][container_id]['weave_mac'] = weave_mac 
            containers_hash['by_container_id'][container_id]['hostname'] = container_hostname
          end
          containers_hash['container_ids'].push(container_id)
          containers_hash['mac_addresses'].push(weave_mac)
          containers_hash['weave_ips'].push(weave_ip)
          containers_hash['hostnames'].push(container_hostname)
        end
      end
      containers_hash['container_count'] = container_count
    end
    containers_hash
  end
end

