
define weave::launch ( 
  $docker_host_weave_ip,
  $docker_cluster_peers,
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

}

