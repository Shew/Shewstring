#!/bin/sh

# This script will install the WPA GUI and allow its user to interact with the
# WPA Supplicant daemon. The WPA GUI home page:
# http://hostap.epitest.fi/wpa_supplicant/

# Arguments:
  password="$arg_1"
  unset arg_1

# Requires:	lib/misc_utils.sh
#		lib/user_maint_utils.sh
#		lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${nojailed_x_wpa_gui__wpa_supplicant_config='/usr/shew/install/shewstring/libexec/nojailed_x/misc/wpa_supplicant.conf'}
								# This file is the default wpa_supplicant.conf.
  : ${nojailed_x_wpa_gui__rcd_wpa_supplicant='/usr/shew/install/shewstring/libexec/nojailed_x/rc.d/shew_wpa_supplicant'}
								# This file is the default wpa_supplicant rc.d file.
  : ${nojailed_x_wpa_gui__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_wpa_gui ]; then
	echo "nojailed_x/wpa_gui.sh was called but it has already been run, skipping."
	return 0
fi

if [ ! -f "$nojailed_x_wpa_gui__wpa_supplicant_config" ]; then
	echo "nojailed_x/wpa_gui.sh could not find a critical install file. It should be:
	$nojailed_x_wpa_gui__wpa_supplicant_config"
	return 1
fi

if [ ! -f "$nojailed_x_wpa_gui__rcd_wpa_supplicant" ]; then
	echo "nojailed_x/wpa_gui.sh could not find a critical install file. It should be:
	$nojailed_x_wpa_gui__rcd_wpa_supplicant"
	return 1
fi

if [ ! -d "$nojailed_x_wpa_gui__apps_folder" ]; then
	echo "nojailed_x/wpa_gui.sh could not find a critical install file. It should be:
	$nojailed_x_wpa_gui__apps_folder"
	return 1
fi

ports_pkgs_utils__configure_port wpa_gui "$nojailed_x_wpa_gui__apps_folder"
ports_pkgs_utils__install_pkg wpa_gui

uid="`user_maint_utils__generate_unique_uid`"
echo "$password" \
	| pw useradd -d /nonexistent -n networker -u "$uid" -h 0

mkdir -p /usr/shew/permanent/root/wpa_supplicant
cp -f "$nojailed_x_wpa_gui__wpa_supplicant_config" /usr/shew/permanent/root/wpa_supplicant/wpa_supplicant.conf
chmod 0500 /usr/shew/permanent/root/wpa_supplicant
chmod 0400 /usr/shew/permanent/root/wpa_supplicant/wpa_supplicant.conf

cp -f "$nojailed_x_wpa_gui__rcd_wpa_supplicant" /etc/rc.d/shew_wpa_supplicant
chmod 0500 /etc/rc.d/shew_wpa_supplicant

echo '
# Added by nojailed_x/wpa_gui.sh for wpa_supplicant:
shew_wpa_supplicant_enable="YES"
ifconfig_wlan0="DHCP"
' >> /etc/rc.conf

if [ ! -f /usr/local/share/desktop-directories/elevated.directory ]; then
	mkdir -p /usr/local/share/desktop-directories
	echo '[Desktop Entry]
Name=Elevated
Icon=folder
' > /usr/local/share/desktop-directories/elevated.directory
	chmod 0444 /usr/local/share/desktop-directories/elevated.directory
fi

if [ ! -d /usr/local/share/applications ]; then
	mkdir -p /usr/local/share/applications
fi

echo "[Desktop Entry]
Name=WPA GUI
Icon=network-wireless
Exec=xterm -e \"echo 'Please enter the guest password.'; su networker -c wpa_gui\"
Terminal=false
Type=Application
Categories=elevated
" > /usr/local/share/applications/wpa_gui.desktop
	chmod 0444 /usr/local/share/applications/wpa_gui.desktop

if [ ! -d /usr/shew/install/done ]; then
	mkdir -p /usr/shew/install/done
	chmod 0700 /usr/shew/install/done
fi

touch /usr/shew/install/done/nojailed_x_wpa_gui
