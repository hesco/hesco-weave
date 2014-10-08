
define weave::run ( $ip, $image, $options ){

  $docker = hiera('ymd_docker::network::weave::docker', '/usr/bin/docker')
  $weave = hiera('ymd_docker::network::weave::script', '/usr/local/bin/weave')

  exec { "weave run $ip $image":
    command => "$weave run $ip $options $image",
     unless => "$docker inspect -f '{{ .Image }}' $image 2>&1 | /bin/grep -v '^Error\|<no value>' -q ",
    timeout => 600,
  }

}

