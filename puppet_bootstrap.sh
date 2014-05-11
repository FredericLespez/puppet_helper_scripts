#!/bin/bash

# Copyright 2014 Frédéric LESPEZ (frederic.lespez@free.fr)
#
# This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>

################################################################################
# Default values for arguments
################################################################################

script_name=$(basename "$0")
log_file=${script_name%.*}.log
puppet_manifests_home=/srv/puppet
puppet_environment_list=( "production" "testing" "development")
puppet_manifestdir=manifests
puppet_modulepath=modules
puppet_templatedir=data
puppet_agent_environment=development
puppet_server_option=NO
puppet_agent_only=NO
puppet_use_dns_alt_names=NO
puppet_use_mysql=NO
puppet_use_passenger=NO
puppet_purge_vardir=YES

################################################################################
# Parse arguments
################################################################################
# Original code from:
# http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [[ $# > 0 ]]; do
    key="$1"
    shift

    case $key in
	-s|--server)
	    puppet_server="$1"
	    puppet_server_option=YES
	    shift
	    ;;
	-e|--environment)
	    puppet_agent_environment="$1"
	    shift
	    ;;
	-a|--agentonly)
	    puppet_agent_only=YES
	    ;;
	--base_path)
	    puppet_manifests_home="$1"
	    shift
	    ;;
	--environment_list)
	    puppet_environment_list=($(echo $1))
	    shift
	    ;;
	--manifestdir)
	    puppet_manifestdir="$1"
	    shift
	    ;;
	--modulepath)
	    puppet_modulepath="$1"
	    shift
	    ;;
	--templatedir)
	    puppet_templatedir="$1"
	    shift
	    ;;
	--dns_alt_names)
	    puppet_use_dns_alt_names=YES
	    puppet_dns_alt_names=$1
	    shift
	    ;;
	--mysql)
	    puppet_use_mysql=YES
	    ;;
	--passenger)
	    puppet_use_passenger=YES
	    ;;
	--keep_vardir)
	    puppet_purge_vardir=NO
	    ;;
	-h|--help)
	    echo "This script installs Puppet Master and Puppet Agent."
	    echo "By default:"
	    echo " - Default environments: ${puppet_environment_list[@]}"
	    echo " - Manifests, modules and templates are respectively under:"
	    echo "   * ${puppet_manifests_home}/[ENV]/${puppet_manifestdir}"
	    echo "   * ${puppet_manifests_home}/[ENV]/${puppet_modulepath}"
	    echo "   * ${puppet_manifests_home}/[ENV]/${puppet_templatedir}"
	    echo " - Puppet Master will be automatically started on boot"
	    echo " - Puppet Master use SQLlite3 and WebRICK"
	    echo " - Puppet Agent environment is set to ${puppet_agent_environment}"
	    echo " - Puppet Agent will not be automatically started on boot"
	    echo " - ** WARNING ** Puppet vardir will be purged"
	    echo "   Main consequences of this:"
	    echo "     * Master: Master certificate will be erased"
	    echo "     * Master: Managed agents will be forgotten"
	    echo "     * Master: All saved files through the filebucket will be erased"
	    echo "     * Master: All cached data (facts, catalogs, etc.) will be erased"
	    echo "     * Agent: Agent certificate will be erased"
	    echo "     * Agent: Master enrollment will be erased"
	    echo "     * Agent: All saved files through the filebucket will be erased"
	    echo "     * Agent: All cached data (facts, catalogs, etc.) will be erased"
	    echo "   Use the --keep_vardir argument to avoid this"
	    echo
	    echo "Everything is logged to file '${log_file}' in the current directory"
	    echo
	    echo "Supported OS:"
	    echo " - Debian 7 (Wheezy)"
	    echo
	    echo "Arguments:"
	    echo "-s hostname or --server hostname"
	    echo "    Specify Puppet Master name"
	    echo "    Default: hostname of running host"
	    echo "             or 'puppet' if option -a or --agentonly is used "
	    echo
	    echo "-e env or --environment env"
	    echo "    Specify environment for Puppet Agent"
	    echo "    Possible values: production testing development"
	    echo "    Default: development"
	    echo
	    echo "-a or --agentonly"
	    echo "    Only install Puppet Agent"
	    echo "    Default: install Puppet Master and Agent"
	    echo
	    echo "--base_path path"
	    echo "    Specify path to Puppet manifests"
	    echo "    Argument ignored if option -a or --agentonly is used"
	    echo "    Default: /srv/puppet"
	    echo
	    echo "--environment_list string"
	    echo "    Specify a list of environment to use"
	    echo "    Argument format : quoted string of words"
	    echo "    Argument ignored if option -a or --agentonly is used"
	    echo "    Default: \"production testing development\""
	    echo
	    echo "--manifestdir rel_path"
	    echo "    Relative path to the manifestdir"
	    echo "    Absolute path: [base_path]/[environment]/[manifestdir]"
	    echo "    Argument ignored if option -a or --agentonly is used"
	    echo "    Default: manifests"
	    echo
	    echo "--modulepath rel_path"
	    echo "    Relative path to the modulepath"
	    echo "    Absolute path: [base_path]/[environment]/[modulepath]"
	    echo "    Argument ignored if option -a or --agentonly is used"
	    echo "    Default: modules"
	    echo
	    echo "--templatedir rel_path"
	    echo "    Relative path to the templatedir"
	    echo "    Absolute path: [base_path]/[environment]/[templatedir]"
	    echo "    Argument ignored if option -a or --agentonly is used"
	    echo "    Default: data"
	    echo
	    echo "--dns_alt_names"
	    echo "    Specify a comma-separated list of alternative DNS names"
	    echo "    to use for the local host (See official documentation)."
	    echo "    Example of use case: Needed if you want to contact your"
	    echo "    Puppet Master with a name which is neither its hostname"
	    echo "    nor 'puppet' ('puppetdev' for example)."
	    echo "    Argument ignored if option -a or --agentonly is used"
	    echo "    Default: puppet,puppet.$domain"
	    echo
	    echo "--mysql"
	    echo "    Specify MySQL as database backend for Puppet Master"
	    echo "    Argument ignored if option -a or --agentonly is used"
	    echo "    Default: SQLite3 backend"
	    echo
	    echo "--passenger"
	    echo "    Use Apache with Passenger module as HTTP server for Puppet Master"
	    echo "    Argument ignored if option -a or --agentonly is used"
	    echo "    Default: WEBrick (Ruby integrated HTTP server)"
	    echo
	    echo "--keep_vardir"
	    echo "    Don't purge Puppet vardir"
	    echo "    Default: Puppet vardir is purged"
	    echo
	    echo "-h or --help"
	    echo "    Print this message"
	    echo
	    echo "Examples:"
	    echo " - Set up Puppet Master and Puppet Agent on a development machine"
	    echo "   # ${script_name}"
	    echo " - Set up Puppet Master and Puppet Agent on a production machine"
	    echo "   # ${script_name} -e production --mysql --passenger"
	    echo " - Set up a Puppet Agent on a production machine and enroll it on"
	    echo "   the Puppet Master server named 'puppet'"
	    echo "   # ${script_name} -a -e production"
	    echo " - Set up a Puppet Agent on a testing machine and enroll it on"
	    echo "   Puppet Master server named 'server.example.com'"
	    echo "   # ${script_name} -a -e testing -s puppet.example.com"
	    exit 0
	    ;;
	*)
	    # Unknown option
	    echo "Unknown option ${key}"
	    echo "Use -h or --help to see options"
	    exit 1
	    ;;
    esac
