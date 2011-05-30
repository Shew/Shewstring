#!/bin/sh

# The Tor home page: https://www.torproject.org/

# Requires:	lib/misc_utils.sh
#		lib/ports_pkgs_utils.sh
#		lib/user_maint_utils.sh

# Contents:	darknets_tor__patch_circuit_length
#		darknets_tor__patch_circuit_dirtiness
#		darknets_tor__install_tor
#		darknets_tor__configure_tor_normal
#		darknets_tor__configure_tor_two_hop
#		darknets_tor__configure_tor_zero_dirtiness
#		darknets_tor__enable_socks
#		darknets_tor__enable_transparent
#		darknets_tor__add_jail_tor_socks_rules
#		darknets_tor__add_jail_tor_transparent_rules

# Variable defaults:
  : ${darknets_tor__tor_configs='/usr/shew/install/shewstring/libexec/darknets/misc/tor'}
								# This file is the default tor folder for config files.
  : ${darknets_tor__rcd_tor_normal='/usr/shew/install/shewstring/libexec/darknets/rc.d/shew_tor_normal'}
								# The default tor_normal rc.d file.
  : ${darknets_tor__rcd_tor_two_hop='/usr/shew/install/shewstring/libexec/darknets/rc.d/shew_tor_two_hop'}
								# The default tor_two_hop rc.d file.
  : ${darknets_tor__rcd_tor_zero_dirtiness='/usr/shew/install/shewstring/libexec/darknets/rc.d/shew_tor_z_dirt'}
								# The default tor_zero_dirtiness rc.d file.
  : ${darknets_tor__apps_folder='/usr/shew/install/shewstring/libexec/darknets/apps'}
								# The default darknets apps folder.

darknets_tor__patch_circuit_length() {
	# This function will patch tor such that it will allow building two hop
	# circuits, this can be enabled by adding the line 'ClientCircuitLen 2' to the
	# torrc of a tor install. NOTE: You must do this before compiling tor. If you
	# do not, you will need to uninstall it and delete its packages. If this task
	# has already been done, the function complains and returns true. The patch is
	# by robo mojo from http://archives.seul.org/or/talk/Apr-2008/msg00065.html

	if [ -f /usr/shew/install/done/nat_darknets/darknets_tor__patch_circuit_length ]; then
		echo "darknets_tor__patch_circuit_length was called but it has already been run,
skipping."
		return 0
	fi

	if
		ports_pkgs_utils__check_port_made tor
	then
		echo 'darknets_tor__patch_circuit_length was called but tor has already been
compiled. It must be uninstalled, etc. before it can be patched.'
		return 1
	fi

	if [ ! -d "$darknets_tor__tor_configs" ]; then
		echo "darknets_tor__configure_tor_normal could not find a critical install file. It
should be:
	$darknets_tor__tor_configs"
		return 1
	fi

	cp -f "$darknets_tor__tor_configs"/patch-circuit-length /usr/shew/jails/compile/usr/ports/security/tor/files

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_tor__patch_circuit_length
}

darknets_tor__patch_circuit_dirtiness() {
	# This function will patch tor such that it will allow setting
	# MaxCircuitDirtiness 0. Setting MaxCircuitDirtiness 0 will generates a new
	# circuit for every unique connection attempt. PLEASE BE CAREFUL, ONLY USE THIS
	# SPARINGLY FOR INTERMITTENT CONNECTIONS LIKE EMAIL. Using this for something
	# that generates many connections, e.g. web browsing, can DoS the tor network.
	# NOTE: You must do this before compiling tor. If you do not, you will need to
	# uninstall it and delete its packages. If this task has already been done, the
	# function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_tor__patch_circuit_dirtiness ]; then
		echo "darknets_tor__patch_circuit_dirtiness was called but it has already been run,
skipping."
		return 0
	fi

	if
		ports_pkgs_utils__check_port_made tor
	then
		echo 'darknets_tor__patch_circuit_dirtiness was called but tor has already been
compiled. It must be uninstalled, etc. before it can be patched.'
		return 1
	fi

	if [ ! -d "$darknets_tor__tor_configs" ]; then
		echo "darknets_tor__configure_tor_normal could not find a critical install file. It
should be:
	$darknets_tor__tor_configs"
		return 1
	fi

	cp -f "$darknets_tor__tor_configs"/patch-circuit-dirtiness /usr/shew/jails/compile/usr/ports/security/tor/files

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_tor__patch_circuit_dirtiness
}

