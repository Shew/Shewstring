#!/bin/sh

# This script will install Xfce. The Xfce home page: http://www.xfce.org/

# Requires:	lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${nojailed_x_xfce__xsession='/usr/shew/install/shewstring/libexec/nojailed_x/misc/xsession'}
								# The default xsession file.
  : ${nojailed_x_xfce__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.
  : ${nojailed_x_xfce__home_folder='/usr/shew/install/shewstring/libexec/nojailed_x/home/xfce'}
								# The default xfce home folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_xfce ]; then
	echo "nojailed_x/xfce.sh was called but it has already been run, skipping."
	return 0
fi

if [ ! -d "$nojailed_x_xfce__apps_folder" ]; then
	echo "nojailed_x/xfce.sh could not find a critical install file. It should be:
	$nojailed_x_xfce__apps_folder"
	return 1
fi

if [ ! -d "$nojailed_x_xfce__home_folder" ]; then
	echo "nojailed_x/xfce.sh could not find a critical install file. It should be:
	$nojailed_x_xfce__home_folder"
	return 1
fi

ports_pkgs_utils__configure_port xfce4 "$nojailed_x_xfce__apps_folder"
ports_pkgs_utils__install_pkg xfce4

rm -f /usr/local/share/applications/Thunar-folder-handler.desktop

echo '[Desktop Entry]
Name=Thunar
Icon=Thunar
Exec=thunar
Terminal=false
Type=Application
Categories=shew-applications
MimeType=x-directory/gnome-default-handler;x-directory/normal;inode/directory;
' > /usr/local/share/applications/thunar.desktop

cp -Rf "$nojailed_x_xfce__home_folder" /tmp/xfce
chown -R guest:guest /tmp/xfce
cp -af /tmp/xfce/ /usr/shew/copy_to_mfs/home/guest
rm -Rf /tmp/xfce

cp -f "$nojailed_x_xfce__xsession" /usr/shew/permanent/guest/xsession
ln -s /usr/shew/permanent/guest/xsession /usr/shew/copy_to_mfs/home/guest/.xsession
ln -s /usr/shew/permanent/guest/xsession /usr/shew/copy_to_mfs/home/guest/.xinitrc
chmod 0550 \
	/usr/shew/permanent/guest/xsession \
	/usr/shew/copy_to_mfs/home/guest/.xsession \
	/usr/shew/copy_to_mfs/home/guest/.xinitrc
chflags -h schg \
	/usr/shew/copy_to_mfs/home/guest/.xsession \
	/usr/shew/copy_to_mfs/home/guest/.xinitrc

mkdir -p \
	/usr/shew/data/host/guest/Desktop \
	/usr/shew/data/host/guest/Desktop/files
chown -R guest:guest /usr/shew/data/host/guest/Desktop
ln -s /usr/shew/data/host/guest/Desktop /usr/shew/copy_to_mfs/home/guest/Desktop
chmod -h 0444 /usr/shew/copy_to_mfs/home/guest/Desktop
chflags -h schg /usr/shew/copy_to_mfs/home/guest/Desktop

mkdir -p \
	/usr/shew/sensitive/host/guest/xfce/desktop \
	/usr/shew/copy_to_mfs/home/guest/.config/xfce4
chown -R guest:guest \
	/usr/shew/sensitive/host/guest/xfce/desktop \
	/usr/shew/copy_to_mfs/home/guest/.config
ln -s /usr/shew/sensitive/host/guest/xfce/desktop /usr/shew/copy_to_mfs/home/guest/.config/xfce4/desktop
chmod -h 0444 /usr/shew/copy_to_mfs/home/guest/.config/xfce4/desktop
chflags -h schg /usr/shew/copy_to_mfs/home/guest/.config/xfce4/desktop
	# This folder contains files that define where the icons are on the desktop.

chflags noschg /usr/shew/sensitive/host/guest.allow
echo 'xfce
xfce/desktop
xfce/desktop/icons.screen[0-9]\.rc' \
	>> /usr/shew/sensitive/host/guest.allow
chflags schg /usr/shew/sensitive/host/guest.allow

if [ ! -d /usr/shew/install/done ]; then
	mkdir -p /usr/shew/install/done
	chmod 0700 /usr/shew/install/done
fi

touch /usr/shew/install/done/nojailed_x_xfce
