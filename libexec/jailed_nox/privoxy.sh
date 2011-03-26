#!/bin/sh

# This script will install Privoxy in a jail. The Privoxy home page:
# http://www.privoxy.org/

# Arguments:
  jail_name="$arg_1"
  unset arg_1

# Requires:	lib/misc_utils.sh
#		lib/ports_pkgs_utils.sh

# Contents:	jailed_nox_privoxy__enable_tor_socks
#		jailed_nox_privoxy__enable_i2p_socks
#		jailed_nox_privoxy__enable_i2p_http_https

# Variable defaults:
  : ${jailed_nox_privoxy__privoxy_configs='/usr/shew/install/shewstring/libexec/jailed_nox/misc/privoxy'}
								# This file is the default privoxy configs.
  : ${jailed_nox_privoxy__rcd_privoxy='/usr/shew/install/shewstring/libexec/jailed_nox/rc.d/shew_privoxy'}
								# This file is the default privoxy rc.d file.
  : ${jailed_nox_privoxy__apps_folder='/usr/shew/install/shewstring/libexec/jailed_nox/apps'}
								# The default jailed_nox apps folder.

# Execute:

if [ -f /usr/shew/install/done/"$jail_name"/jailed_nox_privoxy ]; then
	echo "jailed_nox/privoxy.sh was called on $jail_name but it has already
been run, skipping."
		# Normally this would return 0, but then you wouldn't be able to load functions
		# if the script has already been run.
else

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "jailed_nox/privoxy.sh was called on $jail_name but that jail does not exist."
		return 1
	fi

	if [ ! -d "$jailed_nox_privoxy__privoxy_configs" ]; then
		echo "jailed_nox/privoxy.sh could not find a critical install file. It should be:
	$jailed_nox_privoxy__privoxy_configs"
		return 1
	fi

	if [ ! -f "$jailed_nox_privoxy__rcd_privoxy" ]; then
		echo "jailed_nox/privoxy.sh could not find a critical install file. It should be:
	$jailed_nox_privoxy__rcd_privoxy"
		return 1
	fi

	if [ ! -d "$jailed_nox_privoxy__apps_folder" ]; then
		echo "jailed_nox/privoxy.sh could not find a critical install file. It should be:
	$jailed_nox_privoxy__apps_folder"
		return 1
	fi

	ports_pkgs_utils__configure_port privoxy "$jailed_nox_privoxy__apps_folder"
	ports_pkgs_utils__install_pkg privoxy /usr/shew/jails/"$jail_name"

	user_maint_utils__add_jail_user "$jail_name" privoxy none home permanent
	chroot /usr/shew/jails/"$jail_name" \
		pw usermod -n privoxy -s /sbin/nologin

	cp -Rf /usr/shew/jails/"$jail_name"/usr/local/etc/privoxy/ /usr/shew/jails/"$jail_name"/usr/shew/permanent/privoxy

	if
		ls /usr/shew/jails/"$jail_name"/usr/shew/permanent/privoxy/templates/* \
			> /dev/null \
			2> /dev/null
		# This protects the following for loop from invalid input if there are no files.
	then
		for val in /usr/shew/jails/"$jail_name"/usr/shew/permanent/privoxy/templates/*; do
			cp -f "$val" "${val}.tmp"
			cat "${val}.tmp" \
				| sed 's/ *<link rel="shortcut icon".*//' \
				> "$val"
			rm -f "${val}.tmp"
		done
	fi
		# This removes the favicons from the privoxy error pages.
		# This is done because the favicons replace the favicon the website has selected when you bookmark
		# the website and then hit an error when reaching it. This is a minor annoyance.

	ip="`jail_maint_utils__return_jail_ip "$jail_name"`"
	port="`misc_utils__generate_unique_port`"
	echo "${jail_name}_privoxy=\"${port}\"" \
		>> /usr/shew/install/resources/ports

	cat "${jailed_nox_privoxy__privoxy_configs}/config" \
		| sed "s/listen-address/& ${ip}:${port}/" \
		> /usr/shew/jails/"$jail_name"/usr/shew/permanent/privoxy/config
	cp -f "${jailed_nox_privoxy__privoxy_configs}/user.action" \
		/usr/shew/jails/"$jail_name"/usr/shew/permanent/privoxy/user.action

	misc_utils__add_clause /etc/pf.conf '## Pass Jails:' \
		"# Added by jailed_nox/privoxy.sh for privoxy:\\
		pass quick inet proto tcp from $ip to $ip port $port"
	pfctl -f /etc/pf.conf

	cp -f "$jailed_nox_privoxy__rcd_privoxy" /usr/shew/jails/"$jail_name"/etc/rc.d/shew_privoxy
	chmod 0500 /usr/shew/jails/"$jail_name"/etc/rc.d/shew_privoxy

	echo '
