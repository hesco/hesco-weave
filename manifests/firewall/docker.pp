
class weave::firewall::docker {

  # -A FORWARD -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  firewall { '00100 accept related, established traffic returning to docker0 bridge in FORWARD chain':
     action  => 'accept',
       proto => 'all',
       chain => 'FORWARD',
    outiface => 'docker0',
     ctstate => ['RELATED','ESTABLISHED'],
  }

  # -A FORWARD -i docker0 ! -o docker0 -j ACCEPT
  firewall { '00100 accept docker0 traffic to other interfaces on FORWARD chain':
     action  => 'accept',
       proto => 'all',
       chain => 'FORWARD',
     iniface => 'docker0',
    outiface => '! docker0',
  }

  # -A FORWARD -i docker0 -o docker0 -j ACCEPT
  firewall { '00100 accept docker0 to docker0 FORWARD traffic':
     action  => 'accept',
       proto => 'all',
       chain => 'FORWARD',
     iniface => 'docker0',
    outiface => 'docker0',
  }

  # -A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER 
  firewall { '00100 DOCKER table PREROUTING LOCAL traffic':
    dst_type => 'LOCAL',
       table => 'nat',
       proto => 'all',
       chain => 'PREROUTING',
        jump => 'DOCKER',
  }

  # -A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER 
  # does this belong in nat or filter table ???
  firewall { '00100 DOCKER chain, route LOCAL non-loopback traffic to DOCKER':
          table => 'nat',
       dst_type => 'LOCAL',
          chain => 'OUTPUT',
    destination => '! 127.0.0.1/8',
           jump => 'DOCKER',
  }

  # -A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
  firewall { '00100 DOCKER chain, MASQUERADE docker bridge traffic not bound to docker bridge':
       table => 'nat',
       chain => 'POSTROUTING',
       proto => 'all',
      source => "${::network_docker0}/16",
    outiface => '! docker0',
        jump => 'MASQUERADE',
  }

}

# iptables -F; iptables -F -t nat 
# docker -d & 
# generates this:

### # Generated by iptables-save v1.4.21 on Tue Oct 28 13:22:29 2014
### *filter
### :INPUT ACCEPT [40:5039]
### :FORWARD ACCEPT [0:0]
### :OUTPUT ACCEPT [47:7681]
### -A FORWARD -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
### -A FORWARD -i docker0 ! -o docker0 -j ACCEPT
### -A FORWARD -i docker0 -o docker0 -j ACCEPT
### COMMIT
### # Completed on Tue Oct 28 13:22:29 2014
### # Generated by iptables-save v1.4.21 on Tue Oct 28 13:22:29 2014
### *nat
### :PREROUTING ACCEPT [1:60]
### :INPUT ACCEPT [1:60]
### :OUTPUT ACCEPT [1:73]
### :POSTROUTING ACCEPT [1:73]
### :DOCKER - [0:0]
### -A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
### -A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER
### -A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
### COMMIT
### # Completed on Tue Oct 28 13:22:29 2014

