
class weave (

  $docker               = $weave::params::docker,
  $weave                = $weave::params::weave,
  $weave_container      = $weave::params::weave_container,
  $weave_image          = $weave::params::weave_image,
  $weave_image_tag      = $weave::params::weave_image_tag,
  $docker_host_weave_ip = $weave::params::docker_host_weave_ip,
  $docker_cluster_peers = $weave::params::docker_cluster_peers,

) inherits weave::params {

  include stdlib
  include firewall
  include docker

  validate_absolute_path( $weave )
  validate_absolute_path( $docker )
  validate_string( $weave_image )
  validate_string( $weave_image_tag )
  validate_string( $weave_conatiner )
  validate_bool( is_ip_address( $docker_host_weave_ip ) )
  # for $docker_cluster_peer in $docker_cluster_peers
  # validate_bool( is_ip_address( $docker_cluster_peer) )

  anchor { 'weave::begin': } ->
  class { 'weave::install': } ->
  weave::launch { "$docker_host_weave_ip":
    docker_host_weave_ip => $docker_host_weave_ip,
    docker_cluster_peers => $docker_cluster_peers,
  } ~>
  anchor { 'weave::end': }

}

