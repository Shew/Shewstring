#!/bin/sh

# This script will install the Xfce Terminal. The Terminal home page:
# http://www.os-cillation.de/en/open-source-projekte/xfce-terminal/

# Requires:	lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${nojailed_x_terminal__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_terminal ]; then
	echo "nojailed_x/terminal.sh was called but it has already been run, skipping."
	return 0
fi

if [ ! -d "$nojailed_x_terminal__apps_folder" ]; then
	echo "nojailed_x/terminal.sh could not find a critical install file. It should be:
	$nojailed_x_terminal__apps_folder"
	return 1
fi

ports_pkgs_utils__configure_port Terminal "$nojailed_x_terminal__apps_folder"
ports_pkgs_utils__install_pkg Terminal

echo '[Desktop Entry]
Name=Terminal
Icon=terminal
Exec=terminal
Terminal=false
Type=Application
Categories=shew-applications
' > /usr/local/share/applications/terminal.desktop

if [ ! -d /usr/shew/install/done ]; then
	mkdir -p /usr/shew/install/done
	chmod 0700 /usr/shew/install/done
fi

touch /usr/shew/install/done/nojailed_x_terminal
