# Puppet helper scripts

This repository contains some scripts I use to manage Puppet.

Comments & patches are welcome!

## bootstrap_puppet.sh

This script installs Puppet Master and Puppet Agent.

By default:
* 3 environments are defined : production, testing and development
* Manifests, templates and modules are under /srv/puppet/[ENV]
* Puppet Master use SQLlite3 and WebRICK
* Puppet Agent environment is set to development
* Puppet Agent is not automatically started on boot

Everything is logged to file 'puppet_bootstrap.log' in the current directory.

### Supported OS:
* Debian 7 (Wheezy)

### Arguments:

* `-s hostname` or `--server hostname`

  Specify Puppet Master name. Useful when you only install the agent.

  Default: hostname of running host or 'puppet' if option `-a` or `--agentonly` is used

* `-e env` or `--environment env`

  Specify environment for Puppet Agent

  Possible values: production testing development

  Default: development

* `-a` or `--agentonly`

  Only install Puppet Agent

  Default: install Puppet Master and Agent

* `--path path`

  Specify path to Puppet manifests

  Argument ignored if option `-a` or `--agentonly` is used

  Default: /srv/puppet

* `--mysql`

  Specify MySQL as database backend for Puppet Master

  Argument ignored if option `-a` or `--agentonly` is used

  Default: SQLite3 backend

* `--passenger`

  Use Apache with Passenger module as HTTP server for Puppet Master

  Argument ignored if option `-a` or `--agentonly` is used

  Default: WebRICK (Ruby integrated HTTP server)

* `-h` or `--help`

  Print help message

### Examples:
* Set up Puppet Master and Puppet Agent on a development machine

  `# puppet_bootstrap.sh`

* Set up Puppet Master and Puppet Agent on a production machine

  `# puppet_bootstrap.sh -e production --mysql --passenger`

* Set up a Puppet Agent on a production machine and enroll it on the Puppet Master server named 'puppet'

  `# puppet_bootstrap.sh -a -e production`

* Set up a Puppet Agent on a testing machine and enroll it on Puppet Master server named 'server.example.com'

  `# puppet_bootstrap.sh -a -e testing -s puppet.example.com`
