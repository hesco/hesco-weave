
define weave::launch ( 
  $docker_host_weave_ip,
  $docker_cluster_peers,
  $weave_manage_firewall,
){

  validate_bool( is_ip_address( $docker_host_weave_ip ) )

  $docker = getvar('weave::docker')
  $weave = getvar('weave::weave')
  $weave_container = getvar('weave::weave_container')

  exec { "weave_launch_$docker_host_weave_ip":
    command => "$weave launch $docker_host_weave_ip $docker_cluster_peers ",
     unless => "$docker inspect -f '{{ .Image }}' $weave_container 2>&1 | /bin/grep -v '^Error\|<no value>' -q",
    timeout => 600,
  }

  exec { "restart_weave_for_$docker_host_weave_ip":
    command => "$weave reset && $weave launch $docker_host_weave_ip $docker_cluster_peers ",
     unless => "$docker ps -a | /bin/grep $weave_container | /bin/grep -v Exited -q",
  }

  if $weave_manage_firewall {
    include weave::firewall
  }

}

