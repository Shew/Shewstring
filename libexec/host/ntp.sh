#!/bin/sh

# The NTPD home page: http://www.ntp.org/

# Requires:	lib/user_maint_utils.sh

# Contents:	host_ntp__install_ntpd

# Variable defaults:
  : ${host_ntp__ntp_conf="/usr/shew/install/shewstring/libexec/host/misc/ntp.conf"}
								# This file is the default ntp.conf file.
  : ${host_ntp__rcd_ntpd="/usr/shew/install/shewstring/libexec/host/rc.d/shew_ntpd"}
								# This file is the default ntp rc.d file.

host_ntp__install_ntpd() {
	# This function will configure NTPD. The NTPD server will use the pool.ntp.org
	# servers by default. If this task has already been done, the function
	# complains and returns true.

	if [ -f /usr/shew/install/done/host_ntp__install_ntpd ]; then
		echo "host_ntp__install_ntpd was called but it has already been run, skipping."
		return 0
	fi

	if [ ! -f "$host_ntp__ntp_conf" ]; then
		echo "host_ntp__install_ntpd could not find a critical install file. It should be:
	$host_ntp__ntp_conf"
		return 1
	fi

	if [ ! -f "$host_ntp__rcd_ntpd" ]; then
		echo "host_ntp__install_ntpd could not find a critical install file. It should be:
	$host_ntp__rcd_ntpd"
		return 1
	fi

	cp -f "$host_ntp__ntp_conf" /etc/ntp.conf
	chmod 0400 /etc/ntp.conf

	echo '0.000' \
		> /usr/shew/sensitive/host/root/ntp.drift
	chmod 0600 /usr/shew/sensitive/host/root/ntp.drift

	chflags noschg /usr/shew/sensitive/host/root.allow
	echo 'ntp\.drift' \
		>> /usr/shew/sensitive/host/root.allow
	chflags schg /usr/shew/sensitive/host/root.allow

	cp -f "$host_ntp__rcd_ntpd" /etc/rc.d/shew_ntpd
	chmod 0500 /etc/rc.d/shew_ntpd

	misc_utils__add_clause /etc/pf.conf '## Pass Host:' \
		'# Added by host_ntp__install_ntpd for ntpd:\
		pass quick inet proto udp from !127.0.0.0/8 to !127.0.0.0/8 port 123'
	pfctl -f /etc/pf.conf

	echo '
# Added by host_ntp__install_ntpd for ntpd:
shew_ntpd_enable="YES"
' >> /etc/rc.conf

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/host_ntp__install_ntpd
}
