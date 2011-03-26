#!/bin/sh

# This script will install Terminal in a jail, and sets up telnet and a default
# desktop file. If user is not specified, it defaults to terminal. The default
# desktop file may be overwritten with jail_maint_utils__setup_program_desktop.
# The XOrg home page: http://www.x.org/wiki/Home

# Arguments:
  jail_name="$arg_1"
  user="${arg_2:-terminal}"
  unset arg_1 arg_2

# Requires:	lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${jailed_x_terminal__apps_folder='/usr/shew/install/shewstring/libexec/jailed_x/apps'}
								# The default jailed_x apps folder.

# Execute:

if [ -f /usr/shew/install/done/"$jail_name"/"$user"/jailed_x_terminal ]; then
	echo "jailed_x/terminal.sh was called on $jail_name with user $user but it has
already been run, skipping."
	return 0
fi

if [ ! -d /usr/shew/jails/"$jail_name" ]; then
	echo "jailed_x/terminal.sh was called on $jail_name but that jail does not exist."
	return 1
fi

if [ ! -d "$jailed_x_terminal__apps_folder" ]; then
	echo "jailed_x/terminal.sh could not find a critical install file. It should be:
	$jailed_x_terminal__apps_folder"
	return 1
fi

ports_pkgs_utils__configure_port Terminal "$jailed_x_terminal__apps_folder"
ports_pkgs_utils__install_pkg Terminal /usr/shew/jails/"$jail_name"

password="`
		dd if=/dev/random count=2 \
			| md5
	`"

user_maint_utils__add_jail_user "$jail_name" "$user" "$password" data home

jail_maint_utils__setup_program_telnet "$jail_name" "$user" "$password"
jail_maint_utils__setup_program_desktop "$jail_name" "$user" Terminal '/usr/local/bin/Terminal -x /bin/csh -l'

if [ ! -d /usr/shew/install/done/"$jail_name"/"$user" ]; then
	mkdir -p /usr/shew/install/done/"$jail_name"/"$user"
	chmod 0700 /usr/shew/install/done/"$jail_name"/"$user"
fi

touch /usr/shew/install/done/"$jail_name"/"$user"/jailed_x_terminal
