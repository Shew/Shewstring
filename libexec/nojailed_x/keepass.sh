#!/bin/sh

# This script will install KeePassX. The KeePassX home page:
# http://www.keepassx.org/

# Requires:	lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${nojailed_x_keepass__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.
  : ${nojailed_x_keepass__home_folder='/usr/shew/install/shewstring/libexec/nojailed_x/home/keepass'}
								# The default keepass home folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_keepass ]; then
	echo "nojailed_x/keepass.sh was called but it has already been run, skipping."
	return 0
fi

if [ ! -d "$nojailed_x_keepass__apps_folder" ]; then
	echo "nojailed_x/keepass.sh could not find a critical install file. It should be:
	$nojailed_x_keepass__apps_folder"
	return 1
fi

if [ ! -d "$nojailed_x_keepass__home_folder" ]; then
	echo "nojailed_x/keepass.sh could not find a critical install file. It should be:
	$nojailed_x_keepass__home_folder"
	return 1
fi

if [ ! -L /usr/shew/jails/compile/usr/ports/packages/Latest/keepassx.tbz ]; then
	ln -s KeePassX.tbz /usr/shew/jails/compile/usr/ports/packages/Latest/keepassx.tbz
		# This is used because for some reason the keepassx port produces a differently
		# named package (KeePassX.tbz).
fi

ports_pkgs_utils__configure_port keepassx "$nojailed_x_keepass__apps_folder"
ports_pkgs_utils__install_pkg keepassx

cp -Rf "$nojailed_x_keepass__home_folder" /tmp/keepass
chown -R guest:guest /tmp/keepass
cp -af /tmp/keepass/ /usr/shew/copy_to_mfs/home/guest
rm -Rf /tmp/keepass

rm -f /usr/local/share/applications/keepassx.desktop

echo '[Desktop Entry]
Name=KeePass
Icon=keepassx
Exec=keepassx
Terminal=false
Type=Application
Categories=shew-applications
MimeType=application/x-keepass;
' > /usr/local/share/applications/keepass.desktop

mkdir -p /usr/shew/sensitive/host/guest/keepass
chown -R guest:guest /usr/shew/sensitive/host/guest/keepass

chflags noschg /usr/shew/sensitive/host/guest.allow
echo 'keepass
keepass/passwords\.kdb' \
	>> /usr/shew/sensitive/host/guest.allow
chflags schg /usr/shew/sensitive/host/guest.allow

if [ ! -d /usr/shew/install/done ]; then
	mkdir -p /usr/shew/install/done
	chmod 0700 /usr/shew/install/done
fi

touch /usr/shew/install/done/nojailed_x_keepass
