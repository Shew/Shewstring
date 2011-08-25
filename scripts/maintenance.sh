#!/bin/sh

# This script is meant to upgrade and do maintenance for Shewstring.
# WARNING: This script is not yet well tested!
#
# To use this script, reboot into single user mode (You will get an option
# screen during boot; press 4 to select single user mode.), run 'mount -a', and
# run it using 'sh'.

# Libraries:
  . /usr/shew/install/shewstring/lib/misc_utils.sh
  . /usr/shew/install/shewstring/lib/user_maint_utils.sh
  . /usr/shew/install/shewstring/lib/jail_maint_utils.sh

# Execute:

if [ `id -u` -ne 0 ]; then
	echo 'You must run this script as root for it to complete successfully.'
	exit 1
fi

echo 'Make sure you have rebooted into single user mode! (Type "ok" when ready.)'
read answer
while [ "$answer" != ok ]; do
	echo 'Please type "ok" when ready.'
	read answer
done

# Ports code is unfinished:
#echo 'Please provide the path to the new ports tarball:'
#read path
#while [ ! -f "$path" ]; do
#	echo 'That file was not found, or was not a normal file.'
#	read path
#done

mount -u -o rw /
mount -u -o rw /usr

echo '
Starting up networking.
'

/etc/rc.d/shew_mfs start
/etc/rc.d/shew_mac_changer start
/etc/rc.d/netif start
/etc/rc.d/shew_named start

echo '
Updating the operating system.
'

freebsd-update fetch install

cd /usr/shew/jails
for val in *; do
	freebsd-update -b /usr/shew/jails/"$val" fetch install
done

# Ports code is unfinished:
#rm -Rf /usr/shew/jails/compile/usr/ports
#cd /usr/shew/jails/compile/usr
#tar -x -f "$path"
#
#mkdir /tmp/makefiles
#cd /tmp/makefiles
#
## Here-document encoded by 'tar -z -c $dir | uuencode -'
#uudecode -p | gzip | tar -x -f - << end-here-doc
#
#end-here-doc
#
#cp -Rf /tmp/makefiles/ /usr/shew/jails/compile/usr/ports
#rm -R /tmp/makefiles

# TODO:
# Get a list of all ports.
# Generate default configs for each port.
# Look in the Shewstring folder and find all of the configs.
# Apply configs to change the default configs.
#
# Upgrade each port, creating packages.
# Get a list of all ports on host and in each jail.
# If the version is different than the new one from the compile jail, install the new package.

# ExcludeExitNodes upgrade code disabled for now.
# TODO:
# Test for the date last updated.
# Update the date last updated.
#
#excludenodes=''
#
#if
#	ls /usr/shew/jails/nat_darknets/usr/shew/permanent/tor_*/torrc \
#		> /dev/null \
#		2> /dev/null
#	# This protects the following for loop from invalid input if there are no
#	# files.
#then
#	for val in /usr/shew/jails/nat_darknets/usr/shew/permanent/tor_*/torrc; do
#		cp -f "$val" "$val".tmp
#		cat "$val".tmp \
#			| sed "s/ExcludeExitNodes .*/ExcludeExitNodes $excludenodes/" \
#			> "$val"
#		rm -f "$val".tmp
#	done
#fi

jid="`jail_maint_utils__return_jail_jid nat_darknets`"

# TODO:
# Upgrade I2P.

echo '
Updating Freenet.
'

jexec "$jid" \
	sh "-$-" -c '
		cd /usr/shew/permanent/freenet
		su -m freenet -c \
			/usr/shew/permanent/freenet/update.sh.bak
		# The script is named update.sh.bak because update.sh has been replaced by a
		# dummy script.
	'

echo '
Wiping file traces from sensitive partition.
'

cat /dev/random > /usr/shew/sensitive/random
rm -f /usr/shew/sensitive/random
	# This may remove any file traces that remain on the sensitive partition.

echo '
Finished!'
