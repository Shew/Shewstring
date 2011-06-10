#!/bin/sh

# This script is a wrapper for libexec/main_installer.sh that will properly
# implement progress saving and recovering crashed installations.

debug="${1:-nodebug}"

if
	dirname "$0" \
		| grep '^/' \
		> /dev/null
then
	install_directory="`dirname "$0"`"
else
	install_directory="`pwd`/`dirname "$0"`"
fi

echo '
Starting Shewstring. If the installer exits, you can restart it at the same
location by running this script again.'

if [ `id -u` -ne 0 ]; then
	echo 'You must run this script as root for it to complete successfully.'
	exit 1
fi

if [ -f /tmp/crash_recovery ]; then
	export misc_utils__recovery_mode='YES'

	export misc_utils__recovery_progress="`
		cat /tmp/crash_recovery
	`"

	echo 'Using recovery mode to return to a previously saved location in the install.'
fi

if [ "$debug" = debug ]; then
	echo '
WARNING: You have enabled debug mode. Because of the way debug is implemented
(via sh -xv), all passwords will appear in the logs. It is recommended that you
only use test passwords while in debug mode. Also, sensitive information
generated by Shewstring may be revealed. Unfortunately, it is not currently
feasable to scrub the logs automatically.
'

	sh -euvx "${install_directory}"/libexec/main_installer.sh \
		2> /tmp/shewstring_log.txt \
		|| echo "
Shewstring has exited with an exit value of ${?}."
else
	echo

	sh -eu "${install_directory}"/libexec/main_installer.sh \
		|| echo "
Shewstring has exited with an exit value of ${?}."
fi
	# The -eu options are necessary because Shewstring needs to exit whenever there
	# is an error or undefined variable.
