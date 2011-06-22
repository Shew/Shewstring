#!/bin/sh

# This script will install liferea in a jail, and sets up telnet and a default
# desktop file. If user is not specified, it defaults to liferea. The default
# desktop file may be overwritten with jail_maint_utils__setup_program_desktop.
# The Liferea home page: http://liferea.sourceforge.net/

# Arguments:
  jail_name="$arg_1"
  user="${arg_2:-liferea}"
  unset arg_1 arg_2

# Requires:	lib/misc_utils.sh
#		lib/jail_maint_utils.sh
#		lib/ports_pkgs_utils.sh
#		lib/user_maint_utils.sh

# Variable defaults:
  : ${jailed_x_liferea__apps_folder='/usr/shew/install/shewstring/libexec/jailed_x/apps'}
								# The default jailed_x apps folder.
  : ${jailed_x_liferea__home_folder='/usr/shew/install/shewstring/libexec/jailed_x/home/liferea'}
								# The default liferea home folder.
  : ${jailed_x_liferea__liferea_configs='/usr/shew/install/shewstring/libexec/jailed_x/misc/liferea'}
								# This file is the default liferea folder for config files.

# Execute:

if [ -f /usr/shew/install/done/"$jail_name"/"$user"/jailed_x_liferea ]; then
	echo "jailed_x/liferea.sh was called on $jail_name with user $user but it has
already been run, skipping."
	return 0
fi

if [ ! -d /usr/shew/jails/"$jail_name" ]; then
	echo "jailed_x/liferea.sh was called on $jail_name but that jail does not exist."
	return 1
fi

if [ ! -d "$jailed_x_liferea__apps_folder" ]; then
	echo "jailed_x/liferea.sh could not find a critical install file. It should be:
	$jailed_x_liferea__apps_folder"
	return 1
fi

if [ ! -d "$jailed_x_liferea__home_folder" ]; then
	echo "jailed_x/liferea.sh could not find a critical install file. It should be:
	$jailed_x_liferea__home_folder"
	return 1
fi

if [ ! -d "$jailed_x_liferea__liferea_configs" ]; then
	echo "jailed_x/liferea.sh could not find a critical install file. It should be:
	$jailed_x_liferea__liferea_configs"
	return 1
fi

ports_pkgs_utils__configure_port liferea "$jailed_x_liferea__apps_folder"
ports_pkgs_utils__install_pkg liferea /usr/shew/jails/"$jail_name"

mv /usr/shew/jails/"$jail_name"/usr/local/bin/liferea /usr/shew/jails/"$jail_name"/usr/local/bin/liferea-bin
echo '#!/bin/sh

eval `dbus-launch --sh-syntax`

/usr/local/bin/liferea-bin $@

kill "$DBUS_SESSION_BUS_PID"
' > /usr/shew/jails/"$jail_name"/usr/local/bin/liferea
chmod 0555 /usr/shew/jails/"$jail_name"/usr/local/bin/liferea
	# Liferea fails without launching dbus first.

password="`
		dd if=/dev/random count=2 \
			| md5
	`"

user_maint_utils__add_jail_user "$jail_name" "$user" "$password" home sensitive

cp -Rf "$jailed_x_liferea__home_folder" /usr/shew/jails/"$jail_name"/tmp/liferea
chroot /usr/shew/jails/"$jail_name" \
	chown -R "${user}:$user" /tmp/liferea
cp -af /usr/shew/jails/"$jail_name"/tmp/liferea/ /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"
rm -Rf /usr/shew/jails/"$jail_name"/tmp/liferea

cp -f \
	"$jailed_x_liferea__liferea_configs"/feedlist.opml \
	/usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"
chroot /usr/shew/jails/"$jail_name" \
	chown "${user}:$user" \
		/usr/shew/sensitive/"$user"/feedlist.opml

ln -s /usr/shew/sensitive/"$user" /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.liferea_1.6
chmod -h 0444 /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.liferea_1.6
chflags -h schg /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.liferea_1.6

chflags noschg /usr/shew/sensitive/"$jail_name"/"${user}.allow"
echo 'cache
cache/favicons
cache/favicons/[a-z]*\.png
feedlist\.opml
feedlist\.opml\.backup' \
	>> /usr/shew/sensitive/"$jail_name"/"${user}.allow"
chflags schg /usr/shew/sensitive/"$jail_name"/"${user}.allow"

jail_maint_utils__setup_program_telnet "$jail_name" "$user" "$password"
jail_maint_utils__setup_program_desktop "$jail_name" "$user" \
	/usr/shew/jails/"$jail_name"/usr/local/share/icons/hicolor/48x48/apps/liferea.png \
	/usr/local/bin/liferea

if [ ! -d /usr/shew/install/done/"$jail_name"/"$user" ]; then
	mkdir -p /usr/shew/install/done/"$jail_name"/"$user"
	chmod 0700 /usr/shew/install/done/"$jail_name"/"$user"
fi

touch /usr/shew/install/done/"$jail_name"/"$user"/jailed_x_liferea
