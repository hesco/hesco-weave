# weave

#### Table of Contents

1. [Name](#name)
2. [Version](#version)
3. [Synopsis](#synopsis)
4. [Installation - The basics of getting started with weave](#installation)
    * [Setup requirements](#setup-requirements)
    * [What weave affects](#what-weave-affects)
5. [Usage - Configuration options and additional functionality](#usage)
    * [Organizing your puppet manifests](#organizing-your-puppet-manifests)
        * [The role::docker_host](#the-docker_host-role)
        * [the docker_weave profile ](#the-docker_weave-profile)
        * [Manage state for containers on a docker host](#manage-state-for-containers-on-a-docker-host)
        * [Manages firewall on a docker host](#manages-firewall-on-a-docker-host)
    * [Setting up hiera data](#setting-up-hiera)
        * [/etc/puppet/hiera.yaml](#etcpuppethierayaml)
        * [/etc/puppet/hieradata/dhcp.yaml](#etcpuppethieradatadhcpyaml)
        * [/etc/puppet/hieradata/docker_build_options.yaml](#etcpuppethieradatadocker_build_optionsyaml)
        * [/etc/puppet/hieradata/nodes/dockerhost001.example.com.yaml](#etcpuppethieradatanodesdockerhost001examplecomyaml)
    * [The base weave:: classes and types](#the-base-weave-defined-types-and-classes)
        * [Use weave::run to configure containers](#use-weaverun-type-to-configure-containers)
        * [Use weave::interface - enforce ethwe state on containers](#use-weaveinterface-to-enforce-ethwe-state-on-containers)
        * [Use weave::expose_docker_host_to_weave](#use-weaveexpose_docker_host_to_weave)
    * [Use weave::simple:: to leverage hiera data](#use-weavesimple-to-leverage-hiera-data)
        * [Use weave::simple::run narrows interface to weave::run](#use-weavesimplerun-to-leverage-hiera)
        * [Use weave::simple::interface narrows interface to weave::interface](#use-weavesimpleinterface-to-leverage-hiera)
    * [Use weave::firewall - manage docker host firewall for weave](#use-weavefirewall---manage-docker-host-firewall-for-weave)
        * [Use weave::firewall::docker](#use-weavefirewalldocker)
        * [Use weave::firewall::weave](#use-weavefirewallweave)
        * [Use weave::firewall::dnat_published_port](#use-weavefirewalldnat_published_port)
        * [Use weave::firewall::listen_to_peer](#use-weavefirewalllisten_to_peer)
6. [Facts](#facts-exposed-by-module)
    * [$::weave_router_ip_on_docker_bridge](#weave_router_ip_on_docker_bridge)
    * [$::docker_hosted_containers](#docker_hosted_containers)
7. [Reference - An under-the-hood peek at what the module is doing and how](#reference) # PENDING
8. [Limitations - Caveats, OS compatibility, etc.](#limitations)
9. [Development - Guide for contributing to the module](#development)
10. [To-Do](#to-do)
    * [To-Do tasks for hesco-weave](#to-do-tasks-for-hesco-weave)
        * [Roadmap for version 0.9.x release](#on-the-roadmap-for-the-09x-release)
        * [Features slated for future releases](#features-planned-for-future-releases)
    * [To-Do tasks for other projects](#to-do-tasks-for-other-projects)
11. [Copyright and License](#copyright-and-license)

# NAME

hesco-weave -- puppet module for deploying and managing a docker network with weave

# VERSION

Version v0.8.7

This is alpha code and no promises are made at this early stage as to the stability
of its interface, or its suitability for production use.  The weave project is still
less than three months and barely 900 commits old.  I myself after a month of testing 
and integration with my own environment am on the verge of tagging the v0.8 release 
of this project only now just beginning to roll out production services dependent 
on the bridged network it provides.  

# SYNOPSIS

hesco/weave is a puppet module for managing a weave network on a docker cluster

Weave is a docker container hosted SDN router plus a shell script for managing an SDN
on a docker cluster.  It is capable of bridging virtual networks across docker hosts,
making it possible for containers deployed across different physical hosts (even in 
different data centers) to communicate with one another.  To learn more about 
[weave, click here](https://github.com/zettio/weave).

I found it the least confusing interface I could find for bridging docker containers 
across multiple docker hosts.  But getting it to work in my environment has alrady 
demanded that I dig in to its innards and learn more about software defined networks 
than I might have hoped as a developer who has always deferred to a 'real network 
engineer' on those jobs where one has existed.  I am far more comfortable with the 
subject than when I started, and have endevoured to embed what I have learned from 
those subject matter experts who have been so kind as to answer my many question back 
upstream to the weave project and into this module, so perhaps my future self and you 
might not need to make the same deep dive into the subject.  

Architecturally, to make this work, one will want to use docker to deploy a weave router
using the [zettio/weave image from the Docker Hub](https://registry.hub.docker.com/u/zettio/weave/),
on each docker host, by using the weave script to `weave launch` it.  The script will create
a private bridge and establish peer relationships between multiple docker hosts.

Then rather than using `docker run`, you will use the weave script's `weave run` command
to wrap docker with additional code to configure the Software Defined Network around an
arbitrary docker container.

This puppet module exposed in version 0.7.2, at still an early stage of its development 
three defined types: `weave::launch`, `weave::run` and `weave::interface` to make these 
tools available from a puppet manifest.  It also manages the installation and uninstall 
of weave, its docker hosted router and packaged dependencies.

With version 0.8.x, this module will also add weave::simple::(run|interface) defined types, 
which wrap the version 0.7.x base types, with a more simple interface which relies on hiera 
data for its arguments.  Version 0.8.x also introduces weave::expose_docker_host_to_weave, 
plus the weave::firewall::(docker|weave) classes, two new defined types: 
weave::firewall::(dnat_published_port|listen_to_peer) plus two new facter facts: 
$::weave_router_ip_on_docker_bridge and $::docker_hosted_containers, 
which exposes a json hash of `docker inspect <container>` output.

# INSTALLATION

[This module has been published to the puppet forge](https://forge.puppetlabs.com/hesco/weave).
and can be installed like so:

    # puppet module install -i /etc/puppet/modules hesco/weave

Read `puppet help module install` for other useful options.

For the latest and greatest and potentially less than stable changes, 
you might consider cloning the bleeding edge of development as follows:

    # cd /etc/puppet/modules
    # git clone https://github.com/hesco/hesco-weave.git

# Setup Requirements

If you install this from the git repository rather than from the forge,
dependencies must be managed manually.  This module requires:

    * [garethr/docker](https://forge.puppetlabs.com/garethr/docker)
    * [puppetlabs/stdlib](https://forge.puppetlabs.com/puppetlabs/stdlib)
    * [puppetlabs/firewall](https://forge.puppetlabs.com/puppetlabs/firewall)

The firewall module is intended to support features exposed by weave::firewall:: classes 
and types.  Until such time as this patch is accepted into the upstream project, it 
also requires [being patched as described in this pull request](https://github.com/puppetlabs/puppetlabs-firewall/pull/433).  

## What weave affects

`weave` -- 
This is your public access to the weave::install_* and weave::launch private classes.  

`weave::install_docker` --
purges existing iptables ruleset and invokes docker class to install and daemonize docker

`weave::install_weave` --
installs packages for `ethtool` and `conntrack`
deploys a pinned version of `/usr/local/bin/weave`
Read the source for instructions on manually upgrading the weave script.  
We continue to wait for the weave project to [tag their project with 
semantic version numbers](https://github.com/zettio/weave/issues/110) 
before a future version of this module can [manage up/down grades](../../issues/10) 
the puppet way.  

`weave::launch` --
will run `docker pull zettio/weave` to grab the `:latest` docker image
use the weave script to `weave launch` a weave router as a docker container
set up a weave bridge and associated network interfaces
reset and restart the weave container if it crashes

`weave::run` --
invokes `weave run` which wraps `docker run` to deploy a docker container from an image
creates weave interfaces, uses them to attach a container to the weave bridge, and assign 
a user designated IP on the weave network to the ethwe interface

`weave::interface` --
enforces state (present and absent, supported) for an ethwe interface on a container
this defined type can be used to retroactively attach existing docker containers to a new weave router

`weave::expose_docker_host_to_weave` -- 
runs `weave expose` to add an IP routable from the weave bridge to the weave interface on the docker host, 
permitting the host to communicate with its hosted virtualized containers using the weave bridge.

`weave::simple::run` --
Provides a leaner interface to wrap weave::run and depends on hiera data.

`weave::simple::interface` --
Provides a leaner interface to wrap weave::interface and depends on hiera data.

`weave::firewall::docker` --
Class to replicate docker generated iptables rule set, under management by puppetlabs/firewall.

`weave::firewall::weave.pp` --
Class to replicate weave generated iptables rule set, under management by puppetlabs/firewall.

`weave::firewall::listen_to_peer --
Type to open port 6783 on INGRESS and EGRESS chains to a docker host designated 
as a peer on weave network.

`weave::firewall::dnat_published_port` --
Type permitting one to FORWARD and MASQUERADE -p(ublished) container ports 
across the docker bridge so that public internet traffic gets to and back 
from docker containers.  

# USAGE

## Organizing your puppet manifests

### the docker_host role

My docker_host role class, looks like this:

    class role::docker_host { include profile::docker_weave }

### the docker_weave profile 

The `docker_weave` profile uses the `garethr/docker` module to install docker.
The garethr module also exposes a couple of defined types used in the weave
module and perhaps elsewhere in my internal codebase.

    class profile::docker_weave {

      $fqdn_normalized = regsubst($fqdn,'\.','_',"G")
        .  .  .  
      include docker
      # <-- garethr/docker
      include weave
      # <-- this hesco/weave module
      include weave::expose_docker_host_to_weave

      include "docker_cluster::hosts::${fqdn_normalized}"
      include "docker_cluster::ipitables::${fqdn_normalized}"

    }

### Manage state for containers on a docker host

    class docker_cluster::hosts::dockerhost001_example_com {

      include docker_cluster::db_servers::pg
      include docker_cluster::web_servers::rt
        .  .  .  

    }

    class docker_cluster::web_servers::rt {

      weave::simple::run { 'weave_run rt.example.com': host_name => 'rt.example.com' }
      weave::simple::interface { 'rt.example.com ethwe interface': host_name => 'rt.example.com', ensure => 'present' }

    }

### Manages firewall on a docker host

    class docker_cluster::iptables::dockerhost001_example_com {

      include iptables
      include my_docker::iptables
      include postfix::iptables
      include my_postgresql::iptables
      include puppet::iptables
      include my_rabbitmq::iptables
      include git::gitolite::iptables
        .  .  .  

    }

The puppetlabs/firewall module encourages one to keep the firewall rules close to the configuration 
for the application it supports, so postfix::iptables will open ports 25 and 587 without worrying 
about the ssh daemon and your database.  

    class my_docker::iptables {
    
      include weave::firewall::docker
      include weave::firewall::weave
    
      $peers = hiera( 'weave::docker_cluster_peers_array', undef )
    
      # defined type includes sanity check Notify[no firewall rules required for self], testing eth0
      weave::firewall::listen_to_peer { "weave_listen_to_peer_this.peers.public.ipaddr": peer => 'this.peers.public.ipaddr' }
      weave::firewall::listen_to_peer { "weave_listen_to_peer_that.peers.public.ipaddr": peer => 'that.peers.public.ipaddr' }
      weave::firewall::listen_to_peer { "weave_listen_to_peer_some_other.peers.public.ipaddr": peer => 'some_other.peers.public.ipaddr' }
    
    }

## setting up hiera

Including the [hesco/weave](https://github.com/hesco/hesco-weave) module (`include weave`) 
in profile::docker_weave, along with the following hiera settings, handles the installation 
(and uninstall) of the `zettio/weave` script and its supporting docker image, used to build 
a docker container hosting an SDN router.

### /etc/puppet/hiera.yaml

    ---
    :backends:
      - yaml
    :yaml:
      :datadir: /etc/puppet/hieradata
    :hierarchy:
      - defaults
      - dhcp
      - docker_build_options
      - "node/%{clientcert}"
      - "env/%{environment}"
      - global

### /etc/puppet/hieradata/dhcp.yaml

    ---

    weave::ensure: 'present' # <-- set to 'absent' to uninstall
    weave::docker: '/usr/bin/docker'
    weave::script: '/usr/local/bin/weave'
    weave::container: 'weave'
    weave::image: 'zettio/weave'
    # above settings are the defaults, though they can be over-ridden here
    # module consumer responsible for configuration below
    weave::docker_cluster_peers: '<ip_address_01> <ip_address_02> <ip_address_03>'

    docker_hosts_weave_dhcp:
      - hostname: dockerhost001.example.com
        ip: 10.0.0.1/16
      - hostname: dockerhost002.example.com
        ip: 10.0.0.2/16
      - hostname: dockerhost003.example.com
        ip: 10.0.0.3/16
      # additional array entry for each docker host

    dockerhost_dhcp:
      puppet.example.com:
        hostname: puppet.example.com
        image: puppetmaster
        ip: 10.0.1.11/24
        host: dockerhost001
      pg.example.com:
        hostname: pg.example.com
        image: postgresql
        ip: 10.0.1.21/24
        host: dockerhost001
      rt.example.com:
        hostname: rt.example.com
        image: rt 
        ip: 10.0.1.31/24
        host: dockerhost002
     # additional key->hash definition for each container

Note that in the dockerhost_dhcp hash, the keys are hostnames, which will 
be used as arguments to the `weave::simple::*` types, which will pull and 
validate this hiera data, and use the image value as a key to access the data 
from the docker_build_options.yaml hiera data described next.  

### /etc/puppet/hieradata/docker_build_options.yaml

    ---

    puppetmaster:
      ports:
        - '-p 8140:8140/tcp'
      docker_run_opts:
        - '--memory=1g'
        - '--restart=always'
        - '--net=bridge'
        - '--name="DOMAIN"'
        - '--privileged=true'
        - '-h DOMAIN'
      attach_volumes:
        - "-v /data/etc/apache2/DOMAIN:/etc/apache2 "
        - "-v /data/etc/puppet/DOMAIN:/etc/puppet "
        - "-v /data/var/log/apache2/DOMAIN:/var/log/apache2 "
        - "-v /data/var/log/puppet/DOMAIN:/var/log/puppet "

    pg:
      ports:
        - '-p 5432:5432'
      docker_run_opts:
        - '--memory=2g'
        - '--restart=always'
        - '--net=bridge'
        - '--name="DOMAIN"'
        - '-h DOMAIN'
      attach_volumes:
        - "-v /data/etc/postgresql/DOMAIN:/etc/postgresql"
        - "-v /data/postgresql:/var/lib/postgresql"  
        - "-v /data/var/log/postgresql/DOMAIN:/var/log/postgresql"
        - "-v /data/home/backups:/home/backups"

    rt:
      ports:
      docker_run_opts:
        - '--memory=1g'
        - '--restart=always'
        - '--net=bridge'
        - '--name="DOMAIN"'
        - '-h DOMAIN'
      attach_volumes:
        - "-v /data/usr/share/request-tracker4/DOMAIN:/usr/share/request-tracker4"
        - "-v /data/var/log/apache2/DOMAIN:/var/log/apache2/DOMAIN"
        - "-v /data/var/log/request-tracker4/DOMAIN:/var/log/request-tracker4"
        - "-v /data/etc/apache2/DOMAIN:/etc/apache2"
        - "-v /data/etc/request-tracker4/DOMAIN:/etc/request-tracker4"

    # additional key->hash definition for each docker image type

`weave::simple::run` will parse these `docker run` options from hiera and use 
them to set up your containers.  The keys are image names, and this assumes that 
you have previously used `docker build` to create these base images.  

I have been advised that by deploying a weave network, I can now disable 
the docker bridge, by setting `--net=none`.  But for the moment I continue 
to use ithe docker bridge to manage the containers from the docker hosts, 
even while I intend to use the weave bridge for inter-container communication, 
particularly cross-docker-hosts.  

### /etc/puppet/hieradata/nodes/dockerhost001.example.com.yaml

    ---

    docker::param::version: '1.3.0'
    # this next line may have been deprecated
    # by $docker_hosts_weave_dhcp[n]['ip']
    weave::docker_host_weave_ip: '10.0.0.1/16'

## The base weave:: defined types and classes

This module includes several private classes used to manage the initial installation 
configuration and launching of the weave SDN router (in a docker container), as well 
as the docker daemon if that is not already present.  But as a module consumer you 
really only need to know about this one class:  

    include weave

### use weave::run type to configure containers

Originally this module exposed this defined type to wrap the `weave run` command 
which runs a container given an image.  Its five required arguments seemed a bit 
clumsy as an interface.  So in a moment I'll show you the weave::simple::run type 
which now wraps this with hiera data and a narrower interface.  

    weave::run { "weave run $host_name at $ip":
         host => $container_name,
           ip => $weave_routable_ip/cidr,
        image => $image,
      options => $options
    }

For the early adopters, the host key in this invocation was new to version v0.7.2 
and was necessary to resolve the [bug described here](../../issues/7).

Under the hood `weave::run` is calling the `weave` script which wraps a call to `docker run` with 
additional bash code to plumb the weave network on to the docker container and into the docker hosts 
firewall.  

### use weave::interface to enforce ethwe state on containers

And to enforce state, or to retroactively attach existing containers launched 
with `docker run` rather than `weave run` or the methods exposed by this module:
 
    weave::interface { "Ensure ethwe (bound to $ip) $ensure on $host_name":
         ensure => $ensure,
             ip => $weave_routable_ip/cidr,
      container => $host_name,
    }

### Use weave::expose_docker_host_to_weave

This class executes the `weave expose` command to assign an IP address (from hiera) to the weave 
interface, on the weave bridge, so that the docker host can communicate with containers hosted 
by itself or by its peers attached to the weave bridge.  

## Use weave::simple:: to leverage hiera data

The `weave::simple::*` defined types in general wrap the base types, providing a narrower interface 
deriving the rest of the necessary arguments from hiera lookups and providing data validation.  If 
you use hiera, these types will be easier to use than the base types.  

### Use weave::simple::run to leverage hiera

My `"docker_cluster::hosts::${fqdn_normalized}"` profile includes defined type 
invocations which look like this:

    weave::simple::run { 'weave_run rt.example.com': host_name => 'rt.example.com' }

This ::simple type requires only a single argument used to key the rest of the data 
from the hiera data structure which is necessary for the wrapped `weave::run` type.  

### Use weave::simple::interface to leverage hiera

my `docker_cluster::hosts::${fqdn_normalized}` profile also now includes: 

    weave::simple::interface { 'rt.example.com ethwe interface':
      host_name => 'rt.example.com',
         ensure => 'present',
    }

Wrapping `weave::interface` 

## Use weave::firewall - manage docker host firewall for weave

The use of the weave::firewall:: classes and types is optional and requires setting 
a weave::mangage_firewall option in hiera.  

These features enable puppet driven firewall management without breaking a reliable 
cross-docker-host bridge under its use.  It was motivated by the resistence of the 
docker/weave iptables rule sets to playing well with a puppet managed firewall.  So 
essentially this module will replicate what those tools do, in the puppet way, so all 
the components will play well together.  

This feature is dependent on the [puppetlabs/firewall](https://forge.puppetlabs.com/puppetlabs/firewall) 
module available from the puppet forge.  In addition, it requires a [patch described here](https://tickets.puppetlabs.com/browse/MODULES-1470), 
to the puppetlabs/firewall module and included in [this pending pull request](https://github.com/puppetlabs/puppetlabs-firewall/pull/433).  

This pull request supports the negation of an -i or -o interface switch in an iptables rule, 
actually the iniface and outiface attributes to the Firewall[] resource, which translates 
into the -i and -o switches on an iptables rule, respectively.  Hopefully that pull 
request will soon make it into the upstream project and when that has happened, 
this feature should work without patching a future version of the firewall module.  

Although not necessary for weave::firewall::, this patch will also support 
interface aliases, useful for assigning multiple IPs to the same physical nic.  

Use of this feature is enabled by setting 'weave::manage_firewall' to a true value in 
your hiera data.  

    /etc/puppet/hieradata/node/dockerhost001.example.com.yaml -- 

    weave::manage_firewall: true

Enabling this feature will permit you to manage the firewall for other services on your 
docker host using the resources and types exposed by the puppetlabs/firewall module.  
Rules generated by this module use five digit zero-padded rule id numbers, which 
correspond with the port number to which they relate.  If you use the same convention 
for numbering the rest of your rules, you will find your rule set organized in a sane way.  
This feature also permits you to lock down your installation with `-j REJECT` rules at the 
end of your chains and open up your ssh port and other ports necessary so you do not get 
locked out.  

(For the reasoning behind the five digit rule numbering convention, see [Alex Cline's 2011 
"Advanced Firewall Manipulation Using Puppet"](http://alexcline.net/2012/03/16/advanced-firewall-manipulation-using-puppet/).  

### Use weave::firewall::docker

Docker depends on and manages its own Software Defined Network, using brctl (?) under the hood 
to create a docker0 bridge, the ip utility (?) to create paired veth virtual interfaces, one 
in each container, matched with one on the docker host, all connected to the docker0 bridge.  
The docker binary provides a --net switch which allows this to be turned off if you wish, 
or otherwise configured.  It is also possible to run the docker0 bridge alongside the weave bridge.  

To manage traffic between the docker host and the containers as well as among the containers, 
docker manages the creation of a handful of rules in the \*filter tables' FORWARD chain, and creates 
its own DOCKER chain in the \*nat table.  Including this class will purge and recreate those 
firewall rules using puppetlabs/firewall module.

    include weave::firewall::docker

### Use weave::firewall::weave

Similarly, the weave command line script which comes packaged with the weave SDN router (in a 
docker container) also creates a handful of firewall rules added to the \*nat table, including 
its own WEAVE chain.  Inclusion of this class is intended to replicate those rules purged when 
weave::manage_firewall is enabled.  In your docker/weave profile, you should also add this class 
like so:

    include weave::firewall::weave

### Use weave::firewall::dnat_published_port

When you run a docker container with a published port (the -p switch to the `docker run` 
command, perhaps with EXPOSE in your Dockerfile), docker will add a pair of rules to your 
firewall, one in the FORWARD chain, the other on the DOCKER chain in the \*nat table.  
If you set the weave::manage_firewall option to true, you become responsible for recreating 
these rules yourself.  This defined type is provided to facilitate your doing so.  
Of the following arguments, all are required except for public_ip, which defaults to 
'0.0.0.0', to listen on all IP's, all interfaces.  

    weave::firewall::dnat_published_port { 'dnat puppet.example.com':
        container_ip =>  $::docker_hosted_containers['puppet.example.com']['NetworkSettings']['IPAddress'],
      published_port => '8140',
            protocol => 'tcp',
           public_ip => 'your.public.ip.addr',
    }

### Use weave::firewall::listen_to_peer

Currently the weave command line script does not manage this for you, but its documentation 
advises that you need to open up your firewall to permit tcp and udp packets between the 
weave routers on your peer'd docker hosts.  This defined type exists to make that easy, 
using the power of puppetlabs/firewall module underneath to create appropriate INGRESS 
and EGRESS rules.  You can use it like so:

    if $::ipaddress_eth0 != '<routable.ip_address.for.peered_docker_host>' {
      weave::firewall::listen_to_peer { "weave_listen_to_peer_<routable.ip_address.for.peered_docker_host>": peer => '<routable.ip_address.for.peered_docker_host>' }
    }

# FACTS EXPOSED BY MODULE

## $::weave_router_ip_on_docker_bridge

This returns a string, an IP address assigned to the weave router which can be reached 
from the docker bridge.  It is used internally by this module to configure the firewall, 
and might be useful to the module consumer for accessing the router logs.

## $::docker_hosted_containers

This returns a hash with the keys: docker_host, container_ids, container_count and for each 
hosted container, its hostname or docker0 IP address as a key related to that container's 
`docker inspect` output as its value.  This fact exposes to your puppet manifests the entire 
output for `docker inspect`, and its data can be accessed using the same keys as one would 
using the docker client directly.  If from a command line you would access your required 
data like so:

    /usr/bin/docker inspect -f '{ .NetworkSettings.IPAddress }' puppet.example.com

Then from inside your manifest that same ip address assigned to the container's docker0 interface 
can be accessed like so:

    $::docker_hosted_containers['puppet.example.com']['NetworkSettings']['IPAddress']

and in fact, that is exactly how it is used to NAT the container in the firewall.  

# REFERENCE

Pending . . . 

# LIMITATIONS

If you are one of the first few early adopters who used the github repository to interact with this 
module, consider yourself warned that I have rewritten public history by updating tags as described 
in the Changlog.  Tags v0.0.4, v0.01, v0.02, v0.03, v0.04, v0.05 and v0.06 are no longer present 
in the public repository.  These changes were made to comply with the versioning standards outlined 
at semver.org and necesssary to upload releases to the puppet forge.  Apparently leading zeros are 
not supported.  Who knew?

So far this has only been tested on Debian, jessie/testing.  Reports of your experiences
with this code in other environments are appreciated, particularly when they include tests
and patches, particularly when they come in the form of a Pull Request, even if only to
patch this README.md to report on success or failure of this module in your environment.

As of this writing, enabling the the weave::firewall:: functionality by setting weave::manage_firewall 
in hiera only a day ago was still breaking the weave bridge between docker hosts.  After extensive 
and pain-staking debugging till late last night, the bridge has been stable all day, and in the morning 
I will begin the process of deploying my first production services to the environment this module manages 
(which I continue to monitor closely).  I still consider this feature in the version 0.8.x release beta 
quality.  It is offered with all of the usual disclaimers.  Caveat Emptor.  

# DEVELOPMENT

Please report bugs, feature requests, post your questions, issues and reports of successful 
and failing tests in your environment at the [github site](../../issues).  Please feel free 
to fork this code, add your test cases, patch it and send me back a Pull Request.  Your 
contributions to the items on the to-do list are appreciated, as well as your ideas about what 
items might belong there.  Lets see if working together we can turn this into something useful.

# TO-DO

## To-Do tasks for hesco-weave 

### On the roadmap for the 0.9.x release

RESOLVED: [hesco-weave #14](../../issues/14): BUG: weave::install_docker/Exec['purge_firewall_rules'] 
requires installed docker to install docker

[hesco-weave #2](../../issues/2) I want to permit the `weave::docker_cluster_peers` 
key to accept either a space delimited string or a yaml array, and have it do the 
right thing either way.

[hesco-weave #3](../../issues/3), I want to add some additional custom 
`Facter::facts` to expose the containers and network hosted on the weave 
bridge or a particular docker host.

[hesco-weave #8](../../issues/8): BUG: Exclude local IP from peers array for weave::launch
While not a fatal error, it does provide for noisy logs.  

[hesco-weave #9](../../issues/9): new class needed to provide version check
weave::init ought to include a weave::version_check class, before the ::install class 
is invoked which will query for new versions of zettio/weave and of the hesco-weave 
modules and Notify[] the puppet agent of the opportunity to upgrade either or both modules.   

### Features planned for future releases

[hesco-weave #5](../../issues/5) An additional `weave::migrate` type is required 
to facilitate migrating a docker container from one docker host to another, while 
preserving its network connectivity.

[hesco-weave #10](../../issues/10): extend weave::install to support ensure => latest
Once upstream zettio/weave project provides for semantic versioning, we should be able to 
`ensure => latest` without performing backflips to sort out which git hash version ID to install.  

[hesco-weave #11](../../issues/11): enable use of WEAVE_DOCKER_ARGS for weave::launch 
defined type, to permit setting memory limit on weave router, or other run options.  

[hesco-weave #12](../../issues/12): Investigate weave launch-dns and what it requires 
of the puppet module

[hesco-weave #13](../../issues/13): extend weave::simple::run, invoke 
weave::firewall::dnat_published_port for each published port in hiera

## To-Do tasks for other projects

[weave #110](https://github.com/zettio/weave/issues/110) The weave project needs to 
provide semantic versioning for its releases.  Their doing so will make possible, 
or at least far easier, [hesco-weave #9](../../issues/9) and [hesco-weave #10](../../issues/10).  

[weave #117](https://github.com/zettio/weave/issues/117) I believe that the 
[zettio-weave project](https://github.com/zettio/weave) needs to sort 
out how to use its run, attach and detach subcommands to inject information about the 
weave bridge into the `docker inspect <container>` output.  

[docker #34](https://github.com/garethr/garethr-docker/issues/34) In my mind, 
the [garethr/docker module](https://github.com/garethr/garethr-docker) needs
an additional defined type, `docker::build`, to handle the initial build of a docker container,
from which the image used by `weave::run` can be launched with its additional ethwe bridge
connected interface, created by `weave`.  In the mean time, I am handling that step manually
with a Dockerfile and a wrapper bash script to drive it.  Those are all in my repository
and deployed by: `my_docker::helper_scripts`.

# COPYRIGHT AND LICENSE

Copyright 2014 Hugh Esco <hesco@campaignfoundations.com>
YMD Partners LLC dba/ [CampaignFoundations.com](http://CampaignFoundations.com)

Released under the Gnu Public License v2.