done

################################################################################
# Check execution context
################################################################################

# Are we runned by root ?
if [ "$(id -u)" != "0" ]; then
    echo "Fatal error: This script must be run as root" 1>&2
    exit 1
fi

# Are we runned on a supported OS ?
is_os_supported=YES
os_name=$(lsb_release -is)
os_version_codename=$(lsb_release -cs)
if [ "$os_name" == "Debian" ]; then
    if [ "$os_version_codename" != "wheezy" ]; then
	is_os_supported=NO
    fi
else
    is_os_supported=NO
fi
if [ "$is_os_supported" == "NO" ]; then
    echo "OS ${os_name} ${os_version_codename} is not supported!"
    read -p "Give it a try anyway (Y/N)? " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
	echo "Fatal error: Unsupported OS ${os_name} ${os_version_codename}" 1>&2
	exit 1
    fi
    echo "Proceeding as requested"
fi

# Is selected environment in environment list ?
if [ "$puppet_agent_only" == "NO" ]; then
    found=false
    for env in "${puppet_environment_list[@]}"; do
	if [[ $env == $puppet_agent_environment ]]; then
	    found=true
	    break
	fi
    done
    if [ "$found" = false ]; then
	echo -n "Fatal error: Agent's environment ${puppet_agent_environment} is not valid. " 1>&2
	echo "Should be one of these: ${puppet_environment_list[@]}" 1>&2
	exit 1
    fi
