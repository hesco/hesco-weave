
define weave::firewall ( $peer ) {

  # must convert $weave::docker_cluster_peers into an array

  firewall { "06783 weave router ingress from $peer":
     chain => 'INPUT',
     dport => [ '6783' ],
     proto => [ tcp, udp ],
    source => $peer,
    action => accept,
  }

  firewall { "06783 weave router egress to $peer":
          chain => 'OUTPUT',
          dport => [ '6783' ],
          proto => [ tcp, udp ],
    destination => $peer,
         action => accept,
  }

}

