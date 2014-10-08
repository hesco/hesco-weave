
define weave::run ( $ip, $image $options ){ "":

  $weave = '/usr/local/bin/weave'

  exec { "weave run $ip $image":
    command => "$weave run $ip $options $image",
     unless => "/usr/bin/docker inspect -f "{{ .Image }}" $image 2>&1 | /bin/grep -v ^Error -q",
    timeout => 600,
  }

}

