#!/bin/sh

# This script will install File Roller and P7ZIP. The File Roller home page:
# http://fileroller.sourceforge.net/ and the P7ZIP home page:
# http://p7zip.sourceforge.net/

# Requires:	lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${nojailed_x_file_roller__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_file_roller ]; then
	echo "nojailed_x/file_roller.sh was called but it has already been run, skipping."
	return 0
fi

if [ ! -d "$nojailed_x_file_roller__apps_folder" ]; then
	echo "nojailed_x/file_roller.sh could not find a critical install file. It should be:
	$nojailed_x_file_roller__apps_folder"
	return 1
fi

ports_pkgs_utils__configure_port file-roller "$nojailed_x_file_roller__apps_folder"
ports_pkgs_utils__install_pkg file-roller
ports_pkgs_utils__configure_port p7zip "$nojailed_x_file_roller__apps_folder"
ports_pkgs_utils__install_pkg p7zip

echo '[Desktop Entry]
Name=File-roller
Icon=file-roller
Exec=file-roller
Terminal=false
Type=Application
Categories=shew-applications
MimeType=application/x-7z-compressed;application/x-7z-compressed-tar;application/x-ace;application/x-alz;application/x-ar;application/x-arj;application/x-bzip;application/x-bzip-compressed-tar;application/x-bzip1;application/x-bzip1-compressed-tar;application/x-cabinet;application/x-cbr;application/x-cbz;application/x-cd-image;application/x-compress;application/x-compressed-tar;application/x-cpio;application/x-deb;application/x-ear;application/x-ms-dos-executable;application/x-gtar;application/x-gzip;application/x-gzpostscript;application/x-java-archive;application/x-lha;application/x-lhz;application/x-lzip;application/x-lzip-compressed-tar;application/x-lzma;application/x-lzma-compressed-tar;application/x-lzop;application/x-lzop-compressed-tar;application/x-rar;application/x-rar-compressed;application/x-rpm;application/x-rzip;application/x-tar;application/x-tarz;application/x-stuffit;application/x-war;application/x-xz;application/x-xz-compressed-tar;application/x-zip;application/x-zip-compressed;application/x-zoo;application/zip;
' > /usr/local/share/applications/file-roller.desktop

if [ ! -d /usr/shew/install/done ]; then
	mkdir -p /usr/shew/install/done
	chmod 0700 /usr/shew/install/done
fi

touch /usr/shew/install/done/nojailed_x_file_roller
