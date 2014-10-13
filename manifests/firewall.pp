
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
    source => $peer,
    action => accept,
  }

}

# -A INPUT -s 50.147.240.136/32 -p tcp -m state --state NEW -m tcp --dport 5432 -j accept
# -A INPUT -s 68.230.170.174/32 -p tcp -m state --state NEW -m tcp --dport 5432 -j accept
# -A INPUT -s 68.168.146.147/32 -p tcp -m state --state NEW -m tcp --dport 5432 -j accept
# -A INPUT -s 68.168.146.147/32 -p tcp -m state --state NEW -m tcp --dport 5433 -j accept
 
