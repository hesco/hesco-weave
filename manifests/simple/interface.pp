# == Type: weave::simple::interface
#
# defined type to wrap weave::interface's three required arguments with two, keyed to hiera hash
#
# === Parameters
#
# [host_name]
# a fully qualified host name is recommended, should be a key in hiera data's 
# dockerhosts_dhcp hash, with its own ip key.  
#
# [ensure]
# supports 'present' and 'absent'
#
# === Variables
#
# This defined type expects the following to be set in hiera:
#
# /etc/puppet/hieradata/dhcp.yaml -- 
#
# [*dockerhosts_dhcp::$host_name::ip*]
# an IP in dot-quad/cidr format on the weave bridge to be assigned to the container
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

define weave::simple::interface ( $host_name, $ensure ) {

  validate_string( $host_name )
  if ! is_domain_name( $host_name ) {
    notify { 'invalid_host_name':
      message => "$host_name is an invalid domain name",
    }
    validate_bool( [ "$host_name is not a valid domain name" ] )
  }

  validate_re( $ensure, [ '^present$', '^absent$' ] )

  $dhcp = hiera('dockerhosts_dhcp')
  $ip = $dhcp["$host_name"]['ip']
  $ip_test = regsubst( $ip, '^(.*)/(.*)$', '\1' )
  $ip_cidr_test = regsubst( $ip, '^(.*)/(.*)$', '\2' )
  if ! is_ip_address( $ip_test ) {
    notify { 'invalid_ip_address':
      message => "host: $host_name has an invalid ip: $ip, fix [$host_name][ip] in dockerhosts_dhcp",
    }
    validate_bool( [ "$ip is not a valid ip" ] )
  }

  if ( $ip_cidr_test < 4 or $ip_cidr_test > 32 ) {
    notify { 'invalid_cidr_subnet':
      message => "host: invalid ip: $ip, CIDR out of range, fix [$host_name][ip] in dockerhosts_dhcp",
    }
    validate_bool( [ "$ip is not a valid ip, CIDR out of range" ] )
  }

  weave::interface { "Ensure ethwe (bound to $ip) $ensure on $host_name":
       ensure => $ensure,
           ip => $ip,
    container => $host_name,
  }

}