# Added by jailed_nox/privoxy.sh for privoxy:
shew_privoxy_enable="YES"
' >> /usr/shew/jails/"$jail_name"/etc/rc.conf

	if [ ! -d /usr/shew/install/done/"$jail_name" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"
		chmod 0700 /usr/shew/install/done/"$jail_name"
	fi

	touch /usr/shew/install/done/"$jail_name"/jailed_nox_privoxy
fi

# Functions:

jailed_nox_privoxy__enable_tor_socks() {
	# This function will enable the routing of all traffic without its own rule to
	# tor.

	jail_name="$1"
	tor_install="$2"
	
	if [ -f /usr/shew/install/done/"$jail_name"/jailed_nox_privoxy__enable_tor_socks ]; then
		echo "jailed_nox_privoxy__enable_tor_socks was called but it has already been run,
skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "jailed_nox_privoxy__enable_tor_socks was called on $jail_name but that jail
does not exist."
		return 1
	fi

	if !
		cat /usr/shew/install/resources/ports \
			| grep "tor_${tor_install}_socks=" \
			> /dev/null
	then
		echo "jailed_nox_privoxy__enable_tor_socks was called on $tor_install but
that install doesn't have a socks proxy declared in /usr/shew/install/resources/ports."
		return 1
	fi

	ip="`jail_maint_utils__return_jail_ip nat_darknets`"
	port="`misc_utils__echo_var /usr/shew/install/resources/ports "tor_${tor_install}_socks"`"

	misc_utils__add_clause /usr/shew/jails/"$jail_name"/usr/shew/permanent/privoxy/config '## Route SOCKS:' \
		"# Added by jailed_nox_privoxy__enable_tor_socks for tor:\\
		forward-socks4a / ${ip}:$port ."

	if [ ! -d /usr/shew/install/done/"$jail_name" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"
		chmod 0700 /usr/shew/install/done/"$jail_name"
	fi
	
	touch /usr/shew/install/done/"$jail_name"/jailed_nox_privoxy__enable_tor_socks
}

jailed_nox_privoxy__enable_i2p_socks() {
	# This function will enable the routing of all *.i2p traffic to i2p.

	jail_name="$1"
	
	if [ -f /usr/shew/install/done/"$jail_name"/jailed_nox_privoxy__enable_i2p_socks ]; then
		echo "jailed_nox_privoxy__enable_i2p_socks was called but it has already been run,
skipping."
		return 0
	fi
	
	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "jailed_nox_privoxy__enable_i2p_socks was called on $jail_name but
that jail does not exist."
		return 1
	fi

	if !
		cat /usr/shew/install/resources/ports \
			| grep "i2p_socks=" \
			> /dev/null
	then
		echo "jailed_nox_privoxy__enable_i2p_socks was called but i2p doesn't have a socks
proxy declared in /usr/shew/install/resources/ports."
		return 1
	fi

	ip="`jail_maint_utils__return_jail_ip nat_darknets`"
	port="`misc_utils__echo_var /usr/shew/install/resources/ports i2p_socks`"

	misc_utils__add_clause /usr/shew/jails/"$jail_name"/usr/shew/permanent/privoxy/config '## Route SOCKS:' \
		"# Added by jailed_nox_privoxy__enable_i2p_socks for i2p:\\
		forward-socks4a .i2p/ ${ip}:$port ."

	if [ ! -d /usr/shew/install/done/"$jail_name" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"
		chmod 0700 /usr/shew/install/done/"$jail_name"
	fi
	
	touch /usr/shew/install/done/"$jail_name"/jailed_nox_privoxy__enable_i2p_socks
}

jailed_nox_privoxy__enable_i2p_http_https() {
	# This function will enable the routing of *.i2p HTTP and HTTPS traffic to i2p.

	jail_name="$1"
	
	if [ -f /usr/shew/install/done/"$jail_name"/jailed_nox_privoxy__enable_i2p_http_https ]; then
		echo "jailed_nox_privoxy__enable_i2p_http_https was called but it has already been
run, skipping."
		return 0
	fi
	
	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "jailed_nox_privoxy__enable_i2p_http_https was called on $jail_name
but that jail does not exist."
		return 1
	fi

	if !
		cat /usr/shew/install/resources/ports \
			| grep "i2p_http=" \
			> /dev/null
	then
		echo "jailed_nox_privoxy__enable_i2p_http_https was called but i2p doesn't have a
http proxy declared in /usr/shew/install/resources/ports."
		return 1
	fi

	if !
		cat /usr/shew/install/resources/ports \
			| grep "i2p_https=" \
			> /dev/null
	then
		echo "jailed_nox_privoxy__enable_i2p_http_https was called but i2p doesn't have a
https proxy declared in /usr/shew/install/resources/ports."
		return 1
	fi

	ip="`jail_maint_utils__return_jail_ip nat_darknets`"
	http_port="`misc_utils__echo_var /usr/shew/install/resources/ports i2p_http`"
	https_port="`misc_utils__echo_var /usr/shew/install/resources/ports i2p_https`"

	misc_utils__add_clause /usr/shew/jails/"$jail_name"/usr/shew/permanent/privoxy/config '## Route HTTP:' \
		"# Added by jailed_nox_privoxy__enable_i2p_http_https for i2p:\\
		forward .i2p:80/ ${ip}:${http_port}\\
		forward .i2p:443/ ${ip}:$https_port"

	if [ ! -d /usr/shew/install/done/"$jail_name" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"
		chmod 0700 /usr/shew/install/done/"$jail_name"
	fi
	
	touch /usr/shew/install/done/"$jail_name"/jailed_nox_privoxy__enable_i2p_http_https
}