fi

################################################################################
# Initialize log file & set up helpers
################################################################################
echo "Start logging..." > "$log_file"
DARK_GRAY="\033[1;30m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
NO_COLOR="\033[0m"
logmess()
{
    local COLOR="$1"
    local MESS1="$2"
    local MESS2="$3"
    echo -e "${COLOR}${MESS1}${NO_COLOR}${MESS2}"
    echo "${MESS1}${MESS2}" &>> "$log_file"
}
lognewline()
{
    echo |tee -a "$log_file"
}
logerror()
{
    local COLOR="$RED"
    local MESS1="$1"
    local MESS2="$2"
    logmess $COLOR "${MESS1}" "${MESS2}"
}
loginfo()
{
    local COLOR="$YELLOW"
    local MESS1="$1"
    local MESS2="$2"
    logmess $COLOR "${MESS1}" "${MESS2}"
}
logaction()
{
    local COLOR="$PURPLE"
    local MESS="$1"
    logmess $COLOR "${MESS}"
}
logdone()
{
    local COLOR="$CYAN"
    logmess $COLOR "************************* Done *************************"
    lognewline
}
logtitle()
{
    local COLOR="$GREEN"
    local MESS="$1"
    logmess $COLOR "********************************************************"
    logmess $COLOR "** ${MESS}"
    logmess $COLOR "********************************************************"
}
lognewline

################################################################################
# Variables
################################################################################

if [ "$puppet_server_option" == "NO" ]; then
    if [ "$puppet_agent_only" == "NO" ]; then
	puppet_server=$(hostname -f)
    else
	puppet_server=puppet
    fi
fi
puppet_agent_packages="puppet facter"
puppet_master_packages="puppetmaster"
puppet_master_sqllite_packages="libactiverecord-ruby ruby-sqlite3 sqlite3"
puppet_master_mysql_packages="libactiverecord-ruby mysql-server ruby-mysql"
puppet_master_passenger_packages="puppetmaster-passenger"
puppet_helper_packages="augeas-tools augeas-lenses"
puppet_master_addon_packages="openssh-server rsync"

################################################################################
# Summary
################################################################################