darknets_tor__install_tor() {
	# This function will install tor, and set up things needed by all tor clients.
	# If this task has already been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_tor__install_tor ]; then
		echo "darknets_tor__install_tor was called but it has already been run, skipping."
		return 0
	fi

	if [ ! -d "$darknets_tor__apps_folder" ]; then
		echo "darknets_tor__install_tor could not find a critical install file. It should be:
	$darknets_tor__apps_folder"
		return 1
	fi

	ports_pkgs_utils__configure_port tor "$darknets_tor__apps_folder"
	ports_pkgs_utils__install_pkg tor /usr/shew/jails/nat_darknets

	user_maint_utils__add_jail_group nat_darknets pf
	gid="`user_maint_utils__return_gid pf /usr/shew/jails/nat_darknets`"

	if
		cat /etc/devfs.rules \
			| grep '^\[.*=[0-9]*\]$' \
			> /dev/null
	then
		rule_number='5'
		while
			cat /etc/devfs.rules \
				| grep "^\[.*=${rule_number}\]$" \
				> /dev/null
		do
			rule_number="`expr "$rule_number" + 1`"
		done
	else
		rule_number='5'
	fi

	echo "
[devfsrules_pf_jail=${rule_number}]
  add include \$devfsrules_hide_all
  add include \$devfsrules_unhide_basic
  add include \$devfsrules_unhide_login
  add path pf unhide mode 0660 group $gid
" >> /etc/devfs.rules

	misc_utils__change_var /etc/rc.conf jail_nat_darknets_devfs_ruleset devfsrules_pf_jail

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_tor__install_tor
}

darknets_tor__configure_tor_normal() {
	# This function will configure the normal tor client. This client behaves
	# normally, and is recommended for browsing that needs to be anonymous. If this
	# task has already been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_tor__configure_tor_normal ]; then
		echo "darknets_tor__configure_tor_normal was called but it has already been run,
skipping."
		return 0
	fi

	if [ ! -d "$darknets_tor__tor_configs" ]; then
		echo "darknets_tor__configure_tor_normal could not find a critical install file. It
should be:
	$darknets_tor__tor_configs"
		return 1
	fi

	if [ ! -f "$darknets_tor__rcd_tor_normal" ]; then
		echo "darknets_tor__configure_tor_normal could not find a critical install file. It
should be:
	$darknets_tor__rcd_tor_normal"
		return 1
	fi

	user_maint_utils__add_jail_user nat_darknets tor_normal none home permanent sensitive pf
	chroot /usr/shew/jails/nat_darknets \
		pw usermod -n tor_normal -s /sbin/nologin

	cp -f "$darknets_tor__tor_configs"/torrc_normal /usr/shew/jails/nat_darknets/usr/shew/permanent/tor_normal/torrc
	chroot /usr/shew/jails/nat_darknets \
		chown tor_normal:tor_normal /usr/shew/permanent/tor_normal/torrc
	chmod 0400 /usr/shew/jails/nat_darknets/usr/shew/permanent/tor_normal/torrc

	chflags noschg /usr/shew/sensitive/nat_darknets/tor_normal.allow
	echo 'cached-certs
cached-consensus
cached-descriptors
cached-descriptors\.new
state' \
		>> /usr/shew/sensitive/nat_darknets/tor_normal.allow
	chflags schg /usr/shew/sensitive/nat_darknets/tor_normal.allow

	cp -f "$darknets_tor__rcd_tor_normal" /usr/shew/jails/nat_darknets/etc/rc.d/shew_tor_normal
	chmod 0500 /usr/shew/jails/nat_darknets/etc/rc.d/shew_tor_normal

		echo '
# Added by darknets_tor__install_tor_normal for tor_normal:
shew_tor_normal_enable="YES"
' >> /usr/shew/jails/nat_darknets/etc/rc.conf

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_tor__configure_tor_normal
}

