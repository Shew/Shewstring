#!/bin/sh

# This script will perform a basic install of things contained within the fixit
# scripts. The default settings should be fine for most installers.

# Arguments:
  thumbdrive_device="$arg_1"
  hard_drive_device="$arg_2"
  unset arg_1 arg_2

# Libraries:
  . "$shew__fixit_shewstring_installer_dir"/lib/misc_utils.sh
  . "$shew__fixit_shewstring_installer_dir"/libexec/fixit/thumbdrive.sh
  . "$shew__fixit_shewstring_installer_dir"/libexec/fixit/geli.sh
  . "$shew__fixit_shewstring_installer_dir"/libexec/fixit/populate.sh

# Execute:

echo
shew__current_script='libexec/fixit/exec.sh'
misc_utils__echo_progress

misc_utils__save_progress \
	&& {
		echo '
Wiping, encrypting, and partitioning hard drive. You will be asked for a
passphrase for the encryption (THREE TIMES). NOTE: Wiping the hard drive can
take a LONG time; it can take hours. Please be patient.'

		misc_utils__prompt_continue

		echo
		fixit_geli__init "$hard_drive_device"
	}

misc_utils__save_progress \
	&& {
		echo '
Attaching and mounting encrypted partitions.'
		misc_utils__prompt_continue

		echo
		fixit_geli__attach "$hard_drive_device"
	}

misc_utils__save_progress \
	&& {
		echo '
Installing FreeBSD kernel, base system, and manual pages.'
		misc_utils__prompt_continue

		echo
		fixit_populate__base_man_ports
	}

misc_utils__save_progress \
	&& {
		echo '
Installing configuration files, etc. that are needed to boot properly.'
		misc_utils__prompt_continue

		echo
		fixit_populate__misc_files "$hard_drive_device"
	}

misc_utils__save_progress \
	&& {
		echo '
Wiping, partitioning, and installing boot files on thumbdrive.'
		misc_utils__prompt_continue

		echo
		fixit_thumbdrive__setup "$thumbdrive_device" "$hard_drive_device"
	}