logtitle "Summary of Puppet environment set up"
if [ "$puppet_agent_only" == "NO" ]; then
    loginfo " * Puppet Master:" " WILL BE INSTALLED"
    loginfo "    - Server:                 " "${puppet_server}"
    if [ "$puppet_use_dns_alt_names" == "YES" ]; then
	loginfo "    - Server DNS alt names:   " "${puppet_dns_alt_names}"
    fi
    if [ "$puppet_use_mysql" == "YES" ]; then
	loginfo "    - Database backend:       " "MySQL"
    else
	loginfo "    - Database backend:       " "SQLite3"
    fi
    if [ "$puppet_use_passenger" == "YES" ]; then
	loginfo "    - HTTP Backend:           " "Apache with mod Passenger"
    else
	loginfo "    - HTTP Backend:           " "WEBrick"
    fi
    loginfo "    - Available environments: " "${puppet_environment_list[*]}"
    loginfo "    - Manifests home:         " "${puppet_manifests_home}"
    loginfo "    - Manifest dir:           " "${puppet_manifests_home}/[ENV]/${puppet_manifestdir}"
    loginfo "    - Module path:            " "${puppet_manifests_home}/[ENV]/${puppet_modulepath}"
    loginfo "    - Template dir:           " "${puppet_manifests_home}/[ENV]/${puppet_templatedir}"
    loginfo "    - Purge vardir:           " "${puppet_purge_vardir}"
else
    loginfo " * Puppet Master:" " WILL NOT BE INSTALLED"
fi
lognewline

loginfo " * Puppet Agent:" " WILL BE INSTALLED"
loginfo "    - Environment:   " "${puppet_agent_environment}"
loginfo "    - Puppet server: " "${puppet_server}"
loginfo "    - Purge vardir:  " "${puppet_purge_vardir}"
lognewline

read -p "Proceed (Y/N)? " -n 1 -r
echo
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    logerror "Aborting as requested"
    exit 1
fi

################################################################################
# Install needed packages
################################################################################

logtitle "Installing needed packages"
packages="${puppet_agent_packages} ${puppet_helper_packages}"
if [ "$puppet_agent_only" == "NO" ]; then
    packages="${packages} ${puppet_master_packages} ${puppet_master_addon_packages}"
    if [ "$puppet_use_mysql" == "YES" ]; then
	packages="${packages} ${puppet_master_mysql_packages}"
    else
	packages="${packages} ${puppet_master_sqllite_packages}"
    fi
    if [ "$puppet_use_passenger" == "YES" ]; then
	packages="${packages} ${puppet_master_passenger_packages}"
    fi
fi
loginfo "Packages to install: ${packages}"
logaction "Update packages lists"
aptitude update 2>> "$log_file" 1> /dev/null
logaction "Proceed to install"
if [ "$puppet_use_mysql" == "YES" ]; then
    # We can't suppress output because we need to enter MySQL root user password
    DEBIAN_FRONTEND=text aptitude -y -q=2 install ${packages} |tee -a "$log_file"
else
    aptitude -y -q=2 install ${packages} &>> "$log_file"
fi
logaction "Check that all packages are installed"
for package in $packages; do
    # See https://superuser.com/questions/427318/test-if-a-package-is-installed-in-apt
    if dpkg-query -Wf'${db:Status-abbrev}' "${package}" 2>/dev/null | grep -q '^i'; then
	echo " - ${package} is installed" &>> "$log_file"
    else
	logerror "ERROR: ${package} is NOT installed\! Aborting..."
	exit 1
    fi
done
logdone

################################################################################
# Shutdown Puppet Master daemon
################################################################################

logtitle "Shutdown Puppet Master daemon"
logaction "Shutting down Puppet Master daemon..."
service puppetmaster stop &>> "$log_file"
logdone

################################################################################
# Remove Puppet Agent and Master vardir
################################################################################

