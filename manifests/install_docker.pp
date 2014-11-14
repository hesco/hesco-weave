
class weave::install_docker (
  $ensure = $weave::params::ensure,
  $docker = $weave::params::docker,
) inherits weave::params {

  # package { [ 'ethtool',
  #             'conntrack' ]:
  #   ensure => $ensure,
  # }

  # file { '/root/lib/sh/purge_docker_firewall_rules.sh':
  #   source => 'puppet:///modules/weave/root/lib/sh/purge_docker_firewall_rules.sh',
  #    owner => 'root',
  #    group => 'root',
  #     mode => '0740',
  # }

  # file { '/root/lib/sh/purge_weave_firewall_rules.sh':
  #   source => 'puppet:///modules/weave/root/lib/sh/purge_weave_firewall_rules.sh',
  #    owner => 'root',
  #    group => 'root',
  #     mode => '0740',
  # }

  # exec { 'purge_docker_weave_firewall_rules':
  #   command => '/root/lib/sh/purge_docker_firewall_rules.sh && /root/lib/sh/purge_weave_firewall_rules.sh',
  #    unless => '/usr/bin/docker version | /bin/grep -q "Server version:"',
  #    before => Class['docker'],
  # }

  exec { 'purge_firewall_rules':
    command => '/root/lib/sh/flush_iptable_rules.sh',
     unless => '/usr/bin/docker version | /bin/grep -q "Server version:"',
     before => Class['docker'],
  }

  include docker

}

