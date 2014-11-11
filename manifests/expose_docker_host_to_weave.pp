
define weave::expose_docker_host_to_weave {

  $weave_expose_ip = hiera( 'weave::expose_ip', undef )
  exec { "weave expose $weave_expose_ip":
    command => "/usr/local/bin/weave expose $weave_expose_ip",
     unless => "/bin/echo $weave_expose_ip | /bin/grep -q $::ipaddress_weave",
  }

}

