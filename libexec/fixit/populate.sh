#!/bin/sh

# Contents:	fixit_populate__base_man_ports
#		fixit_populate__misc_files

# Variable defaults:
  : ${fixit_populate__fstab="$shew__fixit_shewstring_installer_dir/libexec/fixit/misc/fstab"}
										# This file is the default fstab file.
  : ${fixit_populate__rc_conf="$shew__fixit_shewstring_installer_dir/libexec/fixit/misc/rc.conf"}
										# This file is the default rc.conf file.

fixit_populate__base_man_ports() {
	# This function will install the kernel, base system, man pages, and ports.

	if [ -f "`cat /tmp/thumbdrive_path`"/../ports.tar.gz ]; then
		latest_ports="`cat /tmp/thumbdrive_path`/../ports.tar.gz"
	else
		for val in "`cat /tmp/thumbdrive_path`"/../ports-*.tar.gz; do
			latest_ports="$val"
		done
	fi

	if [ ! -f "$latest_ports" ]; then
		echo "fixit_populate__base_man_ports could not find a critical install file. It
should be:
	`cat /tmp/thumbdrive_path`/../ports*.tar.gz"
		return 1
	fi

	export DESTDIR='/encrypted'

	cd /dist/"$shew__freebsd_version"/base
	echo 'y' \
		| ./install.sh \
		> /dev/null

	cd /dist/"$shew__freebsd_version"/kernels
	./install.sh GENERIC
	rmdir /encrypted/boot/kernel
	ln -s GENERIC /encrypted/boot/kernel

	cd /dist/"$shew__freebsd_version"/manpages
	./install.sh

	export DESTDIR=''

	mkdir -p /encrypted/usr/shew/install/base_system
	cp -f /dist/"$shew__freebsd_version"/base/* /encrypted/usr/shew/install/base_system

	mkdir -p /encrypted/usr/shew/install

	cp -f "$latest_ports" /encrypted/usr/shew/install/ports.tar.gz

	chmod 0700 /encrypted/usr/shew/install
	chmod 0400 /encrypted/usr/shew/install/ports.tar.gz
}

fixit_populate__misc_files() {
	# This function will install misc configuration files needed to boot properly.

	hard_drive_device="$1"

	if [ ! -c /dev/"$hard_drive_device" ]; then
		echo "fixit_populate__misc_files was called on $hard_drive_device
but that device does not exist."
		return 1
	fi

	if [ ! -f "$fixit_populate__fstab" ]; then
		echo "fixit_populate__misc_files could not find a critical install file. It should
be:
	$fixit_populate__fstab"
		return 1
	fi

	if [ ! -f "$fixit_populate__rc_conf" ]; then
		echo "fixit_populate__misc_files could not find a critical install file. It should
be:
	$fixit_populate__rc_conf"
		return 1
	fi

	mkdir -p /encrypted/etc
	chmod 0755 /encrypted/etc

	mkdir -p /encrypted/etc/keys
	cp -f /tmp/*.key /encrypted/etc/keys
	chmod 0500 /encrypted/etc/keys
	chmod 0400 /encrypted/etc/keys/*.key
	chflags -R schg,opaque /encrypted/etc/keys

	fstab_contents="`cat "$fixit_populate__fstab"`"

	eval "echo \"$fstab_contents\"" \
		> /encrypted/etc/fstab
	# This command evaluates the contents of the fstab file while echoing them,
	# which changes the variables to their values.
	chmod 0600 /encrypted/etc/fstab

	mkdir -p \
		/encrypted/media/dvd \
		/encrypted/media/usb

	cp -f "$fixit_populate__rc_conf" /encrypted/etc/rc.conf
	chmod 0600 /encrypted/etc/rc.conf

	mkdir -p /encrypted/usr/shew/install/shewstring
	cp -R "`cat /tmp/thumbdrive_path`"/ /encrypted/usr/shew/install/shewstring
	chmod 0500 /encrypted/usr/shew/install/shewstring

	echo 'block all' \
		> /encrypted/etc/pf.conf
	chmod 0600 /encrypted/etc/pf.conf

	echo '
[devfsrules_system=5]
' > /encrypted/etc/devfs.rules
	chmod 0600 /encrypted/etc/devfs.rules
		# This is the ruleset in rc.conf, and it must exist or there will be an error
		# during boot.

	mkdir -p \
		/encrypted/usr/shew/copy_to_mfs/tmp \
		/encrypted/usr/shew/copy_to_mfs/var \
		/encrypted/usr/shew/mfs
	chmod 0755 \
		/encrypted/usr/shew/copy_to_mfs/var \
		/encrypted/usr/shew/mfs
	chmod 1777 /encrypted/usr/shew/copy_to_mfs/tmp
	cp -af /encrypted/var/ /encrypted/usr/shew/copy_to_mfs/var
	chflags -R noschg /encrypted/var
	rm -Rf \
		/encrypted/tmp \
		/encrypted/var
	ln -s ./usr/shew/mfs/tmp /encrypted/tmp
	ln -s ./usr/shew/mfs/var /encrypted/var
	chmod -h 0444 \
		/encrypted/tmp \
		/encrypted/var
	# This is done here, since it cannot be changed once the computer is booted.

	echo "
# Added by host_configure__add_special_folders for mfs:
md /usr/shew/mfs mfs rw,noatime,noexec,nosuid,-p0755,-s128m 0 0
" >> /encrypted/etc/fstab

	cp -f "$shew__fixit_shewstring_installer_dir"/lib/rc.d/shew_mfs /encrypted/etc/rc.d/shew_mfs
	chmod 0500 /encrypted/etc/rc.d/shew_mfs
	echo '
# Added by host_configure__add_special_folders for mfs:
shew_mfs_enable="YES"
' >> /encrypted/etc/rc.conf
}
