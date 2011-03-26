#!/bin/sh

# The XOrg home page: http://www.x.org/wiki/Home

# Requires:	lib/misc_utils.sh
#		lib/ports_pkgs_utils.sh

# Contents:	x_xorg__install_xorg
#		x_xorg__install_xterm
#		x_xorg__install_xkill
#		x_xorg__install_xdm

# Variable defaults:
  : ${x_xorg__apps_folder='/usr/shew/install/shewstring/libexec/x/apps'}
					# The default x apps folder.
  : ${x_xorg__rcd_xdm='/usr/shew/install/shewstring/libexec/x/rc.d/shew_xdm'}
					# The default xdm rc.d file.

x_xorg__install_xorg() {
	# This function will install and configure xorg-minimal. If this task has
	# already been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/x_xorg__install_xorg ]; then
		echo "x_xorg__install_xorg was called but it has already been run, skipping."
		return 0
	fi

	if [ ! -d "$x_xorg__apps_folder" ]; then
		echo "x_xorg__install_xorg could not find a critical install file. It should be:
	$x_xorg__apps_folder"
		return 1
	fi

	ports_pkgs_utils__configure_port xorg-minimal "$x_xorg__apps_folder"
	ports_pkgs_utils__install_pkg xorg-minimal

	ports_pkgs_utils__configure_port xorg-drivers "$x_xorg__apps_folder"
	ports_pkgs_utils__install_pkg xorg-drivers

	ports_pkgs_utils__configure_port xorg-fonts "$x_xorg__apps_folder"
	ports_pkgs_utils__install_pkg xorg-fonts

	ports_pkgs_utils__configure_port xrdb "$x_xorg__apps_folder"
	ports_pkgs_utils__install_pkg xrdb

	cp /usr/shew/jails/compile/usr/local/bin/xkbcomp /usr/local/bin
		# For some reason, this is not added to the package.

	Xorg -configure

	mv /root/xorg.conf.new /etc/xorg.conf
	chmod 0600 /etc/xorg.conf

	echo '
# Added by x_xorg__install_xorg for xorg:
Section "ServerFlags"
	Option "AllowEmptyInput" "no"
EndSection
' >> /etc/xorg.conf
		# If this is not added, Xorg does not allow input.

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/x_xorg__install_xorg
}

x_xorg__install_xterm() {
	# This function will install and configure xterm. If this task has already been
	# done, the function complains and returns true.

	if [ -f /usr/shew/install/done/x_xorg__install_xterm ]; then
		echo "x_xorg__install_xterm was called but it has already been run, skipping."
		return 0
	fi

	if [ ! -d "$x_xorg__apps_folder" ]; then
		echo "x_xorg__install_xterm could not find a critical install file. It should be:
	$x_xorg__apps_folder"
		return 1
	fi

	ports_pkgs_utils__configure_port xterm "$x_xorg__apps_folder"
	ports_pkgs_utils__install_pkg xterm

	chmod 0555 /usr/local/bin/xterm
		# Normally this program is suid.

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/x_xorg__install_xterm
}

x_xorg__install_xkill() {
	# This function will install and configure xkill. If this task has already been
	# done, the function complains and returns true.

	if [ -f /usr/shew/install/done/x_xorg__install_xkill ]; then
		echo "x_xorg__install_xkill was called but it has already been run, skipping."
		return 0
	fi

	if [ ! -d "$x_xorg__apps_folder" ]; then
		echo "x_xorg__install_xkill could not find a critical install file. It should be:
	$x_xorg__apps_folder"
		return 1
	fi

	ports_pkgs_utils__configure_port xkill "$x_xorg__apps_folder"

	ports_pkgs_utils__install_pkg xkill

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/x_xorg__install_xkill
}

x_xorg__install_xdm() {
	# This function will install and configure xdm. If this task has already been
	# done, the function complains and returns true.

	if [ -f /usr/shew/install/done/x_xorg__install_xdm ]; then
		echo "x_xorg__install_xdm was called but it has already been run, skipping."
		return 0
	fi

	if [ ! -d "$x_xorg__apps_folder" ]; then
		echo "x_xorg__install_xdm could not find a critical install file. It should be:
	$x_xorg__apps_folder"
		return 1
	fi

	if [ ! -f "$x_xorg__rcd_xdm" ]; then
		echo "x_xorg__install_xdm could not find a critical install file. It should be:
	$x_xorg__rcd_xdm"
		return 1
	fi

	ports_pkgs_utils__configure_port xdm "$x_xorg__apps_folder"

	ports_pkgs_utils__install_pkg xdm

	cp -f "$x_xorg__rcd_xdm" /etc/rc.d/shew_xdm
	chmod 0500 /etc/rc.d/shew_xdm

	echo '
# Added by x_xorg__install_xdm for xdm:
shew_xdm_enable="YES"
' >> /etc/rc.conf

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/x_xorg__install_xdm
}
