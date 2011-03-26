#!/bin/sh

# This script will install SANE Backends and SANE Frontends and modify the
# devfs to allow its user to read and write to the scanner. The SANE home page:
# http://www.sane-project.org/

# Arguments:
  password="$arg_1"
  unset arg_1

# Requires:	lib/misc_utils.sh
#		lib/user_maint_utils.sh
#		lib/ports_pkgs_utils.sh

# Contents:	nojailed_x_sane__install_netpbm

# Variable defaults:
  : ${nojailed_x_sane__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.
  : ${nojailed_x_sane__home_folder='/usr/shew/install/shewstring/libexec/nojailed_x/home/sane'}
								# The default sane home folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_sane ]; then
	echo "nojailed_x/sane.sh was called but it has already been run, skipping."
		# Normally this would return 0, but then you wouldn't be able to load functions
		# if the script has already been run.
else

	if [ ! -d "$nojailed_x_sane__apps_folder" ]; then
		echo "nojailed_x/sane.sh could not find a critical install file. It should be:
	$nojailed_x_sane__apps_folder"
		return 1
	fi

	if [ ! -d "$nojailed_x_sane__home_folder" ]; then
		echo "nojailed_x/sane.sh could not find a critical install file. It should be:
	$nojailed_x_sane__home_folder"
		return 1
	fi

	ports_pkgs_utils__configure_port sane-backends "$nojailed_x_sane__apps_folder"
	ports_pkgs_utils__install_pkg sane-backends
	ports_pkgs_utils__configure_port sane-frontends "$nojailed_x_sane__apps_folder"
	ports_pkgs_utils__install_pkg sane-frontends

	uid="`user_maint_utils__generate_unique_uid`"
	echo "$password" \
		| pw useradd -d /home/guest -n scanner -u "$uid" -g guest -h 0
	# Adding this to the guest group will allow it to access guest's folders.

	cp -Rf "$nojailed_x_sane__home_folder" /tmp/sane
	chown -R scanner:guest /tmp/sane
	chmod -R 0770 /tmp/sane
	cp -af /tmp/sane/ /usr/shew/copy_to_mfs/home/guest
	rm -Rf /tmp/sane

	misc_utils__add_clause /etc/devfs.rules '\[devfsrules_system=5\]' \
		"# Added by nojailed_x/sane.sh for sane:\\
		add path 'usb*' unhide mode 0755 user scanner\\
		add path 'uscanner*' unhide mode 0755 user scanner\\
		add path 'ugen*' unhide mode 0755 user scanner"

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
Name=XScanImage
Icon=scanner
Exec=xterm -e \"echo 'Please enter the guest password.'; su scanner -c xscanimage\"
Terminal=false
Type=Application
Categories=elevated
" > /usr/local/share/applications/sane.desktop
		chmod 0444 /usr/local/share/applications/sane.desktop

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/nojailed_x_sane
fi

# Functions:

nojailed_x_sane__install_netpbm() {
	# This function will install netpbm.

	ports_pkgs_utils__configure_port netpbm "$nojailed_x_sane__apps_folder"
	ports_pkgs_utils__install_pkg netpbm
}
