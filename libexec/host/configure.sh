#!/bin/sh

# Requires:	lib/user_maint_utils.sh

# Contents:	host_configure__misc_configuration
#		host_configure__add_special_folders
#		host_configure__configure_root_user
#		host_configure__configure_guest_user

# Variable defaults:
  : ${host_configure__sysctl_conf="/usr/shew/install/shewstring/libexec/host/misc/sysctl.conf"}
									# This file is the default sysctl.conf file.
  : ${host_configure__dhclient_conf="/usr/shew/install/shewstring/libexec/host/misc/dhclient.conf"}
									# This file is the default dhclient.conf file.
  : ${host_configure__pf_conf="/usr/shew/install/shewstring/libexec/host/misc/pf.conf"}
									# This file is the default pf.conf file.

host_configure__misc_configuration() {
	# This function will add and configure the basic configuration files needed to
	# run the system, as well as some other misc. configuration. If this task has
	# already been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/host_configure__misc_configuration ]; then
		echo "host_configure__misc_configuration was called but it has already been run,
skipping."
		return 0
	fi

	if [ ! -f "$host_configure__sysctl_conf" ]; then
		echo "host_configure__misc_configuration not find a critical install file. It should
be:
	$host_configure__sysctl_conf"
		return 1
	fi

	if [ ! -f "$host_configure__dhclient_conf" ]; then
		echo "host_configure__misc_configuration not find a critical install file. It should
be:
	$host_configure__dhclient_conf"
		return 1
	fi

	if [ ! -f "$host_configure__pf_conf" ]; then
		echo "host_configure__misc_configuration not find a critical install file. It should
be:
	$host_configure__pf_conf"
		return 1
	fi

	cp -f "$host_configure__sysctl_conf" /etc/sysctl.conf
	cp -f "$host_configure__dhclient_conf" /etc/dhclient.conf

	cp -f "$host_configure__pf_conf" /etc/pf.conf
	pfctl -f /etc/pf.conf

	chmod 0600 \
		/etc/sysctl.conf \
		/etc/dhclient.conf \
		/etc/pf.conf

	echo '
127.0.0.1 computer computer.my.domain
127.0.0.1 localhost localhost.my.domain
' > /etc/hosts
	chmod 0644 /etc/hosts

	cp -f /etc/login.conf /etc/login.conf.tmp
	cat /etc/login.conf.tmp \
		| sed -e 's/passwd_format=md5/passwd_format=blf/' \
		> /etc/login.conf
	rm -f /etc/login.conf.tmp

	echo 'crypt_default = blf' \
		> /etc/auth.conf
	cap_mkdb /etc/login.conf

	pw lock toor
		# toor is the backup root user.

	user_maint_utils__add_group media

	mkdir -p \
		/media/dvd \
		/media/usb
	chown -R root:media /media
	chmod 0550 \
		/media \
		/media/dvd
	chmod 0770 /media/usb

	rm -f /etc/motd

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/host_configure__misc_configuration
}

