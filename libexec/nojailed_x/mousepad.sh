#!/bin/sh

# This script will install Mousepad. The Mousepad home page:
# http://www.xfce.org/projects/mousepad/

# Requires:	lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${nojailed_x_mousepad__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_mousepad ]; then
	echo "nojailed_x/mousepad.sh was called but it has already been run, skipping."
	return 0
fi

if [ ! -d "$nojailed_x_mousepad__apps_folder" ]; then
	echo "nojailed_x/mousepad.sh could not find a critical install file. It should be:
	$nojailed_x_mousepad__apps_folder"
	return 1
fi

ports_pkgs_utils__configure_port mousepad "$nojailed_x_mousepad__apps_folder"
ports_pkgs_utils__install_pkg mousepad

echo '[Desktop Entry]
Name=Mousepad
Icon=mousepad
Exec=mousepad
Terminal=false
Type=Application
Categories=shew-applications
MimeType=text/plain;application/xhtml+xml;text/html;
' > /usr/local/share/applications/mousepad.desktop

if [ ! -d /usr/shew/install/done ]; then
	mkdir -p /usr/shew/install/done
	chmod 0700 /usr/shew/install/done
fi

touch /usr/shew/install/done/nojailed_x_mousepad
