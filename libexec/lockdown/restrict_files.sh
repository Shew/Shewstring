#!/bin/sh

# Contents:	lockdown_restrict_files__restrict_etc
#		lockdown_restrict_files__suid_sgid

lockdown_restrict_files__restrict_etc() {
	# This function will restrict the reading of sensitive /etc files.

	if [ -f /usr/shew/install/done/lockdown_restrict_files__restrict_etc ]; then
		echo "lockdown_restrict_files__restrict_etc was called but it has already been run,
skipping."
		return 0
	fi

	for val in \
		/etc/auth.conf		/etc/devd.conf		/etc/devfs.conf		\
		/etc/dhclient.conf	/etc/pf.conf		/etc/inetd.conf		\
		/etc/rc.conf		/etc/sysctl.conf	/etc/mac.conf		\
		/etc/syslog.conf	/etc/rc.sysctl		/etc/crontab		\
		/etc/fstab		/etc/hosts.allow	/etc/login.access	\
		/etc/master.passwd	/etc/periodic/		/etc/spwd.db		\
		/etc/ttys
	do
		chmod -R 0600 "$val" \
			> /dev/null \
			2> /dev/null \
			|| true
		chflags -R opaque "$val" \
			> /dev/null \
			2> /dev/null \
			|| true
		# These commands are set to true in case the file is set to schg.
	done

	chmod 0644 /etc/login.conf
		# This undoes an undesired chmod from '*.conf'.

	touch /usr/shew/install/done/lockdown_restrict_files__restrict_etc
}

lockdown_restrict_files__suid_sgid() {
	# This function will remove set user/group id from all freebsd binaries except
	# for login and su.

	if [ -f /usr/shew/install/done/lockdown_restrict_files__suid_sgid ]; then
		echo "lockdown_restrict_files__suid_sgid was called but it has already been run,
skipping."
		return 0
	fi

	for val in \
		/bin/rcp		/sbin/mksnap_ffs	/sbin/ping	/sbin/ping6		/sbin/shutdown \
		/usr/bin/at		/usr/bin/atq		/usr/bin/atrm	/usr/bin/batch		/usr/bin/btsockstat \
		/usr/bin/chfn		/usr/bin/chpass		/usr/bin/chsh	/usr/bin/crontab	/usr/bin/fstat \
		/usr/bin/lock		/usr/bin/lpq		/usr/bin/lpr	/usr/bin/lprm		/usr/bin/netstat \
		/usr/bin/opieinfo	/usr/bin/opiepasswd	/usr/bin/passwd	/usr/bin/rlogin		/usr/bin/rsh \
		/usr/bin/wall		/usr/bin/write		/usr/bin/ypchfn	/usr/bin/ypchpass	/usr/bin/ypchsh \
		/usr/bin/yppasswd	/usr/libexec/sendmail/sendmail		/usr/sbin/authpf	/usr/sbin/lpc \
		/usr/sbin/ppp		/usr/sbin/timedc	/usr/sbin/traceroute	/usr/sbin/traceroute6 \
		/usr/sbin/trpt
	do
		chflags noschg "$val"
		chmod 0555 "$val"
	done

	for val in / /usr/shew/jails/*; do
		if [ -d "$val"/usr/local/share/games ]; then
			rm -Rf "$val"/usr/local/share/games
				# For some reason, this is a root suid directory!
		fi
	done

	for val in / /usr/shew/jails/*; do
		for val2 in \
			/usr/local/bin/pkexec \
			/usr/local/libexec/dbus-daemon-launch-helper \
			/usr/local/libexec/polkit-agent-helper-1 \
			/usr/local/libexec/polkit-resolve-exe-helper \
			/usr/local/libexec/polkit-read-auth-helper \
			/usr/local/libexec/polkit-set-default-helper \
			/usr/local/libexec/polkit-grant-helper \
			/usr/local/libexec/polkit-grant-helper-pam \
			/usr/local/libexec/polkit-explicit-grant-helper \
			/usr/local/libexec/polkit-revoke-helper \
			/usr/local/libexec/utempter/utempter \
			/usr/local/libexec/gnome-pty-helper
		do
			if [ -f "$val"/"$val2" ]; then
				chmod 0555 "$val"/"$val2"
			fi
		done
	done
		# These are various suid/sgid files installed by ports.

	touch /usr/shew/install/done/lockdown_restrict_files__suid_sgid
}
