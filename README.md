```NAME```

hesco-puppet

```VERSION```

Version v0.02

This is alpha code and no promises are made at this early stage as to the stability 
of its interface, or its suitability for production use.  The weave project is still 
less than seven weeks and four hundred commits old.  I myself am still testing it 
with the hope of putting it to use in my own environment.  I found it the least 
confusing interface I could find for bridging docker containers across multiple 
docker hosts.  But getting it to work in my environment has alrady demanded that 
I dig in to its innards and learn more about software defined networks than I knew 
before.  

```SYNOPSIS```

Puppet module for managing a weave network on a docker cluster

Weave is a docker container hosted SDN router plus a shell script for managing an SDN 
on a docker cluster.  It is capable of bridging virtual networks across docker hosts, 
making it possible for containers deployed across different physical hosts to communicate 
with one another.  To learn more about weave, see:  https://github.com/zettio/weave

Architecturally, to make this work, one will want to use docker to deploy a weave router 
using the zettio/weave image from <a href="https://registry.hub.docker.com/u/zettio/weave/">the Docker hub</a>, 
on each docker host, by using the weave script to `weave launch` it.  The script will create 
a private bridge and establish peer relationships between multiple docker hosts.  

Then rather than using `docker run`, you will use the weave script's `weave run` command 
to wrap docker with additional code to configure the Software Defined Network around an 
arbitrary docker container.  

This puppet module exposes at this early stage of its development two defined types: weave::launch 
and weave::run to make these tools available from a puppet manifest.  It also manages the installation 
and uninstall of weave, its docker hosted router and packaged dependencies.  

```USAGE```

In my docker_host role class, I have this:

    class role::docker_host {

      $fqdn_normalized = regsubst($fqdn,'\.','_',"G")
        .  .  .  
      include 'my_docker'
      include 'weave'
      include "docker_cluster::hosts::${fqdn_normalized}"

    }

In actuality those four lines probably ought to be broken out into their own 
puppet profile.  

The my_docker module uses the garethr/docker module to install docker.  
The garethr module also exposes a couple of defined types used in the weave 
module and perhaps elsewhere in my internal codebase.

    class my_docker {
    
      include docker # <-- garethr/docker
      include my_docker::prereqs
      include my_docker::prereqs::utilities
      include my_docker::helper_scripts
    
    }

Including the hesco/weave module in role::docker_host, along with the following hiera 
settings, handles the installation (and uninstall) of the zettio/weave script and its 
supporting docker image, used to build a docker container hosting an SDN router.  

my /etc/puppet/hieradata/env/docker_cluster.yaml -- 

    weave::ensure: 'present' # <-- set to 'absent' to uninstall
    weave::docker: '/usr/bin/docker'
    weave::script: '/usr/local/bin/weave'
    weave::container: 'weave'
    weave::image: 'zettio/weave'
    weave::docker_cluster_peers: '<ip_address_01> <ip_address_02> <ip_address_03>'

my /etc/puppet/hieradata/nodes/docker_host_01.example.com.yaml -- 

    docker::param::version: '1.2.0'
    weave::docker_host_weave_ip: '10.0.0.1/16'

Finally, my "docker_cluster::hosts::${fqdn_normalized}" profile includes 
classes which look like this:

    class docker_cluster::db_servers::pg {
     
      $domain = 'pg.example.com'
      $image = $domain
      $ip = '10.0.1.16/29'
      $ports = '-p 5432:5432'
      $docker_run_opts = '--memory=2g --restart=always --net=bridge'
      $config = "-v /data/etc/postgresql/$domain:/etc/postgresql"
      $data = '-v /data/postgresql:/var/lib/postgresql'
      $log = "-v /data/var/log/postgresql/$domain:/var/log/postgresql"
      $backups = '-v /data/home/ymdbackups:/home/ymdbackups'
      $attach = "$config $data $log $backups"
      $options = "-d --name=\"$domain\" -h $domain $docker_run_opts $ports $attach "
     
      weave::run { "$domain $ip":
             ip => $ip,
          image => $image,
        options => $options,
      }
     
    }
 
In my mind, the garethr/docker module needs an additional defined type, docker::build, 
to hanlde the initial build of a docker container, from which the image used by weave::run 
can be launched with its additional ethwe weave bridge connected interface.  In the mean time, 
I am handling that step manually with a Dockerfile and a wrapper bash script to drive it.  
Those are all in my repository and deployed by: my_docker::helper_scripts.  

```CONTRIBUTIONS```

Please report bugs, feature requests and other issues at the 
<a href="https://github.com/hesco/hesco-weave">github site</a>, 
fork this code, add your test cases, patch it and send me back 
a Pull Request.  Lets see if working together we can turn this 
into something useful.  

```COPYRIGHT AND LICENSE```

Copyright Hugh Esco <hesco@campaignfoundations.com>

Released under the Gnu Public License.

