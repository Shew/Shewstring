#!/bin/sh

# Requires:	lib/misc_utils.sh
#		lib/jail_maint_utils.sh
#		lib/ports_pkgs_utils.sh
#		lib/user_maint_utils.sh

# Contents:	lockdown_portaudit__install_portaudit
#		lockdown_portaudit__print_full_audit

# Variable defaults:
  : ${lockdown_portaudit__apps_folder='/usr/shew/install/shewstring/libexec/lockdown/apps'}
					# The default lockdown apps folder.

lockdown_portaudit__install_portaudit() {
	# This function will install and configure portaudit. If this task has
	# already been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/lockdown_portaudit__install_portaudit ]; then
		echo "lockdown_portaudit__install_portaudit was called but it has already been run,
skipping."
		return 0
	fi

	if [ ! -d "$lockdown_portaudit__apps_folder" ]; then
		echo "lockdown_portaudit__install_portaudit not find a critical install file. It
should be:
	$lockdown_portaudit__apps_folder"
		return 1
	fi

	ports_pkgs_utils__configure_port portaudit "$lockdown_portaudit__apps_folder"
	ports_pkgs_utils__compile_port portaudit

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/lockdown_portaudit__install_portaudit
}

lockdown_portaudit__print_full_audit() {
	# This function will use portaudit to do a full audit of all jails.

	jid="`jail_maint_utils__return_jail_jid compile`"

	jexec "$jid" \
		portaudit -F

	jexec "$jid" \
		pkg_info \
		| sed 's/ .*//' \
		| jexec "$jid" \
		xargs portaudit \
		|| true
	# portaudit returns false when it finds a vulnerability.
}
