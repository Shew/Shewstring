#!/bin/sh

# This script is meant to upgrade and do maintenance for Shewstring.
# WARNING: This script is not yet well tested!
#
# To use this script, reboot into single user mode (You will get an option
# screen during boot; press 4 to select single user mode.), run 'mount -a', and
# run it using 'sh'.

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

mount -u -o rw /
mount -u -o rw /usr

echo '
Starting up networking.
'

/etc/rc.d/shew_mfs start
/etc/rc.d/shew_mac_changer start
/etc/rc.d/netoptions start
/etc/rc.d/netif start

for val in \
	`
		ifconfig -l
	`
do
	if
		echo "$val" \
			| grep \
				`
					cat /usr/shew/permanent/root/mac_changer/interface_wired \
						| sed 's/^/ -e ^/' \
						| sed 's/$/\[0-9\]\*$/'
				` \
			> /dev/null
	then
		dhclient "$val"
		break
	fi
done

/etc/rc.d/shew_named start

echo '
Updating the operating system.
'

freebsd-update fetch install

for val in /usr/shew/jails/*; do
	dummy_script_list="`
		find "$val"/bin "$val"/sbin "$val"/rescue "$val"/usr/bin "$val"/usr/sbin \
			| while read line; do
				if [ -f "$line" ]; then
					if
						ls -lo "$line" \
							| grep 'schg' \
							> /dev/null \
							2> /dev/null
					then
						if
							head "$line" \
								| grep 'replaced by a dummy script' \
								> /dev/null \
								2> /dev/null
						then
							echo "$line"
						fi
					fi
				fi
			done
	`"

	freebsd-update -b "$val" fetch install
		# If left on its own, freebsd-update will replace dummy scripts with real executables.

	for val2 in ${dummy_script_list}; do
		if !
			head "$val2" \
				| grep 'replaced by a dummy script' \
				> /dev/null \
				2> /dev/null
		then
			chflags noschg "$val2"
			rm -f "$val2"

			echo '#!/bin/sh
echo "$0 has been replaced by a dummy script." >&2
return 0
' > "$val2"

			chmod 0555 "$val2"
			chflags schg "$val2"
		fi
	done
done

# Ports code is unfinished:
#chroot /usr/shew/jails/compile \
#	portsnap -d /usr/portsnap fetch update
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

# TODO:
# Upgrade I2P.

echo '
Updating Freenet.
'

freenet_update_md5="`md5 -q /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/update.sh`"

chroot /usr/shew/jails/nat_darknets \
	su -m freenet -c '
		cd /usr/shew/permanent/freenet
		/usr/shew/permanent/freenet/update.sh
	'

if [ "$freenet_update_md5" != "`md5 -q /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/update.sh`" ]; then
	cp -f /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/update.sh \
		/usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/update.sh.tmp
	cat /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/update.sh.tmp \
		| sed 's|\./run.sh|#&|' \
		| sed 's/echo Restarting node/#&/' \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/update.sh
	rm -f /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/update.sh.tmp
		# This is to prevent updates to update.sh from overwriting the comments that
		# disable autostarting the FreeNet node.
fi

echo '
Wiping file traces from sensitive partition.
'

cat /dev/random > /usr/shew/sensitive/random
rm -f /usr/shew/sensitive/random
	# This may remove any file traces that remain on the sensitive partition.

echo '
Finished!'
