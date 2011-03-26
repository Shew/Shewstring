#!/bin/sh

# Contents:	lockdown_ttys__secure_ttys

lockdown_ttys__secure_ttys() {
	# This function will increase the security of the terminals used on the system.

	if [ -f /usr/shew/install/done/lockdown_ttys__secure_ttys ]; then
		echo "lockdown_ttys__secure_ttys was called but it has already been run, skipping."
		return 0
	fi

	cp -f /etc/ttys /etc/ttys.tmp
	cat /etc/ttys.tmp \
		| sed 's/ secure/ insecure/' \
		> /etc/ttys
	rm -f /etc/ttys.tmp

	chmod 0400 /etc/ttys
	chflags schg,opaque /etc/ttys

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/lockdown_ttys__secure_ttys
}
