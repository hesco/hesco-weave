
define weave::simple::run ( $host_name ){  
  
  $docker = hiera('weave::docker', '/usr/bin/docker')  
  $weave = hiera('weave::script', '/usr/local/bin/weave')  
  $docker_host_weave_ip = hiera('weave::docker_host_weave_ip', undef)  
  
  validate_absolute_path( $weave )  
  validate_absolute_path( $docker )  
  validate_string( $host_name )  
  
  $dhcp = hiera('dockerhosts_dhcp')  
  $ip = $dhcp["$host_name"]['ip']  
  if ! is_ip_address( $ip ) {  
    notify { 'invalid_ip_address':  
      message => "host: $host_name has an invalid ip: $ip",  
    }  
  }  
  
  $image = $dhcp["$host_name"]['image']  
  validate_string( $image )  
  notify { 'the_image_is':  
    message => "The $host_name host uses the $image image.",  
  }  
  
  $build_options = hiera("$image")  
  if ! is_hash( $build_options ) {  
    notify { 'invalid_image':  
      message => "host: $host_name has an invalid image: $image, which failed to provide a hash of build options",  
    }  
  }  
  
  $docker_run_options = $build_options['docker_run_opts']  
  if is_array( $docker_run_options ) {  
    $docker_run_options_array = $docker_run_options  
  } else {  
    $docker_run_options_array = []  
  }  
  
  $exposed_ports = $build_options['ports']  
  if is_array( $exposed_ports ) {  
    $exposed_ports_array = $exposed_ports  
  } else {  
    $exposed_ports_array = []  
  }  
  
  $attach_volumes = $build_options['attach_volumes']  
  if is_array( $attach_volumes ) {  
    $attach_volumes_array = $attach_volumes  
  } else {  
    $attach_volumes_array = []  
  }  
  
  $run_ports_options = concat($exposed_ports_array,$docker_run_options_array)  
  $all_run_options = concat($run_ports_options,$attach_volumes_array)  
  $options = regsubst( join($all_run_options, ' '), 'DOMAIN', "$host_name", 'G')  
    
  if is_string( $options ) {  
  
    weave::run { "weave run $host_name at $ip":  
         host => $host_name,  
           ip => $ip,  
        image => $image,  
      options => $options  
    }  
  
  } else {  
  
    notify { "options is not a string":  
      message => "\$options is not a string, it is instead $options ",  
    }  

  }

}

