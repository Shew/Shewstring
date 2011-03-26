#!/bin/sh

# This script will install XConsole. The XOrg home page:
# http://www.x.org/wiki/Home

# Requires:	lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${nojailed_x_xconsole__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_xconsole ]; then
	echo "nojailed_x/xconsole.sh was called but it has already been run, skipping."
	return 0
fi

if [ ! -d "$nojailed_x_xconsole__apps_folder" ]; then
	echo "nojailed_x/xconsole.sh could not find a critical install file. It should be:
	$nojailed_x_xconsole__apps_folder"
	return 1
fi

ports_pkgs_utils__configure_port xconsole "$nojailed_x_xconsole__apps_folder"
ports_pkgs_utils__install_pkg xconsole

if [ ! -d /usr/shew/install/done ]; then
	mkdir -p /usr/shew/install/done
	chmod 0700 /usr/shew/install/done
fi

touch /usr/shew/install/done/nojailed_x_xconsole
