
# -A FORWARD -d 172.17.0.7/32 ! -i docker0 -o docker0 -p tcp -m tcp --dport 5432 -j ACCEPT
# -A DOCKER ! -i docker0 -p tcp -m tcp --dport 5432 -j DNAT --to-destination 172.17.0.7:5432

define weave::firewall::dnat_published_port ( $container_ip, $published_port, $protocol ) {

  firewall { "$rule_id FORWARD $published_port for $container_ip":
          chain => 'FORWARD',
          dport => [ $published_port ],
          proto => [ $protocol ],
    destination => $container_ip,
        iniface => '! docker0',
       outiface => 'docker0',
         action => accept,
  }

  firewall { "$rule_id dnat $published_port for $container_ip":
      table => 'nat',
      chain => 'DOCKER',
    iniface => '! docker0',
      proto => [ $protocol ],
      dport => [ $published_port ],
     todest => "$container_ip:$published_port",
       jump => 'DNAT',
  }

}

