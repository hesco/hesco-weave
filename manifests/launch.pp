
define weave::launch ( $ip, $peers ){

  $weave = hiera('ymd_docker::network::weave::script', '/usr/local/bin/weave')
  $weave_image = hiera('ymd_docker::network::weave::image', 'zettio/weave')
  $weave_container = hiera('ymd_docker::network::weave::container', 'weave')

  exec { "weave_launch_$ip":
    command => "$weave launch $ip $peers ",
     unless => "/usr/bin/docker inspect -f '{{ .Image }}' $weave_container 2>&1 | /bin/grep -v '^Error\|<no value>' -q",
    timeout => 600,
  }

}

