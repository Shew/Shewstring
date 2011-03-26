#!/bin/sh

# This script will install Galculator. The Galculator home page:
# http://galculator.sourceforge.net/

# Requires:	lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${nojailed_x_galculator__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.
  : ${nojailed_x_galculator__home_folder='/usr/shew/install/shewstring/libexec/nojailed_x/home/galculator'}
								# The default galculator home folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_galculator ]; then
	echo "nojailed_x/galculator.sh was called but it has already been run, skipping."
	return 0
fi

if [ ! -d "$nojailed_x_galculator__apps_folder" ]; then
	echo "nojailed_x/galculator.sh could not find a critical install file. It should be:
	$nojailed_x_galculator__apps_folder"
	return 1
fi

if [ ! -d "$nojailed_x_galculator__home_folder" ]; then
	echo "nojailed_x/galculator.sh could not find a critical install file. It should be:
	$nojailed_x_galculator__home_folder"
	return 1
fi

ports_pkgs_utils__configure_port galculator "$nojailed_x_galculator__apps_folder"
ports_pkgs_utils__install_pkg galculator

cp -Rf "$nojailed_x_galculator__home_folder" /tmp/galculator
chown -R guest:guest /tmp/galculator
cp -af /tmp/galculator/ /usr/shew/copy_to_mfs/home/guest
rm -Rf /tmp/galculator

echo '[Desktop Entry]
Name=Galculator
Icon=galculator
Exec=galculator
Terminal=false
Type=Application
Categories=shew-applications
' > /usr/local/share/applications/galculator.desktop

if [ ! -d /usr/shew/install/done ]; then
	mkdir -p /usr/shew/install/done
	chmod 0700 /usr/shew/install/done
fi

touch /usr/shew/install/done/nojailed_x_galculator
