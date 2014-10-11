
define weave::interface ( $ensure, $ip, $container ) {

  $docker = hiera('weave::docker', '/usr/bin/docker')
  $weave = hiera('weave::script', '/usr/local/bin/weave')
  $docker_host_weave_ip = hiera('weave::docker_host_weave_ip', undef)

  validate_absolute_path( $weave )
  validate_absolute_path( $docker )
  if ! is_ip_address( $docker_host_weave_ip ) {
    validate_bool( [ "$docker_host_weave_ip is not a valid ip, fix hiera for weave::docker_host_weave_ip key" ] )
  }

  if ! is_ip_address( $ip ) {
    validate_bool( [ "$ip is not a valid ip for ethwe" ] )
  }

  # these tests are docker specific, though I suppose that weave could be 
  # used for other purposes and that these tests should perhaps take that into account.  
  if $ensure == 'present' {

    exec { "weave attach $ip $container":
      command => "$weave attach $ip $container ",
       unless => "/usr/local/bin/test_docker_container_for_ethwe -c $container -i $ip -a",
      require => [ Exec["weave_launch_$docker_host_weave_ip"],
                   Exec["restart_weave_for_$docker_host_weave_ip"] ],
    }

  } elsif $ensure == 'absent' {

    exec { "weave detach $ip $container":
      command => "$weave detach $ip $container ",
       unless => "/usr/local/bin/test_docker_container_for_ethwe -c $container -i $ip -d",
      require => [ Exec["weave_launch_$docker_host_weave_ip"],
                   Exec["restart_weave_for_$docker_host_weave_ip"] ],
    }

  } else {

    notify { 'invalid_ensure_value':
      message => "$ensure is an invalid value for the ensure attribute, try 'present' or 'absent' instead",
    }

  }

}

