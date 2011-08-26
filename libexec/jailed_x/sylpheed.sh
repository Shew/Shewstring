#!/bin/sh

# This script will install sylpheed3 in a jail, and sets up telnet and a
# default desktop file. If user is not specified, it defaults to sylpheed. The
# default desktop file may be overwritten with
# jail_maint_utils__setup_program_desktop. This script will also install gpa if
# jailed_x_sylpheed__install_gpa is set to YES (which it is by default). This
# is installed as the same user as sylpheed, but it should really be installed
# as a separate user by a separate script (i.e. gnupg.sh), and sylpheed given
# access by putting it in the group 'gnupg'. However, gnupg does not allow this
# as it 'fixes' the permissions to its configuration files every time it is
# run. It would be nice if someone would fix gnupg so it doesn't do this. The
# Sylpheed home page: http://sylpheed.sraoss.jp/en/

# Arguments:
  jail_name="$arg_1"
  user="${arg_2:-sylpheed}"
  unset arg_1 arg_2

# Requires:	lib/misc_utils.sh
#		lib/jail_maint_utils.sh
#		lib/ports_pkgs_utils.sh
#		lib/user_maint_utils.sh

# Variable defaults:
  : ${jailed_x_sylpheed__apps_folder='/usr/shew/install/shewstring/libexec/jailed_x/apps'}
								# The default jailed_x apps folder.
  : ${jailed_x_sylpheed__sylpheed_configs='/usr/shew/install/shewstring/libexec/jailed_x/misc/sylpheed'}
								# This file is the default sylpheed folder for config files.
  : ${jailed_x_sylpheed__install_gpa='YES'}			# Install gpa with sylpheed.

# Execute:

if [ -f /usr/shew/install/done/"$jail_name"/"$user"/jailed_x_sylpheed ]; then
	echo "jailed_x/sylpheed.sh was called on $jail_name with user $user but it has
already been run, skipping."
	return 0
fi

if [ ! -d /usr/shew/jails/"$jail_name" ]; then
	echo "jailed_x/sylpheed.sh was called on $jail_name but that jail does not exist."
	return 1
fi

if [ ! -d "$jailed_x_sylpheed__apps_folder" ]; then
	echo "jailed_x/sylpheed.sh could not find a critical install file. It should be:
	$jailed_x_sylpheed__apps_folder"
	return 1
fi

if [ ! -d "$jailed_x_sylpheed__sylpheed_configs" ]; then
	echo "jailed_x/sylpheed.sh could not find a critical install file. It should be:
	$jailed_x_sylpheed__sylpheed_configs"
	return 1
fi

cp -f "$jailed_x_sylpheed__sylpheed_configs"/patch-headers /usr/shew/jails/compile/usr/ports/mail/sylpheed/files

ports_pkgs_utils__configure_port sylpheed "$jailed_x_sylpheed__apps_folder"
ports_pkgs_utils__install_pkg sylpheed /usr/shew/jails/"$jail_name"

password="`
		dd if=/dev/random count=2 \
			| md5
	`"

user_maint_utils__add_jail_user "$jail_name" "$user" "$password" home sensitive gpa

chflags noschg /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.profile
echo '
# Added by jailed_x/sylpheed.sh for sylpheed:
export G_FILENAME_ENCODING="UTF-8"
' >> /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.profile
	# Sylpheed complains and prompts the user if this is not set.
chflags schg /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.profile

ln -s /home/gpa/.gnupg /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.gnupg
chmod -h 0444 /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.gnupg
chflags -h schg /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.gnupg

mkdir -p \
	/usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/mail/draft \
	/usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/mail/inbox \
	/usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/mail/junk \
	/usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/mail/queue \
	/usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/mail/outbox \
	/usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/mail/trash \
	/usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/sylpheed
cp -f \
	"$jailed_x_sylpheed__sylpheed_configs"/actionsrc \
	"$jailed_x_sylpheed__sylpheed_configs"/folderlist.xml \
	"$jailed_x_sylpheed__sylpheed_configs"/sylpheedrc \
	/usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/sylpheed
chroot /usr/shew/jails/"$jail_name" \
	chown -R "${user}:$user" \
		/usr/shew/sensitive/"$user"/mail \
		/usr/shew/sensitive/"$user"/sylpheed
chflags schg \
	/usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/sylpheed/actionsrc \
	/usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/sylpheed/sylpheedrc

ln -s /usr/shew/sensitive/"$user"/sylpheed /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.sylpheed-2.0
ln -s /usr/shew/sensitive/"$user"/mail /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/Mail
chmod -h 0444 \
	/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/Mail \
	/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.sylpheed-2.0
chflags -h schg \
	/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/Mail \
	/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.sylpheed-2.0

chflags noschg /usr/shew/sensitive/"$jail_name"/"${user}.allow"
echo 'mail
mail/.*
sylpheed
sylpheed/accountrc
sylpheed/accountrc\.bak
sylpheed/actionsrc
sylpheed/addrbook--index\.xml
sylpheed/addrbook--index\.xml\.bak
sylpheed/addrbook-00000[1-3]\.xml
sylpheed/filter\.xml
sylpheed/folderlist\.xml
sylpheed/folderlist\.xml\.bak
sylpheed/imapcache
sylpheed/imapcache/.*
sylpheed/newscache
sylpheed/newscache/.*
sylpheed/sylpheedrc
sylpheed/trust\.crt' \
	>> /usr/shew/sensitive/"$jail_name"/"${user}.allow"
chflags schg /usr/shew/sensitive/"$jail_name"/"${user}.allow"

jail_maint_utils__setup_program_telnet "$jail_name" "$user" "$password"
jail_maint_utils__setup_program_desktop "$jail_name" "$user" \
	/usr/shew/jails/"$jail_name"/usr/local/share/pixmaps/sylpheed.png \
	/usr/local/bin/sylpheed

if [ ! -d /usr/shew/install/done/"$jail_name"/"$user" ]; then
	mkdir -p /usr/shew/install/done/"$jail_name"/"$user"
	chmod 0700 /usr/shew/install/done/"$jail_name"/"$user"
fi

touch /usr/shew/install/done/"$jail_name"/"$user"/jailed_x_sylpheed
