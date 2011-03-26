#!/bin/sh

# Contents:	fixit_geli__init
#		fixit_geli__attach

# Variable defaults:
  : ${fixit_geli__encrypt_algo="AES"}		# The encryption algorithm to use.
  : ${fixit_geli__encrypt_length="256"}		# The key size to use with the encryption algorithm.
  : ${fixit_geli__verify_algo="HMAC/SHA256"}	# The hash algorithm to verify that the encrypted partition has not
						# been tampered with. Set to NONE for no verification. HMAC/SHA256
						# will reduce availible size by approximately 11%.
  : ${fixit_geli__wipe='RANDOM'}		# How to wipe the hard drive: RANDOM, ZERO, or NONE. ZERO and NONE
						# are both insecure and should only be used for debugging. You must
						# also set fixit_geli__verify_algo to NONE to use NONE here.
  : ${fixit_geli__bsdlabel_file="$shew__fixit_shewstring_installer_dir/libexec/fixit/misc/bsdlabel"}
						# The file bsdlabel uses to determine how to write partitions.

fixit_geli__init() {
	# This function will wipe the hard drive, create an encrypted geli container
	# for it, and create partitions and filesystems for it based on the contents of
	# the $fixit_geli__bsdlabel_file.

	hard_drive_device="$1"

	if [ ! -c /dev/"$hard_drive_device" ]; then
		echo "fixit_geli__init was called on $hard_drive_device but that
device does not exist."
		return 1
	fi

	if [ ! -f "$fixit_geli__bsdlabel_file" ]; then
		echo "fixit_geli__init could not find a critical install file. It should be:
	$fixit_geli__bsdlabel_file"
		return 1
	fi

	dd if=/dev/random of=/tmp/"${hard_drive_device}.key" bs=1k count=1 \
		2> /dev/null
	# This is done before wiping the hard drive in case the supply of random numbers is
	# of lesser quality after wiping it.

	if [ "$fixit_geli__verify_algo" = "NONE" ]; then
		verify__algo=''
	else
		verify__algo="-a $fixit_geli__verify_algo"
	fi

	ln -s /dist/lib /lib
	rm -Rf /boot
	ln -s /dist/boot /boot
	kldload geom_eli

	until
		geli init \
			$verify__algo \
			-b -B none \
			-e "$fixit_geli__encrypt_algo" -K /tmp/"${hard_drive_device}.key" \
			-l "$fixit_geli__encrypt_length" -s 4096 \
			/dev/"$hard_drive_device" \
			\
			&& geli attach \
				-k /tmp/"${hard_drive_device}.key" \
				/dev/"$hard_drive_device"
	do
		echo 'Encrypted container creation failed. Did you enter your passwords correctly?'
	done

	if [ "$fixit_geli__wipe" = ZERO ]; then
		echo '
WARNING: fixit_geli__wipe set to ZERO. Wiping the hard drive with zeros. (This
can enable known plaintext attacks, so only use it when running test installs!)
'

		dd if=/dev/zero of=/dev/"$hard_drive_device".eli bs=1M \
			|| true
	elif [ "$fixit_geli__wipe" = NONE ]; then
		echo '
WARNING: fixit_geli__wipe set to NONE. Skipping the hard drive wipe. (This can
enable an attacker to see what areas of the drive have been written to, so only
use it when running test installs!)
'
	else
		echo 'Writing random numbers to the hard drive...'

		dd if=/dev/random of=/dev/"$hard_drive_device".eli bs=1M \
			|| true
	fi
		# This is done after geli because the authentication makes bsdlabel, etc. generate errors unless
		# all areas of the new encrypted partition are written to. The command is set to true because it
		# always generates an error, due to how the overwrite halts at the end of the device.

	bsdlabel -R /dev/"${hard_drive_device}.eli" "$fixit_geli__bsdlabel_file"

	echo 'Creating the new filesystems. (Log is named fixit_newfs):'
	misc_utils__condense_output_start /usr/shew/install/log/fixit_newfs

	for val in /dev/"${hard_drive_device}.eli"a /dev/"${hard_drive_device}.eli"[d-z]; do
		# b is skipped because that letter is used for swap and is not partitioned.
		# c is skipped because that letter represents the whole drive.

		newfs "$val" \
			>> /usr/shew/install/log/fixit_newfs \
			2>> /usr/shew/install/log/fixit_newfs
	done

	misc_utils__condense_output_end
}

fixit_geli__attach() {
	# This function will attach the hard drive's encrypted geli container if it is
	# not already attached, it will then mount the partitions in their proper
	# places based on the contents of $fixit_geli__bsdlabel_file, with /encrypted
	# prepended to the mount point. The partitions should be given by their full
	# path after a # and space in $fixit_geli__bsdlabel_file. For example:
	# 	d: 20G * 4.2BSD 0 0 0 # /usr
	# Mounts the partition d at /encrypted/usr

	hard_drive_device="$1"

	if [ ! -c /dev/"$hard_drive_device" ]; then
		echo "fixit_geli__attach was called on $hard_drive_device but that device
does not exist."
		return 1
	fi

	if [ ! -f "$fixit_geli__bsdlabel_file" ]; then
		echo "fixit_geli__attach could not find a critical install file. It should be:
	$fixit_geli__bsdlabel_file"
		return 1
	fi

	if [ ! -c /dev/"${hard_drive_device}.eli" ]; then
		until
			geli attach \
				-k /tmp/"${hard_drive_device}.key" \
				/dev/"$hard_drive_device"
		do
			echo 'Encrypted container attachment failed. Did you enter your passwords correctly?'
		done
	fi

	for val in a d e f g h i j k l m n o p q r s t u v w x y z; do
		# b is skipped because that letter is used for swap and is not partitioned.
		# c is skipped because that letter represents the whole drive.

		if
			cat "$fixit_geli__bsdlabel_file" \
				| grep "^${val}:" \
				> /dev/null
		then
			mount_location="`
				cat "$fixit_geli__bsdlabel_file" \
				| grep "^${val}:" \
				| tail -n 1 \
				| sed 's/.*# *//'
			`"

			mkdir -p /encrypted/"$mount_location"

			mount /dev/"${hard_drive_device}.eli$val" /encrypted/"$mount_location"
		fi
	done
}
