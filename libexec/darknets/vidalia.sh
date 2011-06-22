#!/bin/sh

# The Tor home page: https://www.torproject.org/

# Requires:	lib/user_maint_utils.sh
#		lib/ports_pkgs_utils.sh

# Contents:	darknets_vidalia__install_vidalia
#		darknets_vidalia__configure_tor_normal_vidalia
#		darknets_vidalia__configure_tor_two_hop_vidalia
#		darknets_vidalia__configure_tor_zero_dirtiness_vidalia

# Variable defaults:
  : ${darknets_vidalia__vidalia_configs='/usr/shew/install/shewstring/libexec/darknets/misc/vidalia'}
								# This file is the default vidalia folder for config files.
  : ${darknets_vidalia__apps_folder='/usr/shew/install/shewstring/libexec/darknets/apps'}
								# The default darknets apps folder.

darknets_vidalia__install_vidalia() {
	# This function will install vidalia. If this task has already been done, the
	# function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_vidalia__install_vidalia ]; then
		echo "darknets_vidalia__install_vidalia was called but it has already been run,
skipping."
		return 0
	fi

	if [ ! -d "$darknets_vidalia__apps_folder" ]; then
		echo "darknets_vidalia__install_vidalia could not find a critical install file. It
should be:
	$darknets_vidalia__apps_folder"
		return 1
	fi

	ports_pkgs_utils__configure_port vidalia "$darknets_vidalia__apps_folder"
	ports_pkgs_utils__install_pkg vidalia /usr/shew/jails/nat_darknets

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_vidalia__install_vidalia
}