if [ "$puppet_purge_vardir" == "YES" ]; then
    logtitle "Remove Puppet Agent and Master vardir"
    logaction "Identify Puppet Angent and Master vardir"
    command -v puppet &>>/dev/null || {
	logerror "ERROR: 'puppet' command not found.  Aborting."
	exit 1
    }
    puppet_agent_vardir=$(puppet config print vardir --mode agent)
    puppet_master_vardir=$(puppet config print vardir --mode master)

    # Check that $puppet_agent_vardir is not an empty string
    # to avoid thrashing the system
    if [ -n "$puppet_agent_vardir" ]; then
	logaction "Remove Puppet Agent vardir: ${puppet_agent_vardir}"
	rm -rf "${puppet_agent_vardir}/*" &>> "$log_file"

	logaction "Reset permissions on Puppet Agent vardir"
	chown puppet:puppet "${puppet_agent_vardir}" &>> "$log_file"
	chmod 750 "${puppet_agent_vardir}" &>> "$log_file"
	mkdir "${puppet_agent_vardir}/state" &>> "$log_file"
	chown puppet:puppet "${puppet_agent_vardir}/state" &>> "$log_file"
	chmod 755 "${puppet_agent_vardir}/state" &>> "$log_file"
    else
	logerror "WARNING ! Puppet Agent vardir is null"
	exit 1
    fi

    if [ "$puppet_agent_only" == "NO" ]; then
	# Check that $puppet_master_vardir is not an empty string
	# to avoid thrashing the system
	if [ -n "$puppet_master_vardir" ]; then
	    logaction "Remove Puppet Master vardir: ${puppet_master_vardir}"
	    rm -rf "${puppet_master_vardir}/*" &>> "$log_file"

	    logaction "Reset permissions on Puppet Master vardir"
	    chown puppet:puppet "${puppet_master_vardir}" &>> "$log_file"
	    chmod 750 "${puppet_master_vardir}" &>> "$log_file"
	    mkdir "${puppet_master_vardir}/state" &>> "$log_file"
	    chown puppet:puppet "${puppet_master_vardir}/state" &>> "$log_file"
	    chmod 755 "${puppet_master_vardir}/state" &>> "$log_file"
	else
	    logerror "WARNING ! Puppet Master vardir is null"
	    exit 1
	fi
    fi
    logdone
fi

# Begin of configuration for Puppet Master (not used when $puppet_agent_only is set to YES)
if [ "$puppet_agent_only" == "NO" ]; then

################################################################################
# Create manifest structure
################################################################################

    logtitle "Create directory structure for manifests"
    logaction "Create directory structure under ${puppet_manifests_home}"
    for env in "${puppet_environment_list[@]}"; do
	loginfo "Create directory structure for environment ${env}"
	mkdir -p ${puppet_manifests_home}/${env}/${puppet_manifestdir} &>> "$log_file"
	mkdir -p ${puppet_manifests_home}/${env}/${puppet_modulepath} &>> "$log_file"
	mkdir -p ${puppet_manifests_home}/${env}/${puppet_templatedir} &>> "$log_file"
    done
    logaction "Setting permissions on directory structure"
    chown -R puppet:puppet ${puppet_manifests_home} &>> "$log_file"
    find ${puppet_manifests_home} -type d -exec chmod 750 {} + &>> "$log_file"
    find ${puppet_manifests_home} -type f -exec chmod 640 {} + &>> "$log_file"
    logdone

################################################################################
# Modify default puppetmaster configuration
################################################################################

    logtitle "Configure Puppet Master"
    logaction "Modify /etc/puppet/puppet/conf to set up Master"
    augtool -e &>> "$log_file" <<EOF
defvar puppetconf /files/etc/puppet/puppet.conf
rm \$puppetconf/main/prerun_command
rm \$puppetconf/main/postrun_command
set \$puppetconf/main/manifestdir ${puppet_manifests_home}/\$environment/${puppet_manifestdir}
set \$puppetconf/main/modulepath ${puppet_manifests_home}/\$environment/${puppet_modulepath}
set \$puppetconf/main/templatedir ${puppet_manifests_home}/\$environment/${puppet_templatedir}
set \$puppetconf/master/storeconfigs true
set \$puppetconf/master/thin_storeconfigs true
set \$puppetconf/master/dbadapter sqlite3
set \$puppetconf/master/pluginsync true
save
EOF
    logaction "Start Puppet Master daemon on boot"
    augtool -e &>> "$log_file" <<EOF
