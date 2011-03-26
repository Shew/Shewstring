#!/bin/sh

# This script will install VLC. The VLC home page: http://www.videolan.org/

# Requires:	lib/ports_pkgs_utils.sh

# Variable defaults:
  : ${nojailed_x_vlc__apps_folder='/usr/shew/install/shewstring/libexec/nojailed_x/apps'}
								# The default nojailed_x apps folder.
  : ${nojailed_x_vlc__home_folder='/usr/shew/install/shewstring/libexec/nojailed_x/home/vlc'}
								# The default vlc home folder.

# Execute:

if [ -f /usr/shew/install/done/nojailed_x_vlc ]; then
	echo "nojailed_x/vlc.sh was called but it has already been run, skipping."
	return 0
fi

if [ ! -d "$nojailed_x_vlc__apps_folder" ]; then
	echo "nojailed_x/vlc.sh could not find a critical install file. It should be:
	$nojailed_x_vlc__apps_folder"
	return 1
fi

if [ ! -d "$nojailed_x_vlc__home_folder" ]; then
	echo "nojailed_x/vlc.sh could not find a critical install file. It should be:
	$nojailed_x_vlc__home_folder"
	return 1
fi

ports_pkgs_utils__configure_port vlc "$nojailed_x_vlc__apps_folder"
ports_pkgs_utils__install_pkg vlc

cp -Rf "$nojailed_x_vlc__home_folder" /tmp/vlc
chown -R guest:guest /tmp/vlc
cp -af /tmp/vlc/ /usr/shew/copy_to_mfs/home/guest
rm -Rf /tmp/vlc

echo '[Desktop Entry]
Name=VLC
Icon=vlc
Exec=vlc
Terminal=false
Type=Application
Categories=shew-applications
MimeType=video/dv;video/mpeg;video/x-mpeg;video/msvideo;video/quicktime;video/x-anim;video/x-avi;video/x-ms-asf;video/x-ms-wmv;video/x-msvideo;video/x-nsv;video/x-flc;video/x-fli;application/ogg;application/x-ogg;application/x-matroska;audio/x-mp3;audio/x-mpeg;audio/mpeg;audio/x-wav;audio/x-mpegurl;audio/x-scpls;audio/x-m4a;audio/x-ms-asf;audio/x-ms-asx;audio/x-ms-wax;application/vnd.rn-realmedia;audio/x-real-audio;audio/x-pn-realaudio;application/x-flac;audio/x-flac;application/x-shockwave-flash;misc/ultravox;audio/vnd.rn-realaudio;audio/x-pn-aiff;audio/x-pn-au;audio/x-pn-wav;audio/x-pn-windows-acm;image/vnd.rn-realpix;video/vnd.rn-realvideo;audio/x-pn-realaudio-plugin;application/x-extension-mp4;audio/mp4;video/mp4;video/mp4v-es;x-content/video-vcd;x-content/video-svcd;x-content/video-dvd;x-content/audio-cdda;x-content/audio-player;video/x-flv;
' > /usr/local/share/applications/vlc.desktop

if [ ! -d /usr/shew/install/done ]; then
	mkdir -p /usr/shew/install/done
	chmod 0700 /usr/shew/install/done
fi

touch /usr/shew/install/done/nojailed_x_vlc
