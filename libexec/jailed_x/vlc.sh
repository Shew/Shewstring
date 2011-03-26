#!/bin/sh

# This script will install vlc in a jail. This does not install user and
# desktop files since it is usually launched from another program (e.g. from
# Firefox). The VLC home page: http://www.videolan.org/

# Arguments:
  jail_name="$arg_1"
  unset arg_1

# Requires:	lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${jailed_x_vlc__apps_folder='/usr/shew/install/shewstring/libexec/jailed_x/apps'}
								# The default jailed_x apps folder.

# Execute:

if [ -f /usr/shew/install/done/"$jail_name"/jailed_x_vlc ]; then
	echo "jailed_x/vlc.sh was called on $jail_name but it has already been run,
skipping."
	return 0
fi

if [ ! -d /usr/shew/jails/"$jail_name" ]; then
	echo "jailed_x/vlc.sh was called on $jail_name but that jail does not exist."
	return 1
fi

if [ ! -d "$jailed_x_vlc__apps_folder" ]; then
	echo "jailed_x/vlc.sh could not find a critical install file. It should be:
	$jailed_x_vlc__apps_folder"
	return 1
fi

ports_pkgs_utils__configure_port vlc "$jailed_x_vlc__apps_folder"
ports_pkgs_utils__install_pkg vlc /usr/shew/jails/"$jail_name"

if [ ! -d /usr/shew/install/done/"$jail_name" ]; then
	mkdir -p /usr/shew/install/done/"$jail_name"
	chmod 0700 /usr/shew/install/done/"$jail_name"
fi

touch /usr/shew/install/done/"$jail_name"/jailed_x_vlc
