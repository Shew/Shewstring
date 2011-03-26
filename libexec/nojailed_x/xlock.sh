#!/bin/sh

# This script will install Xlockmore and Xautolock. The Xlockmore home page:
# http://www.tux.org/~bagleyd/xlockmore.html

# Requires:	lib/misc_utils.sh
#		lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${nojailed_x_xlock__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_xlock ]; then
	echo "nojailed_x/xlock.sh was called but it has already been run, skipping."
	return 0
fi

if [ ! -d "$nojailed_x_xlock__apps_folder" ]; then
	echo "nojailed_x/xlock.sh could not find a critical install file. It should be:
	$nojailed_x_xlock__apps_folder"
	return 1
fi

ports_pkgs_utils__configure_port xlockmore "$nojailed_x_xlock__apps_folder"
ports_pkgs_utils__install_pkg xlockmore
ports_pkgs_utils__configure_port xautolock "$nojailed_x_xlock__apps_folder"
ports_pkgs_utils__install_pkg xautolock

misc_utils__add_clause /usr/shew/permanent/guest/xsession '## Start misc. desktop programs here:' \
	'# Added by nojailed_x/xlock.sh for xlock:\
	/usr/local/bin/xautolock &'

if [ ! -d /usr/shew/install/done ]; then
	mkdir -p /usr/shew/install/done
	chmod 0700 /usr/shew/install/done
fi

touch /usr/shew/install/done/nojailed_x_xlock
