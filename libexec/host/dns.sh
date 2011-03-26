#!/bin/sh

# The named (aka BIND) home page: https://www.isc.org/software/bind

# Requires:	lib/user_maint_utils.sh

# Contents:	host_dns__install_named
#		host_dns__add_jail_dns_rules

# Variable defaults:
  : ${host_dns__named_configs="/usr/shew/install/shewstring/libexec/host/misc/named"}
								# This file is the default named folder for config files.
  : ${host_dns__rcd_named="/usr/shew/install/shewstring/libexec/host/rc.d/shew_named"}
								# This file is the default named rc.d file.

host_dns__install_named() {
	# This function will install a chroot for named and configure it for chrooting.
	# The named server will use DNSSEC with a trust anchor at the root zone.
	# Running host_dns__add_jail_dns_rules will allow you to use this server for
	# resolution. If this task has already been done, the function complains and
	# returns true.

	if [ -f /usr/shew/install/done/host_dns__install_named ]; then
		echo "host_dns__install_named was called but it has already been run, skipping."
		return 0
	fi

	if [ ! -d "$host_dns__named_configs" ]; then
		echo "host_dns__install_named could not find a critical install file. It should be:
	$host_dns__named_configs"
		return 1
	fi

	if [ ! -f "$host_dns__rcd_named" ]; then
		echo "host_dns__install_named could not find a critical install file. It should be:
	$host_dns__rcd_named"
		return 1
	fi

	user_maint_utils__add_user named none chroots
	pw usermod -n named -s /sbin/nologin

	if [ ! -d /usr/shew/chroots ]; then
		mkdir -p /usr/shew/chroots
		chown root:chroots /usr/shew/chroots
		chmod 0750 /usr/shew/chroots
	fi

	mkdir -p \
		/usr/shew/chroots/named \
		/usr/shew/chroots/named/dev \
		/usr/shew/chroots/named/etc/namedb \
		/usr/shew/chroots/named/tmp
	chmod -R 0500 /usr/shew/chroots/named

	ip="`jail_maint_utils__generate_unique_127ip`"
	echo "$ip named named.my.domain" \
		>> /etc/hosts

	cat "$host_dns__named_configs"/named.conf \
		| sed "s/listen-on { ; };/listen-on { ${ip}; };/" \
		> /usr/shew/chroots/named/etc/namedb/named.conf
	cp -f "$host_dns__named_configs"/root.hints /usr/shew/chroots/named/etc/namedb/root.hints
	chmod 0400 /usr/shew/chroots/named/etc/namedb/named.conf
	chmod 0400 /usr/shew/chroots/named/etc/namedb/root.hints

	chown -R named:named /usr/shew/chroots/named

	cp -f "$host_dns__rcd_named" /etc/rc.d/shew_named
	chmod 0500 /etc/rc.d/shew_named

	loopback="`misc_utils__generate_unique_loopback`"
	echo "named=\"${loopback}\"" \
		>> /usr/shew/install/resources/loopbacks

	cloned_interfaces="`misc_utils__echo_var /etc/rc.conf cloned_interfaces`"
	misc_utils__change_var /etc/rc.conf cloned_interfaces "$cloned_interfaces lo$loopback"

	ifconfig "lo$loopback" create
	ifconfig "lo$loopback" inet "$ip"

	misc_utils__add_clause /etc/pf.conf '## Pass Host:' \
		"# Added by host_dns__install_named for named:\\
		pass quick inet proto tcp from !127.0.0.0/8 to !127.0.0.0/8 port 53\\
		pass quick inet proto udp from !127.0.0.0/8 to !127.0.0.0/8 port 53\\
		pass quick inet proto tcp from 127.0.0.1 to $ip port 53\\
		pass quick inet proto udp from 127.0.0.1 to $ip port 53"
	pfctl -f /etc/pf.conf

	echo '
# Added by host_dns__install_named for resolver:
order hosts bind
multi off
nospoof on
alert on
' > /etc/host.conf

	echo "
# Added by host_dns__install_named for named:
ifconfig_lo${loopback}=\"inet ${ip}\"
shew_named_enable=\"YES\"
" >> /etc/rc.conf

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/host_dns__install_named
}

host_dns__add_jail_dns_rules() {
	# This function will add the pf rules and resolver entries that allow a jail to
	# use the local dns server.

	jail_name="$1"

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "host_dns__add_jail_dns_rules was called on $jail_name but that jail
does not exist."
		return 1
	fi

	echo '
# Added by host_dns__add_jail_dns_rules for resolver:
order hosts bind
multi off
nospoof on
alert on
' > /usr/shew/jails/"$jail_name"/etc/host.conf

	jail_ip="`jail_maint_utils__return_jail_ip "$jail_name"`"
	named_ip="`
		cat /etc/hosts \
			| grep 'named named.my.domain *$' \
			| tail -n 1 \
			| sed 's/ named.*//'
	`"

	misc_utils__add_clause /etc/pf.conf '## Pass Jails:' \
		"# Added by host_dns__add_jail_dns_rules for ${jail_name}:\\
		pass quick inet proto tcp from $jail_ip to $named_ip port 53\\
		pass quick inet proto udp from $jail_ip to $named_ip port 53"
	pfctl -f /etc/pf.conf

	echo "nameserver $named_ip" \
		> /usr/shew/jails/"$jail_name"/etc/resolv.conf
	chmod 0444 /usr/shew/jails/"$jail_name"/etc/resolv.conf
	chflags schg /usr/shew/jails/"$jail_name"/etc/resolv.conf
}
