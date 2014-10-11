
class weave::install (
  $ensure = $weave::params::ensure,
  $weave = $weave::params::weave,
  $docker = $weave::params::docker,
  $weave_image = $weave::params::weave_image,
  $weave_image_tag = $weave::params::weave_image_tag,
  $weave_container = $weave::params::weave_container,
) inherits weave::params {

  package { [ 'ethtool',
              'conntrack' ]:
    ensure => $ensure,
  }

  # wget -O weave/files/usr/local/bin/weave https://raw.githubusercontent.com/zettio/weave/master/weaver/weave
  file { "$weave": 
    ensure => $ensure,
    source => "puppet:///modules/weave${weave}",
      mode => '0755',
  }

  file { '/usr/local/bin/test_docker_container_for_ethwe':
    source => 'puppet:///modules/weave/usr/local/bin/test_docker_container_for_ethwe',
      mode => '0755',
  }

  docker::image { "$weave_image":
       ensure => $ensure,
    image_tag => $weave_image_tag,
  }

  if member(['absent','purged'], $ensure){ 

    exec { 'docker_rm_weave_container':
      command => "$docker stop $weave_container && $docker rm $weave_container",
    }

    notify { "ensure is $ensure": }

  }

}

