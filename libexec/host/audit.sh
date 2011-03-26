#!/bin/sh

# Contents:	host_audit__install_audit

# Variable defaults:
  : ${host_audit__audit_script="/usr/shew/install/shewstring/libexec/host/misc/audit.sh"}
									# This file is the default location for audit.sh.

host_audit__install_audit() {
	# This function will install audit.sh, which cleans out the sensitive folder.
	# This is necessary because some programs do not properly respect symbolic
	# links, and must have whole folders linked for them, thus files can not be
	# separated by linking alone. See $host_audit__audit_script for a more detailed
	# description. If this task has already been done, the function complains and
	# returns true.

	if [ -f /usr/shew/install/done/host_audit__install_audit ]; then
		echo "host_audit__install_audit was called but it has already been run, skipping."
		return 0
	fi

	if [ ! -f "$host_audit__audit_script" ]; then
		echo "host_audit__install_audit could not find a critical install file. It should be:
	$host_audit__audit_script"
		return 1
	fi

	cp -f "$host_audit__audit_script" /usr/shew/permanent/root/audit.sh
	chmod 0500 /usr/shew/permanent/root/audit.sh

	misc_utils__add_clause /etc/rc.shutdown '# Insert other shutdown procedures here' \
		'/usr/shew/permanent/root/audit.sh'

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/host_audit__install_audit
}
