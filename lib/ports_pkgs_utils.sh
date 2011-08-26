#!/bin/sh

# Requires:	lib/misc_utils.sh
#		lib/jail_maint_utils.sh
#		lib/user_maint_utils.sh

# Contents:	ports_pkgs_utils__check_port_made
#		ports_pkgs_utils__create_compile_jail
#		ports_pkgs_utils__configure_port
#		ports_pkgs_utils__compile_port
#		ports_pkgs_utils__install_pkg

# Variable defaults:
  : ${ports_pkgs_utils__apps_folder='/usr/shew/install/shewstring/lib/apps'}
					# The default system apps folder.

ports_pkgs_utils__check_port_made() {
	# This function checks to see if a port has been compiled, and returns true if
	# it is and false if it is not.

	program="$1"

	if [ ! -f /usr/shew/install/done/ports_pkgs_utils__create_compile_jail ]; then
		return 1
	fi

	if [ -f /usr/shew/jails/compile/usr/ports/packages/Latest/"${program}.tbz" ]; then
		return 0
	else
		return 1
	fi
}

ports_pkgs_utils__create_compile_jail() {
	# This function creates the compile jail where programs are compiled. If this
	# task has already been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/ports_pkgs_utils__create_compile_jail ]; then
		echo "ports_pkgs_utils__create_compile_jail was called but it has already been run,
skipping."
		return 0
	fi

#	if [ ! -f /usr/shew/install/ports.tar.gz ]; then
#		echo 'Ports tarball missing.'
#		return 1
#	fi

	jail_maint_utils__create_jail compile

	rc_jail_list="`
		misc_utils__echo_var /etc/rc.conf jail_list \
			| sed 's/compile *//'
	`"
	misc_utils__change_var /etc/rc.conf jail_list "$rc_jail_list"
		# Make sure that the compile jail does not start at boot.

	mkdir -p /usr/shew/jails/compile/var/db/ports

#	cd /usr/shew/jails/compile/usr
#	tar -x -f /usr/shew/install/ports.tar.gz

	. /usr/shew/install/shewstring/libexec/host/dns.sh
	host_dns__add_jail_dns_rules compile

	. /usr/shew/install/shewstring/libexec/host/network.sh
	host_network__add_jail_nat_rules compile

	jid="`jail_maint_utils__return_jail_jid compile`"

	mkdir -p /usr/shew/jails/compile/usr/portsnap
	echo 'Downloading ports skeleton with portsnap (Log is named portsnap):'
	misc_utils__condense_output_start /usr/shew/install/log/portsnap
	jexec "$jid" \
		portsnap -d /usr/portsnap fetch extract \
		>> /usr/shew/install/log/portsnap \
		2>> /usr/shew/install/log/portsnap
	misc_utils__condense_output_end

	echo 'Configuring portmaster (Log is named make_config_portmaster):'
	misc_utils__condense_output_start /usr/shew/install/log/make_config_portmaster
	while true; do
		echo -n 'o'
	done \
		2> /dev/null \
		| jexec "$jid" \
		make -C /usr/ports/ports-mgmt/portmaster config-recursive \
		>> /usr/shew/install/log/make_config_portmaster \
		2>> /usr/shew/install/log/make_config_portmaster
	# The stderr of the echo is set to /dev/null because otherwise it is logged
	# hundreds of times.
	misc_utils__condense_output_end

	echo 'Making portmaster (Log is named make_package_portmaster):'
	misc_utils__condense_output_start /usr/shew/install/log/make_package_portmaster
	jexec "$jid" \
		make -C /usr/ports/ports-mgmt/portmaster install clean \
		>> /usr/shew/install/log/make_package_portmaster \
		2>> /usr/shew/install/log/make_package_portmaster
	misc_utils__condense_output_end
		# This does not actually make a package, but the log is called
		# 'make_package_portmaster' so it appears with other like entries.

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/ports_pkgs_utils__create_compile_jail
}

ports_pkgs_utils__configure_port() {
	# This function will configure a port in the compile jail. It applies the
	# default configure and then makes any changes to port options as specified by
	# ports_pkgs_utils__apps_folder and argument apps files. Each app file defines
	# overriding options in the form:
	#	with='OPTION1 OPTION2 OPTION3'
	#	without='OPTION4 OPTION5 OPTION6'
	# With the same name as the port it is modifying. If this task has already been
	# done, the function complains and returns true. If the compile jail is
	# missing, ports_pkgs_utils__create_compile_jail is called.

	program="$1"
	shift
	apps_folder="${@:-}"

	if [ ! -f /usr/shew/install/done/ports_pkgs_utils__create_compile_jail ]; then
		ports_pkgs_utils__create_compile_jail
	fi

	if !
		ls /usr/shew/jails/compile/usr/ports/*/"$program" \
			> /dev/null \
			2> /dev/null
	then
		echo "ports_pkgs_utils__configure_port was called with $program but it does
not exist in the ports system."
		return 1
	fi

	for val in $ports_pkgs_utils__apps_folder $apps_folder; do
		if [ ! -d "$val" ]; then
			echo "ports_pkgs_utils__configure_port was called with folder:
	$val
but that apps folder does not exist."
			return 1
		fi
	done

	ports_pkgs_utils__check_port_made "$program" \
		&& {
			echo "ports_pkgs_utils__configure_port was called with $program but that
program is already compiled, skipping."
			return 0
		}

	jid="`jail_maint_utils__return_jail_jid compile`"

	category="`
		echo /usr/shew/jails/compile/usr/ports/*/"$program" \
			| head -n 1 \
			| sed 's|.*/usr/ports/||' \
			| sed "s|/${program}||"
	`"

	if [ ! -f /usr/shew/jails/compile/var/db/ports/"${program}_is_configured" ]; then
		echo "Configuring $program (Log is named make_config_${program}):"
		misc_utils__condense_output_start /usr/shew/install/log/"make_config_$program"

		while true; do
			echo -n 'o'
		done \
			2> /dev/null \
			| jexec "$jid" \
			portmaster -n -t --no-confirm /usr/ports/"$category"/"$program" \
			> /usr/shew/install/log/"make_config_$program" \
			2>> /usr/shew/install/log/"make_config_$program"
		# The stderr of the echo is set to /dev/null because otherwise it is logged
		# hundreds of times.

		misc_utils__condense_output_end

		mkdir -p /usr/shew/jails/compile/var/db/ports
			# If there were no options to configure, this directory is not created.
		touch /usr/shew/jails/compile/var/db/ports/"${program}_is_configured"
	fi

	for val in $ports_pkgs_utils__apps_folder $apps_folder; do
		cd "$val"

		if !
			ls * \
				> /dev/null \
				2> /dev/null
			# This protects the following for loop from invalid input if there are no
			# files.
		then
			continue
		fi

		for val2 in *; do
			. "$val"/"$val2"

			if [ -f /usr/shew/jails/compile/var/db/ports/"$val2"/options ]; then
				for val3 in $with; do
					cp -f /usr/shew/jails/compile/var/db/ports/"$val2"/options \
						/usr/shew/jails/compile/var/db/ports/"$val2"/options.tmp

					cat /usr/shew/jails/compile/var/db/ports/"$val2"/options.tmp \
						| sed "s/WITHOUT_${val3}=true/WITH_${val3}=true/" \
						> /usr/shew/jails/compile/var/db/ports/"$val2"/options

					rm -f /usr/shew/jails/compile/var/db/ports/"$val2"/options.tmp
				done

				for val3 in $without; do
					cp -f /usr/shew/jails/compile/var/db/ports/"$val2"/options \
						/usr/shew/jails/compile/var/db/ports/"$val2"/options.tmp

					cat /usr/shew/jails/compile/var/db/ports/"$val2"/options.tmp \
						| sed "s/WITH_${val3}=true/WITHOUT_${val3}=true/" \
						> /usr/shew/jails/compile/var/db/ports/"$val2"/options

					rm -f /usr/shew/jails/compile/var/db/ports/"$val2"/options.tmp
				done
			fi
		done
	done
}

ports_pkgs_utils__compile_port() {
	# This function will compile a port in the compile jail. The port will have the
	# default configuration, unless already configured by
	# ports_pkgs_utils__configure_port. If this task has already been done, the
	# function complains and returns true.  If the compile jail is missing,
	# ports_pkgs_utils__create_compile_jail is called.

	program="$1"

	if [ ! -f /usr/shew/install/done/ports_pkgs_utils__create_compile_jail ]; then
		ports_pkgs_utils__create_compile_jail
	fi

	if !
		ls /usr/shew/jails/compile/usr/ports/*/"$program" \
			> /dev/null \
			2> /dev/null
	then
		echo "ports_pkgs_utils__compile_port was called with $program but it does not exist in the ports
system."
		return 1
	fi

	ports_pkgs_utils__check_port_made "$program" \
		&& {
			echo "ports_pkgs_utils__compile_port was called with $program but that program is already
compiled, skipping."
			return 0
		}

	jid="`jail_maint_utils__return_jail_jid compile`"

	category="`
		echo /usr/shew/jails/compile/usr/ports/*/"$program" \
			| head -n 1 \
			| sed 's|.*/usr/ports/||' \
			| sed "s|/${program}||"
	`"

	if [ ! -f /usr/shew/jails/compile/var/db/ports/"${program}_is_configured" ]; then
		echo "Configuring $program (Log is named make_config_${program}):"
		misc_utils__condense_output_start /usr/shew/install/log/"make_config_$program"

		while true; do
			echo -n 'o'
		done \
			2> /dev/null \
			| jexec "$jid" \
			portmaster -n -t --no-confirm /usr/ports/"$category"/"$program" \
			> /usr/shew/install/log/"make_config_$program" \
			2>> /usr/shew/install/log/"make_config_$program"
		# The stderr of the echo is set to /dev/null because otherwise it is logged
		# hundreds of times.
		misc_utils__condense_output_end

		mkdir -p /usr/shew/jails/compile/var/db/ports
			# If there were no options to configure, this directory is not created.
		touch /usr/shew/jails/compile/var/db/ports/"${program}_is_configured"
	fi

	# The following variables are used to try and make unattended builds more
	# robust:
	export \
		FETCH_ARGS='-ApFRr' \
		FETCH_REGET='2' \
		FORCE_PKG_REGISTER='YES' \
		TMPDIR='/usr/tmp'

	mkdir -p /usr/shew/jails/compile/usr/tmp

	echo "Making $program (Log is named make_package_${program}):"
	misc_utils__condense_output_start /usr/shew/install/log/"make_package_$program"

	jexec "$jid" \
		portmaster -G -g -d --no-confirm /usr/ports/"$category"/"$program" \
		>> /usr/shew/install/log/"make_package_$program" \
		2>> /usr/shew/install/log/"make_package_$program"

	misc_utils__condense_output_end

	rm -Rf /usr/shew/jails/compile/var/db/ports

	export  \
		TMPDIR=''
}

ports_pkgs_utils__install_pkg() {
	# This function will install a compiled package into the base filesystem or a
	# chroot. The port will have the default configuration, unless already
	# configured by ports_pkgs_utils__configure_port. If the package is not
	# compiled, ports_pkgs_utils__compile_port will be called, so this is really
	# the only function you need to use to install new ports, except optionally
	# ports_pkgs_utils__configure_port. If this task has already been done, the
	# function complains and returns true.

	program="$1"
	chroot="${2:-/}"

	if [ ! -f /usr/shew/install/done/ports_pkgs_utils__create_compile_jail ]; then
		ports_pkgs_utils__create_compile_jail
	fi

	if !
		ls /usr/shew/jails/compile/usr/ports/*/"$program" \
			> /dev/null \
			2> /dev/null
	then
		echo "ports_pkgs_utils__install_pkg was called with $program but it does not
exist in the ports system."
		return 1
	fi

	if [ ! -d "$chroot" ]; then
		echo "ports_pkgs_utils__install_pkg was called with chroot:
	$chroot
but that directory does not exist."
		return 1
	fi

	if [ "$chroot" = / ]; then
		if
			pkg_info -Ex "^${program}-*" \
				> /dev/null			
		then
			echo "ports_pkgs_utils__install_pkg was called with program $program and
chroot:
	$chroot
but that program is already installed there, skipping"
			return 0
		fi
	else
		if
			chroot "$chroot" \
				pkg_info -Ex "^${program}-*" \
				> /dev/null
		then
			echo "ports_pkgs_utils__install_pkg was called with program $program and
chroot:
	$chroot
but that program is already installed there, skipping"
			return 0
		fi
	fi

	ports_pkgs_utils__check_port_made "$program" \
		|| ports_pkgs_utils__compile_port "$program"

	export TMPDIR='/usr/tmp'

	pkg_name="../Latest/${program}.tbz"
		# This is used instead of ../All, because ../Latest does not include version
		# numbers, which is more convenient.

	echo "Unpackaging $program (Log is named pkg_add_${program}):"
	misc_utils__condense_output_start /usr/shew/install/log/"pkg_add_$program"

	if [ "$chroot" = / ]; then
		mkdir -p -m 0600 /tmp/passwd_backup
		chflags opaque /tmp/passwd_backup
		cp -f \
			/etc/group \
			/etc/master.passwd \
			/etc/passwd \
			/etc/pwd.db \
			/etc/spwd.db \
			/tmp/passwd_backup

		export PKG_PATH='/usr/shew/jails/compile/usr/ports/packages/All'

		mkdir -p /usr/tmp

		pkg_add -Fv "$PKG_PATH"/"$pkg_name" \
			>> /usr/shew/install/log/"pkg_add_$program" \
			2>> /usr/shew/install/log/"pkg_add_$program"
		# The -F option is used because some packages don't have the same name as
		# their port, and so they don't show up to the previous installed check.

		rm -Rf /usr/tmp

		cp -f /tmp/passwd_backup/* /etc
			# This will remove any users created by pkg_add.

		rm -PRf /tmp/passwd_backup
	else
		mkdir -p -m 0600 "$chroot"/tmp/passwd_backup
		chflags opaque "$chroot"/tmp/passwd_backup
		cp -f \
			"$chroot"/etc/group \
			"$chroot"/etc/master.passwd \
			"$chroot"/etc/passwd \
			"$chroot"/etc/pwd.db \
			"$chroot"/etc/spwd.db \
			"$chroot"/tmp/passwd_backup

		mkdir -p \
			"$chroot"/usr/ports_nullfs \
			"$chroot"/usr/tmp

		if !
			df -t nullfs "$chroot"/usr/ports_nullfs \
				| tail -n 1 \
				| sed 's/.* //' \
				| grep -x "${chroot}/usr/ports_nullfs" \
				> /dev/null
		then
			mount_nullfs /usr/shew/jails/compile/usr/ports "$chroot"/usr/ports_nullfs
		fi

		export PKG_PATH='/usr/ports_nullfs/packages/All'

		cd /
			# If the current directory does not exist within the jail, pkg_add will fail.

		pkg_add -Fv -C "$chroot" "$PKG_PATH"/"$pkg_name" \
			>> /usr/shew/install/log/"pkg_add_$program" \
			2>> /usr/shew/install/log/"pkg_add_$program"
		# The -F option is used because some packages don't have the same name as
		# their port, and so they don't show up to the previous installed check.

		umount -f "$chroot"/usr/ports_nullfs
		rm -Rf "$chroot"/usr/tmp
		rm -Rf "$chroot"/usr/ports_nullfs

		cp -f "$chroot"/tmp/passwd_backup/* "$chroot"/etc
			# This will remove any users created by pkg_add.

		rm -PRf "$chroot"/tmp/passwd_backup
	fi

	misc_utils__condense_output_end

	export \
		PKG_PATH='' \
		TMPDIR=''
}
