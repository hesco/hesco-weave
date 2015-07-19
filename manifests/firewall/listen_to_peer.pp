
define weave::firewall::listen_to_peer ( $peer ) {

  # must convert $weave::docker_cluster_peers into an array

  if $::ipaddress_eth0 == $peer {
    # notify { 'no firewall rules required for self': message => "peer: $peer, eth0: $::ipaddress_eth0" }
  } else {
    firewall { "06783 weave router ingress from $peer for tcp":
       chain => 'INPUT',
       dport => '6783',
       proto => 'tcp', 
      source => $peer,
      action => accept,
    }
  
    firewall { "06783 weave router ingress from $peer for udp":
       chain => 'INPUT',
       dport => '6783',
       proto => 'udp', 
      source => $peer,
      action => accept,
    }
  
    firewall { "06783 weave router egress to $peer for tcp":
            chain => 'OUTPUT',
            dport => '6783',
            proto => 'tcp',
      destination => $peer,
           action => accept,
    }
  
    firewall { "06783 weave router egress to $peer for udp":
            chain => 'OUTPUT',
            dport => '6783',
            proto => 'udp',
      destination => $peer,
           action => accept,
    }
  }

}

