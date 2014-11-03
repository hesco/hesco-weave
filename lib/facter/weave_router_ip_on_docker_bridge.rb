#!/usr/bin/env ruby
require 'facter'

Facter.add(:weave_router_ip_on_docker_bridge) do
  setcode '/usr/bin/docker inspect -f "{{ .NetworkSettings.IPAddress }}" weave 2> /dev/null || /bin/echo "no weave router running"'
end