host_configure__add_special_folders() {
	# This function will add and configure the special folders needed by
	# Shewstring: home, permanent, sensitive and data. If this task has already
	# been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/host_configure__add_special_folders ]; then
		echo "host_configure__add_special_folders was called but it has already been run,
skipping."
		return 0
	fi

	user_maint_utils__add_group home
	user_maint_utils__add_group permanent
	user_maint_utils__add_group sensitive
	user_maint_utils__add_group data

	mkdir -p \
		/usr/shew/copy_to_mfs \
		/usr/shew/copy_to_mfs/home \
		/usr/shew/copy_to_mfs/tmp \
		/usr/shew/copy_to_mfs/var \
		/usr/shew/mfs \
		/usr/shew/permanent \
		/usr/shew/sensitive/host \
		/usr/shew/data/host

	chown root:data \
		/usr/shew/data \
		/usr/shew/data/host
	chown root:home /usr/shew/copy_to_mfs/home
	chown root:permanent /usr/shew/permanent
	chown root:sensitive \
		/usr/shew/sensitive \
		/usr/shew/sensitive/host

	chmod 0750 \
		/usr/shew/copy_to_mfs \
		/usr/shew/copy_to_mfs/home \
		/usr/shew/permanent \
		/usr/shew/sensitive \
		/usr/shew/sensitive/host
	chmod 0755 \
		/usr/shew/copy_to_mfs/var \
		/usr/shew/mfs
	chmod 1777 /usr/shew/copy_to_mfs/tmp
	chmod 0777 \
		/usr/shew/data \
		/usr/shew/data/host

	chmod 0755 /usr/shew/copy_to_mfs/home
		# For some reason, users will not log in correctly unless /home is world
		# readable and executeable. This is a bug.

	chmod 0700 \
		/usr/shew/copy_to_mfs/var/backups \
		/usr/shew/copy_to_mfs/var/crash \
		/usr/shew/copy_to_mfs/var/db \
		/usr/shew/copy_to_mfs/var/log
	chflags opaque \
		/usr/shew/copy_to_mfs/var/backups \
		/usr/shew/copy_to_mfs/var/crash \
		/usr/shew/copy_to_mfs/var/db \
		/usr/shew/copy_to_mfs/var/log

	rm -Rf \
		/usr/shew/copy_to_mfs/var/db/pkg \
		/var/db/pkg
	mkdir -p /usr/ports/pkg_db
	ln -s /usr/ports/pkg_db /usr/shew/copy_to_mfs/var/db/pkg

	/etc/rc.d/shew_mfs start

	rm -Rf \
		/home \
		/usr/home
	ln -s ../usr/shew/mfs/home /usr/home
	ln -s ./usr/shew/mfs/home /home
	chmod -h 0444 \
		/usr/home \
		/home

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/host_configure__add_special_folders
}

host_configure__configure_root_user() {
	# This function will configure the root user and its special folders. If this
	# task has already been done, the function complains and returns true.

	root_password="$1"

	if [ -f /usr/shew/install/done/host_configure__configure_root_user ]; then
		echo "host_configure__configure_root_user was called but it has already been run,
skipping."
		return 0
	fi

	echo "$root_password" \
		| pw usermod root -h 0

	for val in \
		/root/.cshrc \
		/root/.history \
		/root/.hushlogin \
		/root/.login \
		/root/.login_conf \
		/root/.mail_aliases \
		/root/.mailrc \
		/root/.profile \
		/root/.rhosts \
		/root/.shrc \
		/root/.tcshrc
	do
		touch "$val"
		chmod 0440 "$val"
		chflags schg "$val"
	done

	mkdir -p \
		/usr/shew/permanent/root \
		/usr/shew/sensitive/host/root \
		/usr/shew/data/host/root

	chown root:wheel \
		/usr/shew/permanent/root \
		/usr/shew/sensitive/host/root \
		/usr/shew/data/host/root

	chmod 0750 \
		/usr/shew/permanent/root \
		/usr/shew/sensitive/host/root
	chmod 0750 /usr/shew/data/host/root

	touch /usr/shew/sensitive/host/root.allow
	chmod 0400 /usr/shew/sensitive/host/root.allow
	chflags schg,opaque /usr/shew/sensitive/host/root.allow

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/host_configure__configure_root_user
}

host_configure__configure_guest_user() {
	# This function will configure the guest user, which is the default login user.
	# If this task has already been done, the function complains and returns true.

	guest_password="$1"

	if [ -f /usr/shew/install/done/host_configure__configure_guest_user ]; then
		echo "host_configure__configure_guest_user was called but it has already been run,
skipping."
		return 0
	fi

	user_maint_utils__add_user guest "$guest_password" data home jails media permanent sensitive
		# The group media allows a user to access the /media folder, which is the
		# recommended mount location for various types of media.

	pw usermod -n guest -s csh

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/host_configure__configure_guest_user
}
