#!/bin/sh

# Contents:	host_entropy__install_entropy

# Variable defaults:
  : ${host_entropy__rcd_entropy="/usr/shew/install/shewstring/libexec/host/rc.d/shew_entropy"}
								# This file is the default entropy rc.d file.

host_entropy__install_entropy() {
	# Because cron is not enabled on the default system, an alternative system must
	# be used to save entropy through reboots. This script will install an rc.d
	# file which will fork off a process to periodically run save-entropy.

	if [ -f /usr/shew/install/done/host_entropy__install_entropy ]; then
		echo "host_entropy__install_entropy was called but it has already been run, skipping."
		return 0
	fi

	if [ ! -f "$host_entropy__rcd_entropy" ]; then
		echo "host_entropy__install_entropy could not find a critical install file. It should be:
	$host_entropy__rcd_entropy"
		return 1
	fi

	mkdir -p /usr/shew/sensitive/host/root/entropy
	chmod 0700 /usr/shew/sensitive/host/root/entropy

	chflags noschg /usr/shew/sensitive/host/root.allow
	echo 'entropy
entropy/saved-entropy\.[1-8]' \
		>> /usr/shew/sensitive/host/root.allow
	chflags schg /usr/shew/sensitive/host/root.allow

	cp -f "$host_entropy__rcd_entropy" /etc/rc.d/shew_entropy
	chmod 0500 /etc/rc.d/shew_entropy

	echo '
# Added by libexec/host/exec.sh for entropy collection:
entropy_dir="/usr/shew/sensitive/host/root/entropy"
shew_entropy_enable="YES"
' >> /etc/rc.conf

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/host_entropy__install_entropy
}
