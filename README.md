# weave

#### Table of Contents

1. [Name](#name)
2. [Version](#version)
3. [Synopsis](#synopsis)
4. [Installation - The basics of getting started with weave](#installation)
    * [Setup requirements](#setup-requirements)
    * [What weave affects](#what-weave-affects)
5. [Usage - Configuration options and additional functionality](#usage)
    * [Organizing role::docker_host](#organizing-the-docker_host-role)
    * [Setting up hiera data](#setting-up-hiera)
    * [Use weave::run to configure containers](#use-weave-run-type-to-configure-containers)
    * [Use weave::interface - enforce ethwe state on containers](#use-weave-interface)
    * [Use weave::firewall - manage docker host firewall for weave](#use-weave-firewall) # PENDING
6. [Reference - An under-the-hood peek at what the module is doing and how](#reference) # PENDING
7. [Limitations - Caveats, OS compatibility, etc.](#limitations)
8. [Development - Guide for contributing to the module](#development)
9. [To-Do](#to-do)
    * [To-Do tasks for hesco-weave](#to-do-tasks-for-hesco-weave)
    * [To-Do tasks for other projects](#to-do-tasks-for-other-projects)
10. [Copyright and License](#copyright-and-license)

# NAME

hesco-weave -- puppet module for deploying and managing a docker network with weave

# VERSION

Version v0.7.2

This is alpha code and no promises are made at this early stage as to the stability
of its interface, or its suitability for production use.  The weave project is still
less than seven weeks and four hundred commits old.  I myself am still testing it
with the hope of putting it to use in my own environment.  I found it the least
confusing interface I could find for bridging docker containers across multiple
docker hosts.  But getting it to work in my environment has alrady demanded that
I dig in to its innards and learn more about software defined networks than I knew
before.

# SYNOPSIS

Puppet module for managing a weave network on a docker cluster

Weave is a docker container hosted SDN router plus a shell script for managing an SDN
on a docker cluster.  It is capable of bridging virtual networks across docker hosts,
making it possible for containers deployed across different physical hosts to communicate
with one another.  To learn more about [weave, click here](https://github.com/zettio/weave).

Architecturally, to make this work, one will want to use docker to deploy a weave router
using the [zettio/weave image from the Docker Hub](https://registry.hub.docker.com/u/zettio/weave/),
on each docker host, by using the weave script to `weave launch` it.  The script will create
a private bridge and establish peer relationships between multiple docker hosts.

Then rather than using `docker run`, you will use the weave script's `weave run` command
to wrap docker with additional code to configure the Software Defined Network around an
arbitrary docker container.

This puppet module exposes at this early stage of its development three defined types: `weave::launch`,
`weave::run` and `weave::interface` to make these tools available from a puppet manifest.  It also manages 
the installation and uninstall of weave, its docker hosted router and packaged dependencies.

# INSTALLATION

For the time being, this module may be installed like so:

    # cd /etc/puppet/modules
    # git clone https://github.com/hesco/hesco-weave.git

Now that [this module has been published to the puppet forge](https://forge.puppetlabs.com/hesco/weave),
and at the risk of missing out on the latest and greatest and potentially less than stable changes, 
it can be installed using puppet, like so:

    # puppet module install -i /etc/puppet/modules hesco/weave

Read `puppet help module install` for other useful options.

# Setup Requirements

If you install this from the git repository rather than from the forge,
dependencies must be managed manually.  This module requires:

    - [puppetlabs/stdlib](https://forge.puppetlabs.com/puppetlabs/stdlib)
    - [puppetlabs/firewall](https://forge.puppetlabs.com/puppetlabs/firewall)
    - [garethr/docker](https://forge.puppetlabs.com/garethr/docker)

Actually, the firewall module is intended to support a future, not yet implemented feature.

## What weave affects

`weave::install` --
installs packages for `ethtool` and `conntrack`
deploys a pinned version of `/usr/local/bin/weave`
Read the source for instructions on upgrading the weave script

`weave::launch` --
will run `docker pull zettio/weave` to grab the `:latest` docker image
use the weave script to `weave launch` a weave router as a docker container
set up a weave bridge and associated network interfaces
reset and restart the weave container if it crashes

`weave::run` --
invokes `weave run` which wraps `docker run` to deploy a docker container from an image
creates weave interfaces, uses them to attach a container to the weave bridge

`weave::interface` --
enforces state (present and absent, supported) for an ethwe interface on a container
this defined type can be used to retroactively attach existing docker containers to a new weave router

# USAGE

## Organizing the docker_host role

My docker_host role class, looks like this:

    class role::docker_host { include profile::docker_weave }

The `docker_weave` profile uses the `garethr/docker` module to install docker.
The garethr module also exposes a couple of defined types used in the weave
module and perhaps elsewhere in my internal codebase.

    class profile::docker_weave {

      $fqdn_normalized = regsubst($fqdn,'\.','_',"G")
      include docker
      # <-- garethr/docker
      include my_docker
      # <-- install prerequisites, utilities, helper scripts, Dockerfile(s)
      include weave
      # <-- this hesco/weave module
      include "docker_cluster::hosts::${fqdn_normalized}"
      # <-- manages state for containers on a particular docker host

    }

## setting up hiera

Including the [hesco/weave](https://github.com/hesco/hesco-weave) module (`include weave`) 
in profile::docker_weave, along with the following hiera settings, handles the installation 
(and uninstall) of the `zettio/weave` script and its supporting docker image, used to build 
a docker container hosting an SDN router.

my /etc/puppet/hiera.yaml --

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

my /etc/puppet/hieradata/dhcp.yaml --

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
      s01.example.com:
        hostname: s01.example.com
        image: drupal
        ip: 10.0.1.11/24
        host: dockerhost001
     # additional key->hash definition for each container

/etc/puppet/hieradata/docker_build_options.yaml --

    ---

    drupal:
      docker_run_opts:
        - '--memory=1g'
        - '--restart=always'
        - '--net=bridge'
        - '--name="DOMAIN"'
        - '-h DOMAIN'
      attach_volumes:
        - "-v /data/var/www/files/DOMAIN:/var/www/files/DOMAIN"
        - "-v /data/var/www/sites/DOMAIN:/var/www/sites/DOMAIN"
        - "-v /data/var/log/apache2/DOMAIN:/var/log/apache2/DOMAIN"
        - "-v /data/etc/apache2/DOMAIN:/etc/apache2"
    # additional key->hash definition for each docker image type

I have been advised that by deploying a weave network, I can now disable 
the docker bridge, by setting `--net=none`.  But for the moment I continue 
to use ithe docker bridge to manage the containers from the docker hosts, 
even while I intend to use the weave bridge for inter-container communication.  

In the data structure for my haproxy image, I also set the published ports
as a yaml array:

    haproxy:
      ports:
        - '-p 80:80'
      docker_run_opts:
        etc., etc.

my /etc/puppet/hieradata/nodes/dockerhost01.example.com.yaml --

    ---

    docker::param::version: '1.2.0'
    # this next line may have been deprecated
    # by $docker_hosts_weave_dhcp[n]['ip']
    weave::docker_host_weave_ip: '10.0.0.1/16'

## use weave::run type to configure containers

Next, my `"docker_cluster::hosts::${fqdn_normalized}"` profile includes
defined type invocations which look like this:

    my_docker::container { 'weave_run s01.example.com': host_name => 's01.example.com' }

That defined type wraps the following in sanity checks and data validation to ensure that 
valid data is being passed from the hiera data store to a defined type exposed by this module:

    weave::run { "weave run $host_name at $ip":
         host => $container_name,
           ip => $ip,
        image => $image,
      options => $options
    }

The host key in this invocation is new to version v0.7.xx and was necessary to resolve the 
[bug described here](../../issues/7).

Under the hood `weave::run` is calling the `weave` script which wraps a call to `docker run` with 
additional bash code to plumb the weave network on to the docker container.  

## use weave::interface to enforce ethwe state on containers

And finally, to enforce state, or to retroactively attach existing containers launched 
with `docker run` rather than `weave run` or the methods exposed by this module, 
my `docker_cluster::hosts::${fqdn_normalized}` profile now includes: 
    
    my_docker::network::interface { 's01.example.com ethwe interface':
      host_name => 's01.example.com',
         ensure => 'present',
    }

Again, this is a defined type designed to munge my own hiera data structure, apply sanity 
checks and validation tests to data fed to another defined type exposed by this module:

    weave::interface { "Ensure ethwe (bound to $ip) $ensure on $host_name":
         ensure => $ensure,
             ip => $ip,
      container => $host_name,
    }

## Use weave::firewall - manage docker host firewall for weave

Pending . . . 

Although code for this upcoming feature has been committed to the repository and is included 
in this package, its use is currently suppressed.  This [feature](../../issues/1) requires 
some additional work before being ready for even alpha testing.  Your patience or patches 
are appreciated.  

# REFERENCE

Pending . . . 

# LIMITATIONS

If you are an early adopter who has used the github repository to interact with this module, 
consider yourself warned that I have rewritten public history by updating tags as described 
in the Changlog.  Tags v0.0.4, v0.01, v0.02, v0.03, v0.04, v0.05 and v0.06 are no longer present 
in the public repository.  These changes were made to comply with the versioning standards outlined 
at semver.org and necesssary to upload releases to the puppet forge.  

So far this has only been tested on Debian, jessie/testing.  Reports of your experiences
with this code in other environments are appreciated, particularly when they include tests
and patches, particularly when they come in the form of a Pull Request, even if only to
patch this README.md to report on success or failure of this module in your environment.

# DEVELOPMENT

Please report bugs, feature requests and other issues or successful tests in other environments 
at the [github site](../../issues), fork this code, add your test cases, patch it and send me 
back a Pull Request.  Your contributions to the items on the to-do list are appreciated, as 
well as your ideas about what items might belong there.  Lets see if working together we can 
turn this into something useful.

# TO-DO

## To-Do tasks for hesco-weave 

[hesco-weave #1](../../issues/1) The `weave::install` manifest needs to use 
[puppetlabs-firewall](https://forge.puppetlabs.com/puppetlabs/firewall) 
to ensure that port 6783 is open for tcp and udp traffic among the docker hosts.  

[hesco-weave #2](../../issues/2) I want to permit the `weave::docker_cluster_peers` 
key to accept either a space delimited string or a yaml array, and have it do the 
right thing either way.

[hesco-weave #3](../../issues/3), [hesco-weave #4](../../issues/4) I want to add 
some custom `Facter::facts` to expose the containers and network hosted on the 
weave bridge or a particular docker host.

[hesco-weave #5](../../issues/5) An additional `weave::migrate` type is required 
to facilitate migrating a docker container from one docker host to another, while 
preserving its network connectivity.

[hesco-weave #6](../../issues/6) 
At the moment, my hiera data exposes a hash of hashes and an inhouse module is left with 
responsibility for munging, validating and sanity checking that data before the `weave::run`
and `weave::interface` types are handed what they need to get the job done.  This seemed an 
appropriate balance between making this code available and not wanting to dictate the 
structure of other folks hiera data stores.  But I am open to feedback on whether that 
balance ought to be tipped in the other direction to facilitate ease of use for consumers 
of this module, at the cost perhaps of constraining design choices they might make about 
their own environments.  

## To-Do tasks for other projects

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