darknets_tor__configure_tor_two_hop() {
	# This function will configure the two hop tor client. This client will be
	# faster, at the expense of anonymity. It is only recommended for avoiding
	# passive surveillance. You must run darknets_tor__patch_circuit_length for
	# this client to work correctly. If this task has already been done, the
	# function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_tor__configure_tor_two_hop ]; then
		echo "darknets_tor__configure_tor_two_hop was called but it has already been run,
skipping."
		return 0
	fi

	if [ ! -d "$darknets_tor__tor_configs" ]; then
		echo "darknets_tor__configure_tor_two_hop could not find a critical install file. It
should be:
	$darknets_tor__tor_configs"
		return 1
	fi

	if [ ! -f "$darknets_tor__rcd_tor_two_hop" ]; then
		echo "darknets_tor__configure_tor_two_hop could not find a critical install file. It
should be:
	$darknets_tor__rcd_tor_two_hop"
		return 1
	fi

	user_maint_utils__add_jail_user nat_darknets tor_two_hop none home permanent sensitive pf
	chroot /usr/shew/jails/nat_darknets \
		pw usermod -n tor_two_hop -s /sbin/nologin

	cp -f "$darknets_tor__tor_configs"/torrc_two_hop /usr/shew/jails/nat_darknets/usr/shew/permanent/tor_two_hop/torrc
	chroot /usr/shew/jails/nat_darknets \
		chown tor_two_hop:tor_two_hop /usr/shew/permanent/tor_two_hop/torrc
	chmod 0440 /usr/shew/jails/nat_darknets/usr/shew/permanent/tor_two_hop/torrc
		# This is 0440 instead of 0400 so that vidalia can access it, if it is in the same group as tor.

	chflags noschg /usr/shew/sensitive/nat_darknets/tor_two_hop.allow
	echo 'cached-certs
cached-consensus
cached-descriptors
cached-descriptors\.new
state' \
		>> /usr/shew/sensitive/nat_darknets/tor_two_hop.allow
	chflags schg /usr/shew/sensitive/nat_darknets/tor_two_hop.allow

	cp -f "$darknets_tor__rcd_tor_two_hop" /usr/shew/jails/nat_darknets/etc/rc.d/shew_tor_two_hop
	chmod 0500 /usr/shew/jails/nat_darknets/etc/rc.d/shew_tor_two_hop

		echo '
# Added by darknets_tor__install_tor_normal for tor_two_hop:
shew_tor_two_hop_enable="YES"
' >> /usr/shew/jails/nat_darknets/etc/rc.conf

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_tor__configure_tor_two_hop
}

darknets_tor__configure_tor_zero_dirtiness() {
	# This function will configure the zero dirtiness tor client. This client will
	# generate a new circuit for every unique connection attempt. PLEASE BE
	# CAREFUL, ONLY USE THIS SPARINGLY FOR INTERMITTENT CONNECTIONS LIKE EMAIL.
	# Using this for something that generates many connections, e.g. web browsing,
	# can DoS the tor network. You must run darknets_tor__patch_circuit_dirtiness
	# for this client to work correctly. If this task has already been done, the
	# function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_tor__configure_tor_zero_dirtiness ]; then
		echo "darknets_tor__configure_tor_zero_dirtiness was called it has already been run,
skipping."
		return 0
	fi

	if [ ! -d "$darknets_tor__tor_configs" ]; then
		echo "darknets_tor__configure_tor_zero_dirtiness could not find a critical install
file. It should be:
	$darknets_tor__tor_configs"
		return 1
	fi

	if [ ! -f "$darknets_tor__rcd_tor_zero_dirtiness" ]; then
		echo "darknets_tor__configure_tor_zero_dirtiness could not find a critical install
file. It should be:
	$darknets_tor__rcd_tor_zero_dirtiness"
		return 1
	fi

	user_maint_utils__add_jail_user nat_darknets tor_z_dirt none home permanent sensitive pf
	chroot /usr/shew/jails/nat_darknets \
		pw usermod -n tor_z_dirt -s /sbin/nologin

	cp -f "$darknets_tor__tor_configs"/torrc_z_dirt /usr/shew/jails/nat_darknets/usr/shew/permanent/tor_z_dirt/torrc
	chroot /usr/shew/jails/nat_darknets \
		chown tor_z_dirt:tor_z_dirt /usr/shew/permanent/tor_z_dirt/torrc
	chmod 0440 /usr/shew/jails/nat_darknets/usr/shew/permanent/tor_z_dirt/torrc
		# This is 0440 instead of 0400 so that vidalia can access it, if it is in the same group as tor.

	chflags noschg /usr/shew/sensitive/nat_darknets/tor_z_dirt.allow
	echo 'cached-certs
cached-consensus
cached-descriptors
cached-descriptors\.new
state' \
		>> /usr/shew/sensitive/nat_darknets/tor_z_dirt.allow
	chflags schg /usr/shew/sensitive/nat_darknets/tor_z_dirt.allow

	cp -f "$darknets_tor__rcd_tor_zero_dirtiness" /usr/shew/jails/nat_darknets/etc/rc.d/shew_tor_z_dirt
	chmod 0500 /usr/shew/jails/nat_darknets/etc/rc.d/shew_tor_z_dirt

		echo '
# Added by darknets_tor__install_tor_normal for tor_z_dirt:
shew_tor_z_dirt_enable="YES"
' >> /usr/shew/jails/nat_darknets/etc/rc.conf

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_tor__configure_tor_zero_dirtiness
}

