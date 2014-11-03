
class weave::params {

  $ensure = hiera('weave::ensure', 'present')
  $docker = hiera('weave::docker', '/usr/bin/docker')
  $weave = hiera('weave::script', '/usr/local/bin/weave')
  $weave_container = hiera('weave::container', 'weave')
  $weave_image = hiera('weave::image', 'zettio/weave')
  $weave_image_tag = hiera( 'weave::weave_image_tag', 'latest' )
  $docker_host_weave_ip = hiera( 'weave::docker_host_weave_ip' )
  $docker_cluster_peers = hiera( 'weave::docker_cluster_peers' )
  $manage_firewall = hiera( 'weave::manage_firewall', false )

}

