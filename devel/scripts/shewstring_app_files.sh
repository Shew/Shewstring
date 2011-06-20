#!/bin/sh

# This script will call devel/generate_app_files.sh with the ports used in
# Shewstring.

# Arguments:
  folder="${1:-/tmp/apps}"

  if
	dirname "$0" \
		| grep '^/' \
		> /dev/null
  then
	directory="${2:-`dirname "$0"`/../..}"
  else
	directory="${2:-`pwd`/`dirname "$0"`/../..}"
  fi

# Execute:

cd "$directory"

mkdir -p "$folder"/x
x_programs='xorg-minimal xorg-drivers xorg-fonts xrdb xterm xkill xdm'
sh "-$-" devel/scripts/generate_app_files.sh "$folder"/x $x_programs

mkdir -p "$folder"/darknets
darknets_programs='tor wget diablo-jdk16 openjdk7 compat4x vidalia'
sh "-$-" devel/scripts/generate_app_files.sh "$folder"/darknets $darknets_programs

mkdir -p "$folder"/nojailed_nox
nojailed_nox_programs='sudo'
sh "-$-" devel/scripts/generate_app_files.sh "$folder"/nojailed_nox $nojailed_nox_programs

mkdir -p "$folder"/nojailed_x
nojailed_x_programs='abiword evince file-roller p7zip galculator keepassx xfce4-mixer mousepad ristretto
sane-backends sane-frontends netpbm Terminal tkdvd vlc wpa_gui xconsole xfce4 xlockmore xautolock'
sh "-$-" devel/scripts/generate_app_files.sh "$folder"/nojailed_x $nojailed_x_programs

mkdir -p "$folder"/jailed_nox
jailed_nox_programs='privoxy'
sh "-$-" devel/scripts/generate_app_files.sh "$folder"/jailed_nox $jailed_nox_programs

mkdir -p "$folder"/jailed_x
jailed_x_programs='abiword evince firefox xpi-torbutton gnash xpi-adblock_plus xpi-noscript gnupg pinentry gpa liferea
pidgin pidgin-otr sylpheed3 Terminal vlc'
sh "-$-" devel/scripts/generate_app_files.sh "$folder"/jailed_x $jailed_x_programs

if [ -f "$folder"/jailed_x/sylpheed3/sylpheed3 ]; then
	mv "$folder"/jailed_x/sylpheed3/sylpheed3 "$folder"/jailed_x/sylpheed3/sylpheed
		# The sylpheed3 /var/db/ports file is named 'sylpheed', instead of
		# 'sylpheed3', for some reason.
fi

mkdir -p "$folder"/lockdown
lockdown_programs='portaudit'
sh "-$-" devel/scripts/generate_app_files.sh "$folder"/lockdown $lockdown_programs