darknets_tor__enable_socks() {
	# This function will enable socks for the chosen tor installation. Valid
	# installations supplied by this script are: normal two_hop z_dirt

	tor_install="$1"

	if [ ! -f /usr/shew/jails/nat_darknets/usr/shew/permanent/"tor_${tor_install}"/torrc ]; then
		echo "darknets_tor__enable_socks was called on $tor_install but that
installation's torrc file was not found."
	fi

	if
		cat /usr/shew/install/resources/ports \
			| grep "tor_${tor_install}_socks=" \
			> /dev/null
	then
		echo "darknets_tor__enable_socks was called on $tor_install but there is
already a tor_${tor_install}_socks entry in
/usr/shew/install/resources/ports, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/sensitive/nat_darknets/tor_"$tor_install" ]; then
		echo 'You must choose a valid tor installation.'
		return 1
	fi

	tor_socks="`misc_utils__generate_unique_port`"
	echo "tor_${tor_install}_socks=\"${tor_socks}\"" \
		>> /usr/shew/install/resources/ports

	echo "
# Added by darknets_tor__enable_socks for socks:
SocksListenAddress `jail_maint_utils__return_jail_ip nat_darknets`
SocksPort $tor_socks
" >> /usr/shew/jails/nat_darknets/usr/shew/permanent/"tor_${tor_install}"/torrc
}

darknets_tor__enable_transparent() {
	# This function will enable the transparent proxy and dns proxy for the chosen
	# tor installation. Valid installations supplied by this script are: normal
	# two_hop z_dirt. The use of loopback interfaces is a bit of a hack, to get
	# around PF's inability to properly redirect packets on loopback interfaces.

	tor_install="$1"

	if [ ! -f /usr/shew/jails/nat_darknets/usr/shew/permanent/"tor_${tor_install}"/torrc ]; then
		echo "darknets_tor__enable_socks was called on $tor_install but that
installation's torrc file was not found."
	fi

	if
		cat /usr/shew/install/resources/ports \
			| grep "tor_${tor_install}_transparent=" \
			> /dev/null
	then
		echo "darknets_tor__enable_socks was called on $tor_install but there is
already a tor_${tor_install}_transparent entry in
/usr/shew/install/resources/ports, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/sensitive/nat_darknets/tor_"$tor_install" ]; then
		echo 'You must choose a valid tor installation.'
		return 1
	fi

	tor_ip="`jail_maint_utils__return_jail_ip nat_darknets`"

	tor_dns="`misc_utils__generate_unique_port`"
	echo "tor_${tor_install}_dns=\"${tor_dns}\"" \
		>> /usr/shew/install/resources/ports
	tor_transparent="`misc_utils__generate_unique_port`"
	echo "tor_${tor_install}_transparent=\"${tor_transparent}\"" \
		>> /usr/shew/install/resources/ports

	echo "
# Added by darknets_tor_enable_transparent for transparent proxy and dns:
TransListenAddress `jail_maint_utils__return_jail_ip nat_darknets`
TransPort $tor_transparent

DNSListenAddress $tor_ip
DNSPort $tor_dns
" >> /usr/shew/jails/nat_darknets/usr/shew/permanent/"tor_${tor_install}"/torrc

	loopback="`misc_utils__generate_unique_loopback`"
	echo "tor_${tor_install}_transparent=\"${loopback}\"" \
		>> /usr/shew/install/resources/loopbacks

	cloned_interfaces="`misc_utils__echo_var /etc/rc.conf cloned_interfaces`"
	misc_utils__change_var /etc/rc.conf cloned_interfaces "$cloned_interfaces lo$loopback"

	misc_utils__add_clause /etc/pf.conf '## Redirect Internal:' \
		"# Added by darknets_tor_enable__transparent for ${tor_install}:\\
		rdr pass on lo$loopback inet proto tcp from 127.0.0.0/8 to !127.0.0.0/8 -> $tor_ip port ${tor_transparent}\\
		rdr pass on lo$loopback inet proto tcp from 127.0.0.0/8 to 127.192.0.0/10 -> $tor_ip port ${tor_transparent}\\
		rdr pass on lo$loopback inet proto tcp from 127.0.0.0/8 to port 53 -> $tor_ip port ${tor_dns}\\
		rdr pass on lo$loopback inet proto udp from 127.0.0.0/8 to port 53 -> $tor_ip port ${tor_dns}"
	pfctl -f /etc/pf.conf
}

