
define weave::launch ( 
  $docker_host_weave_ip,
  $docker_cluster_peers,
  $weave_manage_firewall,
){

  validate_bool( is_ip_address( $docker_host_weave_ip ) )

  $docker = getvar('weave::docker')
  $weave = getvar('weave::weave')
  $weave_container = getvar('weave::weave_container')

  $peers = regsubst($docker_cluster_peers, "^$::ipaddress_eth0$", '', 'G')

  # notify { "debug": message => "docker: $docker; weave: $weave; weave container: $weave_container" }
  exec { "reset_weave_for_$docker_host_weave_ip":
    command => "$weave reset ",
     unless => "$docker ps -a | /bin/grep $weave_container | /bin/grep -q -v Exited ",
     notify => Exec["weave_launch_$docker_host_weave_ip"],
  }

  exec { "weave_launch_$docker_host_weave_ip":
    command => "$weave launch $peers ",
     unless => "$docker inspect -f '{{ .Image }}' $weave_container 2>&1 | /bin/grep -q -v ^Error ",
    timeout => 600,
  }

  if $weave_manage_firewall {
    include weave::firewall::docker
    include weave::firewall::weave
    if is_string( $peers ){
      $peers_to_listen_to = split($peers, ' ')
    } elsif is_array( $peers ) {
      $peers_to_listen_to = $peers
    }
    weave::firewall::listen_to_peer { $peers_to_listen_to: }
  }

}