defvar defaultpuppetmaster /files/etc/default/puppetmaster
set \$defaultpuppetmaster/START yes
save
EOF
    if [ "$puppet_use_dns_alt_names" == "YES" ]; then
	logaction "Delete the Puppet Master’s certificate, private key, and public key"
	puppet_ssldir=$(puppet master --configprint ssldir)
	puppet_certname="$(puppet master --configprint certname).pem"
	find "${puppet_ssldir}" -name "${puppet_certname}" -delete &>> "$log_file"
	logaction "Configure DNS alt names for Puppet Master"
	augtool -e &>> "$log_file" <<EOF
defvar puppetconf /files/etc/puppet/puppet.conf
set \$puppetconf/master/dns_alt_names ${puppet_dns_alt_names}
save
EOF
	logaction "Generate new Puppet Master’s certificate, private key, and public key"
	puppet cert --generate $(hostname -f) &>> "$log_file"
    fi
    logdone

################################################################################
# Create Puppet database in MySQL
################################################################################

    if [ "$puppet_use_mysql" == "YES" ]; then
	logtitle "Create Puppet database in MySQL"
	logaction "Choose a password for MySQL 'puppet' user"
	loginfo "Beware of special characters here. Some characters like '\`'"
	loginfo "or '^' need two keypresses to appear only once !"
	loginfo "Strengthen your password afterwards if you need to, by changing"
	loginfo "it in MySQL and by changing the value of 'dbpassword'"
	loginfo "parameter in /etc/puppet/puppet.conf"
	puppet_mysql_password=A
	puppet_mysql_password_verify=B
	while [ "$puppet_mysql_password" != "$puppet_mysql_password_verify" ]; do
	    read -s -p "New password for 'puppet' user:" puppet_mysql_password
	    echo
	    read -s -p "Repeat password for 'puppet' user:" puppet_mysql_password_verify
	    echo
	done
	loginfo "Got a password for MySQL 'puppet' user"
	logaction "Provide MySQL 'root' user password"
	mysql -u root -p <<EOF |tee -a "$log_file"
create database puppet;
grant all privileges on puppet.* to puppet@localhost identified by '${puppet_mysql_password}';
EOF
	logaction "Modify /etc/puppet/puppet/conf to use MySQL database"
	augtool -e &>> "$log_file" <<EOF
defvar puppetconf /files/etc/puppet/puppet.conf
set \$puppetconf/master/thin_storeconfigs false
set \$puppetconf/master/dbadapter mysql
set \$puppetconf/master/dbuser puppet
set \$puppetconf/master/dbpassword "${puppet_mysql_password}"
set \$puppetconf/master/dbserver localhost
set \$puppetconf/master/dbsocket /var/run/mysqld/mysqld.sock
save
EOF
	logdone
    fi

################################################################################
# Setup Apache and Passenger module
################################################################################

    if [ "$puppet_use_passenger" == "YES" ]; then
	logtitle "Setup Apache and Passenger module"
	logaction "Prevent Puppet Master daemon from starting on boot"
	augtool -e &>> "$log_file" <<EOF
defvar defaultpuppetmaster /files/etc/default/puppetmaster
set \$defaultpuppetmaster/START no
save
EOF
	logaction "Customize Apache Puppet Master virtual host"
	augtool -e &>> "$log_file"<<EOF