darknets_tor__add_jail_tor_socks_rules() {
	# This function will add the pf rules that allow a jail to use tor's socks
	# proxy. Valid installations supplied by this script are: normal two_hop
	# z_dirt. The function calls darknets_tor__enable_socks if that tor install
	# does not have it's proxy enabled.

	jail_name="$1"
	tor_install="$2"
	
	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "darknets_tor__add_jail_tor_socks_rules was called on $jail_name but
that jail does not exist."
		return 1
	fi

	if [ ! -f /usr/shew/jails/nat_darknets/usr/shew/permanent/"tor_${tor_install}"/torrc ]; then
		echo "darknets_tor__add_jail_tor_socks_rules was called on $tor_install
but that installation's torrc file was not found."
	fi

	if !
		cat /usr/shew/install/resources/ports \
			| grep "tor_${tor_install}_socks=" \
			> /dev/null
	then
		darknets_tor__enable_socks
	fi

	ip="`jail_maint_utils__return_jail_ip "$jail_name"`"
	nat_darknets_ip="`jail_maint_utils__return_jail_ip nat_darknets`"
	port="`misc_utils__echo_var /usr/shew/install/resources/ports "tor_${tor_install}_socks"`"

	misc_utils__add_clause /etc/pf.conf '## Pass Jails:' \
		"# Added by darknets_tor__add_jail_tor_socks_rules for ${jail_name}:\\
		pass quick inet proto tcp from $ip to $nat_darknets_ip port $port"
	pfctl -f /etc/pf.conf
}

darknets_tor__add_jail_tor_transparent_rules() {
	# This function will add the pf rules that force a jail to use tor's
	# transparent proxy. Valid installations supplied by this script are: normal
	# two_hop z_dirt. The function calls darknets_tor_enable__transparent if
	# that tor install does not have it's proxy enabled.

	jail_name="$1"
	tor_install="$2"
	
	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "darknets_tor__add_jail_tor_transparent_rules was called on $jail_name
but that jail does not exist."
		return 1
	fi

	if [ ! -f /usr/shew/jails/nat_darknets/usr/shew/permanent/"tor_${tor_install}"/torrc ]; then
		echo "darknets_tor__add_jail_tor_transparent_rules was called on
$tor_install but that installation's torrc file was not found."
	fi

	if !
		cat /usr/shew/install/resources/ports \
			| grep "tor_${tor_install}_transparent=" \
			> /dev/null
	then
		darknets_tor__enable_transparent
	fi

	ip="`jail_maint_utils__return_jail_ip "$jail_name"`"
	nat_darknets_ip="`jail_maint_utils__return_jail_ip nat_darknets`"
	port="`misc_utils__echo_var /usr/shew/install/resources/ports "tor_${tor_install}_transparent"`"
	loopback="`misc_utils__echo_var /usr/shew/install/resources/loopbacks "tor_${tor_install}_transparent"`"

	misc_utils__add_clause /etc/pf.conf '## Route-to:' \
		"# Added by darknets_tor__add_jail_tor_transparent_rules for ${jail_name}:\\
		pass out route-to lo$loopback inet proto tcp from $ip to !127.0.0.0/8\\
		pass out route-to lo$loopback inet proto tcp from $ip to 127.192.0.0/10\\
		pass out route-to lo$loopback inet proto tcp from $ip to port 53\\
		pass out route-to lo$loopback inet proto udp from $ip to port 53"
	pfctl -f /etc/pf.conf

	echo "nameserver $nat_darknets_ip" \
		> /usr/shew/jails/"$jail_name"/etc/resolv.conf
	chmod 0444 /usr/shew/jails/"$jail_name"/etc/resolv.conf
	chflags schg /usr/shew/jails/"$jail_name"/etc/resolv.conf
}
