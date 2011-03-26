#!/bin/sh

# This script will install Evince. The Evince home page:
# http://projects.gnome.org/evince/

# Requires:	lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${nojailed_x_evince__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_evince ]; then
	echo "nojailed_x/evince.sh was called but it has already been run, skipping."
	return 0
fi

if [ ! -d "$nojailed_x_evince__apps_folder" ]; then
	echo "nojailed_x/evince.sh could not find a critical install file. It should be:
	$nojailed_x_evince__apps_folder"
	return 1
fi

ports_pkgs_utils__configure_port evince "$nojailed_x_evince__apps_folder"
ports_pkgs_utils__install_pkg evince

echo '[Desktop Entry]
Name=Evince
Icon=evince
Exec=evince
Terminal=false
Type=Application
Categories=shew-applications
MimeType=application/pdf;application/x-bzpdf;application/x-gzpdf;application/postscript;application/x-bzpostscript;application/x-gzpostscript;image/x-eps;image/x-bzeps;image/x-gzeps;application/x-cbr;application/x-cbz;application/x-cb7;
' > /usr/local/share/applications/evince.desktop

if [ ! -d /usr/shew/install/done ]; then
	mkdir -p /usr/shew/install/done
	chmod 0700 /usr/shew/install/done
fi

touch /usr/shew/install/done/nojailed_x_evince
