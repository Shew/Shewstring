#!/bin/sh

# This script will install Abiword. The Abiword home page:
# http://abisource.com/

# Requires:	lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${nojailed_x_abiword__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_abiword ]; then
	echo "nojailed_x/abiword.sh was called but it has already been run, skipping."
	return 0
fi

if [ ! -d "$nojailed_x_abiword__apps_folder" ]; then
	echo "nojailed_x/abiword.sh could not find a critical install file. It should be:
	$nojailed_x_abiword__apps_folder"
	return 1
fi

ports_pkgs_utils__configure_port abiword "$nojailed_x_abiword__apps_folder"
ports_pkgs_utils__install_pkg abiword

echo '[Desktop Entry]
Name=Abiword
Icon=abiword_48
Exec=abiword
Terminal=false
Type=Application
Categories=shew-applications
MimeType=application/x-abiword;text/x-abiword;text/x-xml-abiword;application/msword;application/rtf;application/vnd.plain;application/x-crossmark;application/docbook+xml;application/x-t602;application/vnd.oasis.opendocument.text;application/vnd.sun.xml.writer;application/vnd.stardivision.writer;text/vnd.wap.wml;application/wordperfect6;application/wordperfect5.1;application/vnd.wordperfect;application/x-abicollab;
' > /usr/local/share/applications/abiword.desktop

if [ ! -d /usr/shew/install/done ]; then
	mkdir -p /usr/shew/install/done
	chmod 0700 /usr/shew/install/done
fi

touch /usr/shew/install/done/nojailed_x_abiword
