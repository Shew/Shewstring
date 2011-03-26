#!/bin/sh

# This script will install gnupg in a jail. This does not install gpa by
# default, but gnupg__install_gpa can be run to do so. The GnuPG home page:
# http://www.gnupg.org/ and the GPA home page
# http://wald.intevation.org/projects/gpa/

# Arguments:
  jail_name="$arg_1"
  unset arg_1

# Requires:	lib/misc_utils.sh
#		lib/jail_maint_utils.sh
#		lib/ports_pkgs_utils.sh
#		lib/user_maint_utils.sh

# Contents:	gnupg__install_gpa

# Variable defaults:
  : ${jailed_x_gnupg__apps_folder='/usr/shew/install/shewstring/libexec/jailed_x/apps'}
								# The default jailed_x apps folder.
  : ${jailed_x_gpa__gpa_configs='/usr/shew/install/shewstring/libexec/jailed_x/misc/gpa'}
								# This file is the default gpa folder for config files.

# Execute:

if [ -f /usr/shew/install/done/"$jail_name"/jailed_x_gnupg ]; then
	echo "jailed_x/gnupg.sh was called on $jail_name but it has already been
run, skipping."
		# Normally this would return 0, but then you wouldn't be able to load functions
		# if the script has already been run.
else

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "jailed_x/gnupg.sh was called on $jail_name but that jail does not exist."
		return 1
	fi

	if [ ! -d "$jailed_x_gnupg__apps_folder" ]; then
		echo "jailed_x/gnupg.sh could not find a critical install file. It should be:
	$jailed_x_gnupg__apps_folder"
		return 1
	fi

	ports_pkgs_utils__configure_port gnupg "$jailed_x_gnupg__apps_folder"
	ports_pkgs_utils__install_pkg gnupg /usr/shew/jails/"$jail_name"
	ports_pkgs_utils__configure_port pinentry "$jailed_x_gnupg__apps_folder"
	ports_pkgs_utils__install_pkg pinentry /usr/shew/jails/"$jail_name"

	if [ ! -d /usr/shew/install/done/"$jail_name" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"
		chmod 0700 /usr/shew/install/done/"$jail_name"
	fi

	touch /usr/shew/install/done/"$jail_name"/jailed_x_gnupg
fi

# Functions:

gnupg__install_gpa() {
	# This function will install gpa. NOTE: if a program wants to use the same
	# gnupg files as another program, it must be running as the same user. This is
	# because gnupg will "fix" the permissions of its configuration files each time
	# it is run. To install gpa as the same user as another program, just specify
	# the same user via the second argument. Some functions called may complain if
	# other programs have configured something already, but it should complete
	# without an error. It would be nice if someone would fix gnupg so it doesn't
	# do this.

	jail_name="$1"
	user="${2:-gpa}"

	if [ -f /usr/shew/install/done/"$jail_name"/"$user"/gnupg__install_gpa ]; then
		echo "gnupg__install_gpa was called on $jail_name with user $user but it has
already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "gnupg__install_gpa was called on $jail_name but that jail does not
exist."
		return 1
	fi

	if [ ! -d "$jailed_x_gnupg__apps_folder" ]; then
		echo "gnupg__install_gpa could not find a critical install file. It should be:
	$jailed_x_gnupg__apps_folder"
		return 1
	fi

	if [ ! -d "$jailed_x_gpa__gpa_configs" ]; then
		echo "gnupg__install_gpa could not find a critical install file. It should be:
	$jailed_x_gpa__gpa_configs"
		return 1
	fi

	ports_pkgs_utils__configure_port gpa "$jailed_x_gnupg__apps_folder"
	ports_pkgs_utils__install_pkg gpa /usr/shew/jails/"$jail_name"

	password="`
			dd if=/dev/random count=2 \
				| md5
		`"

	user_maint_utils__add_jail_user "$jail_name" "$user" "$password" home sensitive

	mkdir -p /usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/gnupg
	cp -f "$jailed_x_gpa__gpa_configs"/gpg.conf /usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/gnupg/gpg.conf
	touch /usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/gnupg/pubring.kbx
		# For some reason, entries for certificate authorities show up in GPA if this
		# is not touched.
	chroot /usr/shew/jails/"$jail_name" \
		chown -R "${user}:$user" /usr/shew/sensitive/"$user"/gnupg
	chflags schg /usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/gnupg/gpg.conf

	ln -s /usr/shew/sensitive/"$user"/gnupg /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.gnupg
	chmod -h 0444 /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.gnupg
	chflags -h schg /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.gnupg

	chflags noschg /usr/shew/sensitive/"$jail_name"/"${user}.allow"
	echo 'gnupg
gnupg/gpg.conf
gnupg/pubring\.gpg
gnupg/pubring\.kbx
gnupg/random_seed
gnupg/secring\.gpg
gnupg/trustdb\.gpg' \
		>> /usr/shew/sensitive/"$jail_name"/"${user}.allow"
	chflags schg /usr/shew/sensitive/"$jail_name"/"${user}.allow"

	jail_maint_utils__setup_program_telnet "$jail_name" "$user" "$password"
	jail_maint_utils__setup_program_desktop "$jail_name" "$user" \
		/usr/shew/jails/"$jail_name"/usr/local/share/gpa/gpa.png \
		/usr/local/bin/gpa

	if [ ! -d /usr/shew/install/done/"$jail_name"/"$user" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"/"$user"
		chmod 0700 /usr/shew/install/done/"$jail_name"/"$user"
	fi

	touch /usr/shew/install/done/"$jail_name"/"$user"/gnupg__install_gpa
}
