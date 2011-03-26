#!/bin/sh

# This script will install Sudo. The Sudo home page: http://www.sudo.ws/

# Requires:	lib/misc_utils.sh
#		lib/ports_pkgs_utils.sh

# Contents:	nojailed_nox_sudo__add_sudo_user
#		nojailed_nox_sudo__lock_sudoers

# Variable defaults:
  : ${nojailed_nox_sudo__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_nox/apps'}
								# The default nojailed_nox apps folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_nox_sudo ]; then
	echo "nojailed_nox/sudo.sh was called but it has already been run, skipping."
		# Normally this would return 0, but then you wouldn't be able to load functions
		# if the script has already been run.
else

	if [ ! -d "$nojailed_nox_sudo__apps_folder" ]; then
		echo "nojailed_nox/sudo.sh could not find a critical install file. It should be:
	$nojailed_nox_sudo__apps_folder"
		return 1
	fi

	ports_pkgs_utils__configure_port sudo "$nojailed_nox_sudo__apps_folder"
	ports_pkgs_utils__install_pkg sudo

	if [ ! -f /usr/local/etc/sudoers ]; then
		cp /usr/local/etc/sudoers.default /usr/local/etc/sudoers
	fi
	chflags opaque /usr/local/etc/sudoers

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/nojailed_nox_sudo
fi

# Functions:

nojailed_nox_sudo__add_sudo_user() {
	# This function will enable all privileges for a user. WARNING: This is
	# effectively giving them root access.

	user="$1"

	cp -f /usr/local/etc/sudoers /usr/local/etc/sudoers.tmp

	misc_utils__add_clause /usr/local/etc/sudoers.tmp '# User privilege specification' "$user ALL=(ALL) ALL"

	visudo -c -f /usr/local/etc/sudoers.tmp
		# This verfies the integrety of the sudoers file.

	rm -f /usr/local/etc/sudoers
	cp -f /usr/local/etc/sudoers.tmp /usr/local/etc/sudoers
	chmod 0660 /usr/local/etc/sudoers
	chflags opaque /usr/local/etc/sudoers
}

nojailed_nox_sudo__lock_sudoers() {
	# This function will lock the sudoers file so that it cannot be edited.

	chmod 0440 /usr/local/etc/sudoers
	chflags schg,opaque /usr/local/etc/sudoers

	rm -f /usr/local/bin/sudoedit
		# This is a suid/sgid binary, so it should be removed if it is no longer
		# needed.
}
