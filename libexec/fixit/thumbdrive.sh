#!/bin/sh

# Contents:	fixit_thumbdrive__setup

# Variable defaults:
  : ${fixit_thumbdrive__password_debug='NO'}		# Render the boot password visible, which may be useful to detect
							# driver problems. THIS IS INSECURE.

fixit_thumbdrive__setup() {
	# This function will wipe, partition and install the kernel and boot files on
	# the thumbdrive. The thumbdrive is mounted at /thumb

	thumbdrive_device="$1"
	hard_drive_device="$2"

	if [ ! -c /dev/"$thumbdrive_device" ]; then
		echo "fixit_thumbdrive__setup was called on $thumbdrive_device but
that device does not exist."
		return 1
	fi

	if [ ! -c /dev/"$hard_drive_device" ]; then
		echo "fixit_thumbdrive__setup was called on $hard_drive_device but
that device does not exist."
		return 1
	fi

	dd if=/dev/zero of=/dev/"$thumbdrive_device" bs=1M \
		|| true
	# This command is set to true because it always generates an error, due to how
	# the overwrite halts at the end of the device.

	bsdlabel -Bw /dev/"$thumbdrive_device"
	newfs /dev/"${thumbdrive_device}a"

	mkdir -p /thumb
	mount /dev/"${thumbdrive_device}a" /thumb

	cp -Rf /encrypted/boot /thumb/boot

	mkdir -p /thumb/etc
	echo "/dev/${hard_drive_device}.elia / ufs ro 1 1" \
		> /thumb/etc/fstab
	chmod 0500 /thumb/etc
	chmod 0400 /thumb/etc/fstab
	chflags -R schg /thumb/etc

	echo "
# Added by fixit_thumbdrive__setup for geli:
geom_eli_load=\"YES\"
geli_${hard_drive_device}_keyfile0_load=\"YES\"
geli_${hard_drive_device}_keyfile0_type=\"${hard_drive_device}:geli_keyfile0\"
geli_${hard_drive_device}_keyfile0_name=\"/boot/keys/${hard_drive_device}.key\"
" > /thumb/boot/loader.conf

	if [ "$fixit_thumbdrive__password_debug" = YES ]; then
		echo '
WARNING: fixit_thumbdrive__password_debug enabled. This will make the password
visible to the user. (This will also make it visible in the logs, so only use
it when running test installs!)
'

		echo '
# Added by fixit_geli__init for geli:
hint.kbdmux.0.disabled="1"
' >> /thumb/boot/device.hints
			# Sometimes this fixes password entry problems when booting with geli.

		echo '
# Added by fixit_thumbdrive__setup for debug:
# WARNING: THIS IS AN INSECURE OPTION!
kern.geom.eli.visible_passphrase="1"
' >> /thumb/boot/loader.conf
	fi

	chmod 0500 /thumb/boot
	chmod 0600 /thumb/boot/loader.conf

	mkdir -p /thumb/boot/keys
	chflags schg /thumb/boot

	cp -f /tmp/"${hard_drive_device}.key" /thumb/boot/keys
	chmod 0500 /thumb/boot/keys
	chmod 0400 /thumb/boot/keys/"${hard_drive_device}.key"
	chflags -R schg /thumb/boot/keys
}
