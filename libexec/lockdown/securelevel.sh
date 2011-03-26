#!/bin/sh

# Contents:	lockdown_securelevel__boot_raise_securelevel

# Variable defaults:
  : ${lockdown_securelevel__rcd_securelevel="/usr/shew/install/shewstring/libexec/lockdown/rc.d/shew_securelevel"}
							# This file is the default securelevel rc.d file.

lockdown_securelevel__boot_raise_securelevel() {
	# This function will set the securelevel to raise to 3 after booting.

	if [ -f /usr/shew/install/done/lockdown_securelevel__boot_raise_securelevel ]; then
		echo "lockdown_securelevel__boot_raise_securelevel was called but it has already been
run, skipping."
		return 0
	fi

	if [ ! -f "$lockdown_securelevel__rcd_securelevel" ]; then
		echo "lockdown_securelevel__boot_raise_securelevel could not find a critical install
file. It should be:
	$lockdown_securelevel__rcd_securelevel"
		return 1
	fi

	cp -f "$lockdown_securelevel__rcd_securelevel" /etc/rc.d/shew_securelevel
	chmod 0500 /etc/rc.d/shew_securelevel

	echo '
# Added by lockdown_securelevel__boot_raise_securelevel for securelevel:
shew_securelevel_enable="YES"
' >> /etc/rc.conf

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/lockdown_securelevel__boot_raise_securelevel
}