defvar puppetmastervhost /files/etc/apache2/sites-available/puppetmaster
rm \$puppetmastervhost/VirtualHost/*[self::directive='ErrorLog']
rm \$puppetmastervhost/VirtualHost/*[self::directive='CustomLog']
set \$puppetmastervhost/VirtualHost/directive[last()+1] ErrorLog
set \$puppetmastervhost/VirtualHost/*[self::directive='ErrorLog']/arg /var/log/apache2/puppetmaster.error.log
set \$puppetmastervhost/VirtualHost/directive[last()+1] CustomLog
set \$puppetmastervhost/VirtualHost/*[self::directive='CustomLog']/arg /var/log/apache2/puppetmaster.access.log
set \$puppetmastervhost/VirtualHost/*[self::directive='CustomLog']/arg[last()+1] Combined
save
EOF
	logaction "Enable Apache Puppet Master virtual host"
	# In theory, the site is enabled by default, but just in case...
	a2ensite puppetmaster &>> "$log_file"
	logdone
    fi

################################################################################
# Start Puppet Master
################################################################################

    logtitle "Start Puppet master"
    if [ "$puppet_use_passenger" == "NO" ]; then
	logaction "Start Puppet Master daemon"
	service puppetmaster restart &>> "$log_file"
    else
	logaction "Restart Apache (to start Puppat Master)"
	service apache2 restart &>> "$log_file"
    fi
    logdone

fi
# End of configuration for Puppet Master (not used when $puppet_agent_only is set to YES)

################################################################################
# Modify default puppet agent configuration
################################################################################

logtitle "Configure Puppet agent"
logaction "Modify /etc/puppet/puppet/conf to set up Agent"
augtool -e &>> "$log_file" <<EOF
defvar puppetconf /files/etc/puppet/puppet.conf
set \$puppetconf/agent/environment ${puppet_agent_environment}
set \$puppetconf/agent/server ${puppet_server}
set \$puppetconf/agent/pluginsync true
save
EOF
if [ "$puppet_agent_only" == "YES" ]; then
    logaction "Registering Puppet Agent on Puppet Master (${puppet_server})..."
    puppet agent --server ${puppet_server} --test --noop --color false &>> "$log_file"
    loginfo "Instructions to finish the agent registration"
    loginfo "On the Puppet Master (${puppet_server}):"
    loginfo " - List the waiting certificates with this command:"
    loginfo "   # puppet cert --list"
    loginfo " - Sign the certificate for this agent ($(hostname -f))"
    loginfo "   # puppet cert --sign $(hostname -f)"
    loginfo "After that, the Puppet Agent will be operational"
    logdone
    logtitle "That's all folks !"
    exit 0
fi
logdone

################################################################################
# Test setup with a Hello World manifest
################################################################################

if [ "$puppet_agent_only" == "NO" ]; then
    logtitle "Test Puppet setup"
    logaction "Set up a 'Hello World' manifest"
    rm -f /root/hello_puppet &>> "$log_file"
    manifest_file="${puppet_manifests_home}/${puppet_agent_environment}/manifests/site.pp"
    existing_sitepp=NO
    if [ -f "$manifest_file" ]; then
	existing_sitepp=YES
	suffix=$(date +%Y-%m-%d-%H:%M:%S)_$$.$RANDOM
	loginfo "Putting aside existing site.pp manifest"
	loginfo "Renaming existing site.pp manifest"
	loginfo "Will be suffixed with \"${suffix}\""
	mv "$manifest_file" "${manifest_file}_${suffix}" &>> "$log_file"
    fi
    cat > "$manifest_file" <<EOF
# site.pp
file { "/root/hello_puppet":
	ensure	=> present,
	content	=> "Hello World !\n",
	owner	=> root,
	group	=> root,
	mode	=> 440
}
EOF
    logaction "Run Puppet Agent"
    puppet agent --test --color false &>> "$log_file"
    if [ "$existing_sitepp" == "YES" ]; then
	loginfo "Putting back existing site.pp manifest"
	mv "${manifest_file}_${suffix}" "$manifest_file" &>> "$log_file"
    fi
    loginfo "Is everything like we expected?"
    if [ -f /root/hello_puppet ]; then
	loginfo "Yes! Everything's fine Captain!"
    else
	logerror "Nope! Something's broken :-("
	logerror "See log './${log_file}' for details"
	exit 1
    fi
    logdone
fi

################################################################################
# Optimize Puppet database
################################################################################

if [ "$puppet_agent_only" == "NO" ] && [ "$puppet_use_mysql" == "YES" ]; then
    logtitle "Optimize Puppet database performance"
    logaction "Set up an index on Puppet database"
    mysql -u puppet -p"${puppet_mysql_password}" <<EOF &>> "$log_file"
use puppet;
create index exported_restype_title on resources (exported, restype, title(50));
EOF
    logdone
fi

logtitle "That's all folks !"
exit
