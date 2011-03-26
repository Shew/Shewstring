#!/bin/sh

# This script will install the Xfce Mixer. The Mixer home page:
# http://www.xfce.org/projects/xfce4-mixer/

# Requires:	lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${nojailed_x_mixer__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.
  : ${nojailed_x_mixer__home_folder='/usr/shew/install/shewstring/libexec/nojailed_x/home/mixer'}
								# The default mixer home folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_mixer ]; then
	echo "nojailed_x/mixer.sh was called but it has already been run, skipping."
	return 0
fi

if [ ! -d "$nojailed_x_mixer__apps_folder" ]; then
	echo "nojailed_x/mixer.sh could not find a critical install file. It should be:
	$nojailed_x_mixer__apps_folder"
	return 1
fi

if [ ! -d "$nojailed_x_mixer__home_folder" ]; then
	echo "nojailed_x/mixer.sh could not find a critical install file. It should be:
	$nojailed_x_mixer__home_folder"
	return 1
fi

ports_pkgs_utils__configure_port xfce4-mixer "$nojailed_x_mixer__apps_folder"
ports_pkgs_utils__install_pkg xfce4-mixer

cp -Rf "$nojailed_x_mixer__home_folder" /tmp/mixer
chown -R guest:guest /tmp/mixer
cp -af /tmp/mixer/ /usr/shew/copy_to_mfs/home/guest
rm -Rf /tmp/mixer

if [ ! -d /usr/shew/install/done ]; then
	mkdir -p /usr/shew/install/done
	chmod 0700 /usr/shew/install/done
fi

touch /usr/shew/install/done/nojailed_x_mixer
