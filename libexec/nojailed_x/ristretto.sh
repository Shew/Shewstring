#!/bin/sh

# This script will install Ristretto. The Ristretto home page:
# http://goodies.xfce.org/projects/applications/ristretto

# Requires:	lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${nojailed_x_ristretto__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_ristretto ]; then
	echo "nojailed_x/ristretto.sh was called but it has already been run, skipping."
	return 0
fi

if [ ! -d "$nojailed_x_ristretto__apps_folder" ]; then
	echo "nojailed_x/ristretto.sh could not find a critical install file. It should be:
	$nojailed_x_ristretto__apps_folder"
	return 1
fi

ports_pkgs_utils__configure_port ristretto "$nojailed_x_ristretto__apps_folder"
ports_pkgs_utils__install_pkg ristretto

echo '[Desktop Entry]
Name=Ristretto
Icon=ristretto
Exec=ristretto
Terminal=false
Type=Application
Categories=shew-applications
MimeType=image/png;image/gif;image/jpeg;image/bmp;image/x-ico;image/x-pixmap;image/tiff;image/x-portable-bitmap;image/x-portable-greymap;image/x-portable-pixmap;
' > /usr/local/share/applications/ristretto.desktop

if [ ! -d /usr/shew/install/done ]; then
	mkdir -p /usr/shew/install/done
	chmod 0700 /usr/shew/install/done
fi

touch /usr/shew/install/done/nojailed_x_ristretto
