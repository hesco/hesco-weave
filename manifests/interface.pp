
define weave::interface ( $ensure, $ip, $container ) {

  $docker = hiera('weave::docker', '/usr/bin/docker')
  $weave = hiera('weave::script', '/usr/local/bin/weave')
  $docker_host_weave_ip = hiera('weave::docker_host_weave_ip', undef)

  validate_absolute_path( $weave )
  validate_absolute_path( $docker )
  if ! is_ip_address( $docker_host_weave_ip ) {

    validate_bool( [ "$docker_host_weave_ip is not a valid ip" ] )

  }

  if ! is_ip_address( $ip ) {

    validate_bool( [ "$ip is not a valid ip" ] )

  }

  if $ensure == 'present' {

    exec { "weave attach $ip $container":
      command => "$weave attach $ip $container ",
       unless => "IP=$(/usr/bin/docker inspect --format '{{ .NetworkSettings.IPAddress }}' $container) && RAW_IP=$(/bin/echo '$ip' | /bin/sed \"s,/.*$,,\") && /usr/bin/ssh $IP \"/sbin/ifconfig ethwe \" | /bin/grep -q $RAW_IP",
      require => [ Exec["weave_launch_$docker_host_weave_ip"],
                   Exec["restart_weave_for_$docker_host_weave_ip"] ],
    }

  } elsif $ensure == 'absent' {

    exec { "weave detach $ip $container":
      command => "$weave detach $ip $container ",
       unless => "IP=$(/usr/bin/docker inspect --format '{{ .NetworkSettings.IPAddress }}' $container) && RAW_IP=$(/bin/echo '$ip' | /bin/sed \"s,/.*$,,\") && RESULT=$(/usr/bin/ssh $IP \"/sbin/ifconfig ethwe \" | /bin/grep $RAW_IP | wc -l) && /usr/bin/test \"$RESULT\" == \"1\"",
      require => [ Exec["weave_launch_$docker_host_weave_ip"],
                   Exec["restart_weave_for_$docker_host_weave_ip"] ],
    }

  } else {

    notify { 'invalid_ensure_value':
      message => "$ensure is an invalid value for the ensure attribute, try 'present' or 'absent' instead",
    }

  }

}

