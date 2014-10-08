
define weave::launch ( $ip, $peers ){ "":

  $weave = '/usr/local/bin/weave'
  $weave_image = 'zettio/weave'

  exec { "weave launch $ip $peers":
    command => "$weave launch $ip $peers ",
     unless => "/usr/bin/docker inspect -f "{{ .Image }}" $weave_image 2>&1 | /bin/grep -v ^Error -q",
    timeout => 600,
  }

}

