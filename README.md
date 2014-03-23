# Puppet helper scripts

This repository contains some scripts I use to manage Puppet.

Comments & patches are welcome!

## bootstrap_puppet.sh

This script installs Puppet Master and Puppet Agent.

By default:
* Default environments: production, testing and development
* Manifests, modules and templates are respectively under:
 * /srv/puppet/[ENV]/manifests
 * /srv/puppet/[ENV]/modulepath
 * /srv/puppet/[ENV]/templates
* Puppet Master will be automatically started on boot
* Puppet Master use SQLlite3 and WebRICK
* Puppet Agent environment is set to development
* Puppet Agent is not automatically started on boot
* **WARNING** Puppet vardir will be purged. Main consequences of this:
 * Master: Master certificate will be erased
 * Master: Managed agents will be forgotten
 * Master: All saved files through the filebucket will be erased
 * Master: All cached data (facts, catalogs, etc.) will be erased
 * Agent: Agent certificate will be erased
 * Agent: Master enrollment will be erased
 * Agent: All saved files through the filebucket will be erased
 * Agent: All cached data (facts, catalogs, etc.) will be erased
 * Use the --keep_vardir argument to avoid this

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

* `--base_path path`

  Specify path to Puppet manifests

  Argument ignored if option `-a` or `--agentonly` is used

  Default: /srv/puppet

* `--environment_list string`

  Specify a list of environment to use

  Argument format : quoted string of words

  Argument ignored if option -a or --agentonly is used

  Default: "production testing development"

* `--manifestdir rel_path`

  Relative path to the manifestdir

  Absolute path: [base_path]/[environment]/[manifestdir]

  Argument ignored if option -a or --agentonly is used

  Default: manifests

* `--modulepath rel_path`

  Relative path to the modulepath

  Absolute path: [base_path]/[environment]/[modulepath]

  Argument ignored if option -a or --agentonly is used

  Default: modules

* `--templatedir rel_path`

  Relative path to the templatedir

  Absolute path: [base_path]/[environment]/[templatedir]

  Argument ignored if option -a or --agentonly is used

  Default: data

* `--dns_alt_names`
  Specify a comma-separated list of alternative DNS names to use for the local host (See official documentation).

  Example of use case: Needed if you want to contact your Puppet Master with a name which is neither its hostname nor 'puppet' ('puppetdev' for example).

  Argument ignored if option -a or --agentonly is used

  Default: puppet,puppet.

* `--mysql`

  Specify MySQL as database backend for Puppet Master

  Argument ignored if option `-a` or `--agentonly` is used

  Default: SQLite3 backend

* `--passenger`

  Use Apache with Passenger module as HTTP server for Puppet Master

  Argument ignored if option `-a` or `--agentonly` is used

  Default: WEBrick (Ruby integrated HTTP server)

* `--keep_vardir`

  Don't purge Puppet vardir

  Default: Puppet vardir is purged

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
