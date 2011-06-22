#!/bin/sh

# This script will install TkDVD and modify the devfs to allow its user to
# write to the disk drives. The TkDVD home page:
# https://savannah.nongnu.org/projects/tkdvd/

# Arguments:
  password="$arg_1"
  unset arg_1

# Requires:	lib/misc_utils.sh
#		lib/user_maint_utils.sh
#		lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${nojailed_x_tkdvd__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_tkdvd ]; then
	echo "nojailed_x/tkdvd.sh was called but it has already been run, skipping."
	return 0
fi

if [ ! -d "$nojailed_x_tkdvd__apps_folder" ]; then
	echo "nojailed_x/tkdvd.sh could not find a critical install file. It should be:
	$nojailed_x_tkdvd__apps_folder"
	return 1
fi

ports_pkgs_utils__configure_port tkdvd "$nojailed_x_tkdvd__apps_folder"
ports_pkgs_utils__install_pkg tkdvd

uid="`user_maint_utils__generate_unique_uid`"
echo "$password" \
	| pw useradd -d /home/guest -n disk_burner -u "$uid" -g guest -h 0
# Adding this to the guest group will allow it to access guest's folders.

mkdir -p /usr/shew/copy_to_mfs/home/guest/.tkdvd
chown disk_burner:guest /usr/shew/copy_to_mfs/home/guest/.tkdvd
	# TkDVD does not like not being able to write to its folder in its home location.

misc_utils__add_clause /etc/devfs.rules '\[devfsrules_system=5\]' \
	"# Added by nojailed_x/tkdvd.sh for tkdvd:\\
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
Name=TkDVD
Icon=drive-cdrom
Exec=xterm -e \"echo 'Please enter the guest password.'; su disk_burner -c tkdvd\"
Terminal=false
Type=Application
Categories=elevated
" > /usr/local/share/applications/tkdvd.desktop
	chmod 0444 /usr/local/share/applications/tkdvd.desktop

if [ ! -d /usr/shew/install/done ]; then
	mkdir -p /usr/shew/install/done
	chmod 0700 /usr/shew/install/done
fi

touch /usr/shew/install/done/nojailed_x_tkdvd
