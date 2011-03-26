#!/bin/sh

# This script will install Xfburn and modify the devfs to allow its user to
# write to the disk drives. The Xfburn home page:
# http://goodies.xfce.org/projects/applications/xfburn

# Arguments:
  password="$arg_1"
  unset arg_1

# Requires:	lib/misc_utils.sh
#		lib/user_maint_utils.sh
#		lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${nojailed_x_xfburn__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.
  : ${nojailed_x_xfburn__home_folder='/usr/shew/install/shewstring/libexec/nojailed_x/home/xfburn'}
								# The default xfburn home folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_xfburn ]; then
	echo "nojailed_x/xfburn.sh was called but it has already been run, skipping."
	return 0
fi

if [ ! -d "$nojailed_x_xfburn__apps_folder" ]; then
	echo "nojailed_x/xfburn.sh could not find a critical install file. It should be:
	$nojailed_x_xfburn__apps_folder"
	return 1
fi

if [ ! -d "$nojailed_x_xfburn__home_folder" ]; then
	echo "nojailed_x/xfburn.sh could not find a critical install file. It should be:
	$nojailed_x_xfburn__home_folder"
	return 1
fi

ports_pkgs_utils__configure_port xfburn "$nojailed_x_xfburn__apps_folder"
ports_pkgs_utils__install_pkg xfburn

uid="`user_maint_utils__generate_unique_uid`"
echo "$password" \
	| pw useradd -d /home/guest -n disk_burner -u "$uid" -g guest -h 0
# Adding this to the guest group will allow it to access guest's folders.

cp -Rf "$nojailed_x_xfburn__home_folder" /tmp/xfburn
chown -R disk_burner:guest /tmp/xfburn
chmod -R 0770 /tmp/xfburn
cp -af /tmp/xfburn/ /usr/shew/copy_to_mfs/home/guest
rm -Rf /tmp/xfburn

misc_utils__add_clause /etc/devfs.rules '\[devfsrules_system=5\]' \
	"# Added by nojailed_x/xfburn.sh for xfburn:\\
	add path 'cd*' unhide mode 0600 user disk_burner\\
	add path 'pass*' unhide mode 0600 user disk_burner\\
	add path 'xpt*' unhide mode 0600 user disk_burner"

if [ ! -f /usr/local/share/desktop-directories/elevated.directory ]; then
	mkdir -p /usr/local/share/desktop-directories
	echo '[Desktop Entry]
Name=Elevated
Icon=folder
' > /usr/local/share/desktop-directories/elevated.directory
	chmod 0444 /usr/local/share/desktop-directories/elevated.directory
fi

if [ ! -d /usr/local/share/applications ]; then
	mkdir -p /usr/local/share/applications
fi

echo "[Desktop Entry]
Name=XFBurn
Icon=drive-cdrom
Exec=xterm -e \"echo 'Please enter the guest password.'; su disk_burner -c xfburn\"
Terminal=false
Type=Application
Categories=elevated
" > /usr/local/share/applications/xfburn.desktop
	chmod 0444 /usr/local/share/applications/xfburn.desktop

if [ ! -d /usr/shew/install/done ]; then
	mkdir -p /usr/shew/install/done
	chmod 0700 /usr/shew/install/done
fi

touch /usr/shew/install/done/nojailed_x_xfburn
