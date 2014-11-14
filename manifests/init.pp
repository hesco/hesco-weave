
# == Class: weave
#
# puppet module for deploying and managing a docker network with weave 
#
# === Parameters
#
# [docker_host_weave_ip]
#   Required, in dotted quad/cidr notation, for the IP assigned in the weave 
#   managed private network to the docker host to which this class is 
#   being applied.  This can be passed across the interface, or configured 
#   in hiera as weave::docker_host_weave_ip.
#
# [docker_cluster_peers]
#   Required, a space delimited list of the already routable IPs for the 
#   docker hosts with which this docker host ought to peer in the weave 
#   managed private network.  This can be passed across the interface, or 
#   configured in hiera as weave::docker_cluster_peers.  
#
# === Variables
#
# The following may be set in hiera, or, without the 'weave::' prefix, 
# passed across the class interface.   
#
# [*weave::docker*]
#   fully qualified path to docker binary, defaults to '/usr/bin/docker'
#
# [*weave::weave*]
#   fully qualified path to weave shell script, defaults to '/usr/local/bin/weave'
#
# [*weave::weave_container*]
#   name of the router container run by ::launch, defaults to 'weave'
#
# [*weave::weave_image*]
#   name of the image used by ::launch, defaults to weave 'zettio/weave'
#
# [*weave::weave_image_tag*]
#  version tag for the image used by ::launch, defaults to 'latest'
#
# === Examples
#
#  /etc/puppet/hieradata/env/docker_cluster.yaml --
#    weave::docker_cluster_peers: '<ip_address_01> <ip_address_02> <ip_address_03>'
#
#  /etc/puppet/hieradata/nodes/docker_host_01.example.com.yaml -- 
#    docker::param::version: '1.2.0'
#    weave::docker_host_weave_ip: '10.0.0.1/16'
#    
#  class role::docker_host {
#
#    $fqdn_normalized = regsubst($fqdn,'\.','_',"G")
#       .  .  .  
#    include 'docker'
#    include 'weave'
#    include "docker_cluster::hosts::${fqdn_normalized}"
#
#  }
#
#  Now in the docker_cluster::hosts::${fqdn_normalized} profile, 
#    include docker_cluster::db_servers::pg
#    include . . . 
# 
#  class docker_cluster::db_servers::pg {
#   
#    $domain = 'pg.example.com'
#    $image = $domain
#    $ip = '10.0.1.16/29'
#    $ports = '-p 5432:5432'
#    $docker_run_opts = '--memory=2g --restart=always --net=bridge'
#    $config = "-v /data/etc/postgresql/$domain:/etc/postgresql"
#    $data = '-v /data/postgresql:/var/lib/postgresql'
#    $log = "-v /data/var/log/postgresql/$domain:/var/log/postgresql"
#    $backups = '-v /data/home/ymdbackups:/home/ymdbackups'
#    $attach = "$config $data $log $backups"
#    $options = "--name=\"$domain\" -h $domain $docker_run_opts $ports $attach "
#   
#    weave::run { "$domain $ip":
#           ip => $ip,
#        image => $image,
#      options => $options,
#    }
#   
#  }
# 
# For a more complete example, see the README.md file.
# 
# === Authors
#
# Hugh Esco <hesco@yourmessagedelivered.com> 
#
# === Copyright
#
# Copyright 2014 Hugh Esco, YMD Partners 

class weave (

  $docker_host_weave_ip  = $weave::params::docker_host_weave_ip,
  $docker_cluster_peers  = $weave::params::docker_cluster_peers,
  $docker                = $weave::params::docker,
  $weave                 = $weave::params::weave,
  $weave_container       = $weave::params::weave_container,
  $weave_image           = $weave::params::weave_image,
  $weave_image_tag       = $weave::params::weave_image_tag,
  $weave_manage_firewall = $weave::params::weave_manage_firewall,

) inherits weave::params {

  include stdlib
  # include firewall
  # include  docker

  validate_absolute_path( $weave )
  validate_absolute_path( $docker )
  validate_string( $weave_image )
  validate_string( $weave_image_tag )
  validate_string( $weave_conatiner )
  validate_bool( is_ip_address( $docker_host_weave_ip ) )
  # for $docker_cluster_peer in $docker_cluster_peers
  # validate_bool( is_ip_address( $docker_cluster_peer) )

  # notify { 'running weave::init': }
  anchor { 'weave::begin': } ->
  class { 'weave::install_docker': } ->
  class { 'weave::install_weave': } ->
  weave::launch { "$docker_host_weave_ip":
     docker_host_weave_ip => $docker_host_weave_ip,
     docker_cluster_peers => $docker_cluster_peers,
    weave_manage_firewall => $weave_manage_firewall,
  } ~>
  anchor { 'weave::end': }

}