darknets_vidalia__configure_tor_normal_vidalia() {
	# This function will configure vidalia to control the normal tor client. If
	# this task has already been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_vidalia__configure_tor_normal_vidalia ]; then
		echo "darknets_vidalia__configure_tor_normal_vidalia was called but it has already
been run, skipping."
		return 0
	fi

	if [ ! -d "$darknets_vidalia__vidalia_configs" ]; then
		echo "darknets_vidalia__configure_tor_normal_vidalia could not find a critical
install file. It should be:
	$darknets_vidalia__vidalia_configs"
		return 1
	fi

	password="`
		dd if=/dev/random count=2 \
			| md5
	`"
	user_maint_utils__add_jail_user nat_darknets vidalia_normal "$password" tor_normal home permanent
	jail_maint_utils__setup_program_telnet nat_darknets vidalia_normal "$password"
	jail_maint_utils__setup_program_desktop nat_darknets vidalia_normal \
		/usr/shew/jails/nat_darknets/usr/local/share/icons/hicolor/48x48/apps/vidalia.png \
		/usr/local/bin/vidalia

	ip="`jail_maint_utils__return_jail_ip nat_darknets`"
	control_port="`misc_utils__generate_unique_port`"
	echo "tor_normal_control_port=\"${control_port}\"" \
		>> /usr/shew/install/resources/ports

	vidalia_password="`
		dd if=/dev/random count=2 \
			| md5
	`"

	cat "$darknets_vidalia__vidalia_configs"/vidalia_normal.conf \
		| sed "s/ControlAddr=/&${ip}/" \
		| sed "s/ControlPort=/&${control_port}/" \
		| sed "s/ControlPassword=/&${vidalia_password}/" \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/vidalia_normal/vidalia.conf
	mkdir -p /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/vidalia_normal/.vidalia/
	ln -s /usr/shew/permanent/vidalia_normal/vidalia.conf \
		/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/vidalia_normal/.vidalia/vidalia.conf
	chmod -h 0444 /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/vidalia_normal/.vidalia/vidalia.conf
	chflags -h schg /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/vidalia_normal/.vidalia/vidalia.conf

	jid="`jail_maint_utils__return_jail_jid nat_darknets`"

	vidalia_hash="`
		jexec -U tor_normal "$jid" \
			tor --quiet --hash-password "$vidalia_password"
	`"

	echo "
# Added by darknets_vidalia__configure_tor_normal_vidalia for Vidalia:
ControlListenAddress $ip
ControlPort $control_port
HashedControlPassword $vidalia_hash
" >> /usr/shew/jails/nat_darknets/usr/shew/permanent/tor_normal/torrc

	misc_utils__add_clause /etc/pf.conf '## Pass Jails:' \
		"# Added by darknets_vidalia__configure_tor_normal_vidalia for Vidalia:\\
		pass quick inet proto tcp from $ip to $ip port $control_port"
	pfctl -f /etc/pf.conf

	chmod 0440 /usr/shew/jails/nat_darknets/usr/shew/permanent/tor_normal/torrc
	# This is changed to 0440 so that vidalia can read it.

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_vidalia__configure_tor_normal_vidalia
}

darknets_vidalia__configure_tor_two_hop_vidalia() {
	# This function will configure vidalia to control the two hop tor client. If
	# this task has already been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_vidalia__configure_tor_two_hop_vidalia ]; then
		echo "darknets_vidalia__configure_tor_two_hop_vidalia was called but it has already
been run, skipping."
		return 0
	fi

	if [ ! -d "$darknets_vidalia__vidalia_configs" ]; then
		echo "darknets_vidalia__configure_tor_two_hop_vidalia could not find a critical
install file. It should be:
	$darknets_vidalia__vidalia_configs"
		return 1
	fi

	password="`
		dd if=/dev/random count=2 \
			| md5
	`"
	user_maint_utils__add_jail_user nat_darknets vidalia_two_hop "$password" tor_two_hop home permanent
	jail_maint_utils__setup_program_telnet nat_darknets vidalia_two_hop "$password"
	jail_maint_utils__setup_program_desktop nat_darknets vidalia_two_hop \
		/usr/shew/jails/nat_darknets/usr/local/share/icons/hicolor/48x48/apps/vidalia.png \
		/usr/local/bin/vidalia

	ip="`jail_maint_utils__return_jail_ip nat_darknets`"
	control_port="`misc_utils__generate_unique_port`"
	echo "tor_two_hop_control_port=\"${control_port}\"" \
		>> /usr/shew/install/resources/ports

	vidalia_password="`
		dd if=/dev/random count=2 \
			| md5
	`"

	cat "$darknets_vidalia__vidalia_configs"/vidalia_two_hop.conf \
		| sed "s/ControlAddr=/&${ip}/" \
		| sed "s/ControlPort=/&${control_port}/" \
		| sed "s/ControlPassword=/&${vidalia_password}/" \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/vidalia_two_hop/vidalia.conf
	mkdir -p /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/vidalia_two_hop/.vidalia/
	ln -s /usr/shew/permanent/vidalia_two_hop/vidalia.conf \
		/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/vidalia_two_hop/.vidalia/vidalia.conf
	chmod -h 0444 /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/vidalia_two_hop/.vidalia/vidalia.conf
	chflags -h schg /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/vidalia_two_hop/.vidalia/vidalia.conf

	jid="`jail_maint_utils__return_jail_jid nat_darknets`"

	vidalia_hash="`
		jexec -U tor_two_hop "$jid" \
			tor --quiet --hash-password "$vidalia_password"
	`"

	echo "
# Added by darknets_vidalia__configure_tor_two_hop_vidali for vidalia:
ControlListenAddress $ip
ControlPort $control_port
HashedControlPassword $vidalia_hash
" >> /usr/shew/jails/nat_darknets/usr/shew/permanent/tor_two_hop/torrc

	misc_utils__add_clause /etc/pf.conf '## Pass Jails:' \
		"# Added by darknets_vidalia__configure_tor_two_hop_vidalia for Vidalia:\\
		pass quick inet proto tcp from $ip to $ip port $control_port"
	pfctl -f /etc/pf.conf

	chmod 0440 /usr/shew/jails/nat_darknets/usr/shew/permanent/tor_two_hop/torrc
	# This is changed to 0440 so that vidalia can read it.

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_vidalia__configure_tor_two_hop_vidalia
}

darknets_vidalia__configure_tor_zero_dirtiness_vidalia() {
	# This function will configure vidalia to control the zero dirtiness tor
	# client. If this task has already been done, the function complains and
	# returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_vidalia__configure_tor_zero_dirtiness_vidalia ]; then
		echo "darknets_vidalia__configure_tor_zero_dirtiness_vidalia was called but it has
already been run, skipping."
		return 0
	fi

	if [ ! -d "$darknets_vidalia__vidalia_configs" ]; then
		echo "darknets_vidalia__configure_tor_zero_dirtiness_vidalia could not find a
critical install file. It should be:
	$darknets_vidalia__vidalia_configs"
		return 1
	fi

	password="`
		dd if=/dev/random count=2 \
			| md5
	`"
	user_maint_utils__add_jail_user nat_darknets vidalia_z_dirt "$password" tor_z_dirt home permanent
	jail_maint_utils__setup_program_telnet nat_darknets vidalia_z_dirt "$password"
	jail_maint_utils__setup_program_desktop nat_darknets vidalia_z_dirt \
		/usr/shew/jails/nat_darknets/usr/local/share/icons/hicolor/48x48/apps/vidalia.png \
		/usr/local/bin/vidalia

	ip="`jail_maint_utils__return_jail_ip nat_darknets`"
	control_port="`misc_utils__generate_unique_port`"
	echo "tor_z_dirt_control_port=\"${control_port}\"" \
		>> /usr/shew/install/resources/ports

	vidalia_password="`
		dd if=/dev/random count=2 \
			| md5
	`"

	cat "$darknets_vidalia__vidalia_configs"/vidalia_z_dirt.conf \
		| sed "s/ControlAddr=/&${ip}/" \
		| sed "s/ControlPort=/&${control_port}/" \
		| sed "s/ControlPassword=/&${vidalia_password}/" \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/vidalia_z_dirt/vidalia.conf
	mkdir -p /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/vidalia_z_dirt/.vidalia/
	ln -s /usr/shew/permanent/vidalia_z_dirt/vidalia.conf \
		/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/vidalia_z_dirt/.vidalia/vidalia.conf
	chmod -h 0444 /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/vidalia_z_dirt/.vidalia/vidalia.conf
	chflags -h schg /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/vidalia_z_dirt/.vidalia/vidalia.conf

	jid="`jail_maint_utils__return_jail_jid nat_darknets`"

	vidalia_hash="`
		jexec -U tor_z_dirt "$jid" \
			tor --quiet --hash-password "$vidalia_password"
	`"

	echo "
# Added by darknets_vidalia__configure_tor_normal_vidalia for vidalia:
ControlListenAddress $ip
ControlPort $control_port
HashedControlPassword $vidalia_hash
" >> /usr/shew/jails/nat_darknets/usr/shew/permanent/tor_z_dirt/torrc

	misc_utils__add_clause /etc/pf.conf '## Pass Jails:' \
		"# Added by darknets_vidalia__configure_tor_zero_dirtiness_vidalia for Vidalia:\\
		pass quick inet proto tcp from $ip to $ip port $control_port"
	pfctl -f /etc/pf.conf

	chmod 0440 /usr/shew/jails/nat_darknets/usr/shew/permanent/tor_z_dirt/torrc
	# This is changed to 0440 so that vidalia can read it.

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_vidalia__configure_tor_zero_dirtiness_vidalia
}
