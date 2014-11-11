
Facter.add(:docker_hosted_containers) do
  setcode do
    containers_hash = {}
    container_array = Facter::Core::Execution.exec('/usr/bin/docker ps -q').chomp().split(/\n/)
    container_array.each do |container|
      hostname = Facter::Core::Execution.exec("/usr/bin/docker inspect -f \"{{ .Name }}\" #{container}").sub(/^\//,"")
      ip = Facter::Core::Execution.exec("/usr/bin/docker inspect -f \"{{ .NetworkSettings.IPAddress }}\" #{container}")
      if hostname
        # containers_hash[container]['hostname'] = hostname
        # containers_hash[container]['ip'] = ip
        containers_hash[hostname] = ip
      end
    end
    containers_hash
  end
end

