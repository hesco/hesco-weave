
define weave::run ( $ip, $image, $options ){

  $docker = hiera('weave::docker', '/usr/bin/docker')
  $weave = hiera('weave::script', '/usr/local/bin/weave')
  $docker_host_weave_ip = hiera('weave::docker_host_weave_ip', undef)

  validate_absolute_path( $weave )
  validate_absolute_path( $docker )
  validate_string( $image )
  validate_string( $options )
  validate_bool( is_ip_address( $ip ) )

  exec { "weave run $ip $image":
    command => "$weave run $ip $options $image",
     unless => "$docker inspect -f '{{ .Image }}' $image 2>&1 | /bin/grep -v '^Error\|<no value>' -q ",
    timeout => 600,
     require => [ Exec["weave_launch_$docker_host_weave_ip"],
                  Exec["restart_weave_for_$docker_host_weave_ip"] ],
  }

}

