#!/bin/sh

# This script will install pidgin and pidgin-otr in a jail, and sets up telnet
# and a default desktop file. If user is not specified, it defaults to pidgin.
# The default desktop file may be overwritten with
# jail_maint_utils__setup_program_desktop. The Pidgin home page:
# http://www.pidgin.im/ and the OTR home page: http://www.cypherpunks.ca/otr/

# Arguments:
  jail_name="$arg_1"
  user="${arg_2:-pidgin}"
  unset arg_1 arg_2

# Requires:	lib/misc_utils.sh
#		lib/jail_maint_utils.sh
#		lib/ports_pkgs_utils.sh
#		lib/user_maint_utils.sh

# Variable defaults:
  : ${jailed_x_pidgin__apps_folder='/usr/shew/install/shewstring/libexec/jailed_x/apps'}
								# The default jailed_x apps folder.
  : ${jailed_x_pidgin__pidgin_configs='/usr/shew/install/shewstring/libexec/jailed_x/misc/pidgin'}
								# This file is the default pidgin folder for config files.

# Execute:

if [ -f /usr/shew/install/done/"$jail_name"/"$user"/jailed_x_pidgin ]; then
	echo "jailed_x/pidgin.sh was called on $jail_name with user $user but it has
already been run, skipping."
	return 0
fi

if [ ! -d /usr/shew/jails/"$jail_name" ]; then
	echo "jailed_x/pidgin.sh was called on $jail_name but that jail does not exist."
	return 1
fi

if [ ! -d "$jailed_x_pidgin__apps_folder" ]; then
	echo "jailed_x/pidgin.sh could not find a critical install file. It should be:
	$jailed_x_pidgin__apps_folder"
	return 1
fi

if [ ! -d "$jailed_x_pidgin__pidgin_configs" ]; then
	echo "jailed_x/pidgin.sh could not find a critical install file. It should be:
	$jailed_x_pidgin__pidgin_configs"
	return 1
fi

ports_pkgs_utils__configure_port pidgin "$jailed_x_pidgin__apps_folder"
ports_pkgs_utils__install_pkg pidgin /usr/shew/jails/"$jail_name"
ports_pkgs_utils__configure_port pidgin-otr "$jailed_x_pidgin__apps_folder"
ports_pkgs_utils__install_pkg pidgin-otr /usr/shew/jails/"$jail_name"

password="`
		dd if=/dev/random count=2 \
			| md5
	`"

user_maint_utils__add_jail_user "$jail_name" "$user" "$password" home sensitive sound

cp -f "$jailed_x_pidgin__pidgin_configs"/prefs.xml /usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/prefs.xml
chroot /usr/shew/jails/"$jail_name" \
	chown "${user}:$user" /usr/shew/sensitive/"$user"/prefs.xml
chflags schg /usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/prefs.xml

ln -s /usr/shew/sensitive/"$user" /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.purple
chmod -h 0444 /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.purple
chflags -h schg /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.purple
	# Pidgin does not follow symbolic links properly.

chflags noschg /usr/shew/sensitive/"$jail_name"/"${user}.allow"
echo 'certificates
certificates/.*
accounts\.xml
blist\.xml
pounces\.xml
prefs\.xml
otr\.fingerprints
otr\.private_key' \
	>> /usr/shew/sensitive/"$jail_name"/"${user}.allow"
chflags schg /usr/shew/sensitive/"$jail_name"/"${user}.allow"

jail_maint_utils__setup_program_telnet "$jail_name" "$user" "$password"
jail_maint_utils__setup_program_desktop "$jail_name" "$user" \
	/usr/shew/jails/"$jail_name"/usr/local/share/icons/hicolor/48x48/apps/pidgin.png \
	/usr/local/bin/pidgin

if [ ! -d /usr/shew/install/done/"$jail_name"/"$user" ]; then
	mkdir -p /usr/shew/install/done/"$jail_name"/"$user"
	chmod 0700 /usr/shew/install/done/"$jail_name"/"$user"
fi

touch /usr/shew/install/done/"$jail_name"/"$user"/jailed_x_pidgin
