#!/bin/sh

# Requires:	lib/misc_utils.sh
#		lib/user_maint_utils.sh

# Contents:	jail_maint_utils__generate_unique_127ip
#		jail_maint_utils__return_jail_ip
#		jail_maint_utils__return_jail_jid
#		jail_maint_utils__create_jail
#		jail_maint_utils__create_data
#		jail_maint_utils__create_home
#		jail_maint_utils__create_permanent
#		jail_maint_utils__create_sensitive
#		jail_maint_utils__allow_telnet
#		jail_maint_utils__allow_x
#		jail_maint_utils__allow_sound
#		jail_maint_utils__setup_program_telnet
#		jail_maint_utils__setup_program_desktop
#		jail_maint_utils__lockdown_jail

jail_maint_utils__generate_unique_127ip() {
	# This function will generate a unique IP address in 127.0.0.0/8 for a jail.
	# Besides 127.0.0.1, all IPs must be in /etc/hosts to be considered 'taken',
	# so all jails should have their IPs added there.

	while true; do
		jail_ip="127.`jot -r 1 0 255`.`jot -r 1 0 255`.`jot -r 1 2 254`"

		if
			cat /etc/hosts \
				| grep "^ *$jail_ip " \
				> /dev/null
		then
			continue
		fi

		if
			echo "$jail_ip" \
				| grep '^127\.192' \
				> /dev/null
			# 127.192.0.0/16 is excluded because it is the ip range that tor resolves
			# virtual addresses to (actually 127.192.0.0/10).
		then
			continue
		fi

		break
	done

	echo "$jail_ip"
}

jail_maint_utils__return_jail_ip() {
	# This function will return the IP address of a jail, given its name. This is
	# looked up in /etc/hosts, so all jails should have their IPs added there.

	jail_name="$1"

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		return 1
	fi

	cat /etc/hosts \
		| grep "$jail_name ${jail_name}.my.domain *$" \
		| tail -n 1 \
		| sed "s/ ${jail_name}.*//"
}

jail_maint_utils__return_jail_jid() {
	# This function will return the jid of a jail. You should be able to use the
	# jail name in commands, but there doesn't seem to be a way to set it in
	# rc.conf (jail_${jail_name}_name="$jail_name" does not work). This will also
	# bring up a jail if it is not already up.

	jail_name="$1"

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		return 1
	fi

	if !
		jls -n -h path \
			| grep "path=/usr/shew/jails/$jail_name" \
			> /dev/null
	then
		rm -f /var/run/"jail_${jail_name}.id" \
			> /dev/null \
			2> /dev/null \
			|| true
		# A jail will die and leave its ID and thus refuse to start again if it is left
		# with no processes in it.

		/etc/rc.d/jail start "$jail_name" \
			> /dev/null
	fi

	cat /var/run/"jail_${jail_name}.id"
}

jail_maint_utils__create_jail() {
	# This function will create a jail, prepare it for use, and bring it online.
	# Other functions must be used for specific tasks, e.g. adding special folders,
	# and enabling telnetd. If this task has already been done, the function
	# complains and returns true.

	jail_name="$1"

	if [ -f /usr/shew/install/done/"$jail_name"/jail_maint_utils__create_jail ]; then
		echo "jail_maint_utils__create_jail was called on $jail_name but it has
already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/install/base_system ]; then
		echo 'Base system installer missing.'
		return 1
	fi

	user_maint_utils__add_group jails

	mkdir -p /usr/shew/jails/"$jail_name"

	cd /usr/shew/install/base_system
	export DESTDIR="/usr/shew/jails/$jail_name"
	echo 'y' \
		| /usr/shew/install/base_system/install.sh \
		> /dev/null
	export DESTDIR=''

	mkdir -p \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/tmp \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/var \
		/usr/shew/jails/"$jail_name"/usr/shew/mfs
	chown root:jails \
		/usr/shew/jails \
		/usr/shew/jails/"$jail_name"
	chmod 0750 \
		/usr/shew/jails \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs
	chmod 0755 \
		/usr/shew/jails/"$jail_name" \
		/usr/shew/jails/"$jail_name"/usr/shew/mfs \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/var
	chmod 1777 /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/tmp

	cp -af /usr/shew/jails/"$jail_name"/var/ /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/var
	chflags -R noschg /usr/shew/jails/"$jail_name"/var
	rm -Rf \
		/usr/shew/jails/"$jail_name"/tmp \
		/usr/shew/jails/"$jail_name"/var
	ln -s ./usr/shew/mfs/tmp /usr/shew/jails/"$jail_name"/tmp
	ln -s ./usr/shew/mfs/var /usr/shew/jails/"$jail_name"/var
	chmod -h 0444 \
		/usr/shew/jails/"$jail_name"/tmp \
		/usr/shew/jails/"$jail_name"/var

	chmod 0700 \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/var/backups \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/var/crash \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/var/db \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/var/log
	chflags opaque \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/var/backups \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/var/crash \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/var/db \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/var/log

	rm -Rf \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/var/db/pkg \
		/usr/shew/jails/"$jail_name"/var/db/pkg
	mkdir -p /usr/shew/jails/"$jail_name"/usr/ports/pkg_db
	ln -s /usr/ports/pkg_db /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/var/db/pkg

	echo "
# Added by jail_maint_utils__create_jail for ${jail_name}:
md /usr/shew/jails/${jail_name}/usr/shew/mfs mfs rw,noatime,noexec,nosuid,-p0755,-s128m 0 0
" >> /etc/fstab

	mount /usr/shew/jails/"$jail_name"/usr/shew/mfs

	cp -f /usr/shew/install/shewstring/lib/rc.d/shew_mfs /usr/shew/jails/"$jail_name"/etc/rc.d/shew_mfs
	chmod 0500 /usr/shew/jails/"$jail_name"/etc/rc.d/shew_mfs
	chroot /usr/shew/jails/"$jail_name" \
		/etc/rc.d/shew_mfs onestart

	echo 'pass quick inet proto tcp from !127.0.0.0/8 to !127.0.0.0/8 port 80' \
		| pfctl -m -f -
	echo "Updating ${jail_name}. (Log is named update_${jail_name}):"
	misc_utils__condense_output_start /usr/shew/install/log/"update_$jail_name"

	freebsd-update -b /usr/shew/jails/"$jail_name" fetch install \
		>> /usr/shew/install/log/"update_$jail_name" \
		2>> /usr/shew/install/log/"update_$jail_name"

	misc_utils__condense_output_end
	pfctl -f /etc/pf.conf

	echo '
cron_enable="NO"
hostid_enable="NO"
inetd_enable="NO"
kern_securelevel="3"
kern_securelevel_enable="YES"
populate_var="NO"
sendmail_enable="NONE"
shew_mfs_enable="YES"
syslogd_flags="-ss"
update_motd="NO"
' > /usr/shew/jails/"$jail_name"/etc/rc.conf
	chmod 0600 /usr/shew/jails/"$jail_name"/etc/rc.conf

	touch /usr/shew/jails/"$jail_name"/etc/fstab
	chmod 0600 /usr/shew/jails/"$jail_name"/etc/fstab
		# The jail will have a minor boot error if there is no fstab file.

	chroot /usr/shew/jails/"$jail_name" \
		sh "-$-" -c \
		'
			cp -f /etc/login.conf /etc/login.conf.tmp
			cat /etc/login.conf.tmp \
				| sed -e "s/passwd_format=md5/passwd_format=blf/" \
				> /etc/login.conf
			rm -f /etc/login.conf.tmp

			echo "crypt_default = blf" \
				> /etc/auth.conf
			cap_mkdb /etc/login.conf

			pw lock root
			pw lock toor
				# toor is the backup root user.

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
		'

	rm -f /usr/shew/jails/${jail_name}/etc/motd

	ip="`jail_maint_utils__generate_unique_127ip`"
	echo "$ip $jail_name ${jail_name}.my.domain" \
		>> /etc/hosts

	echo "
127.0.0.1 computer computer.my.domain
$ip localhost localhost.my.domain
" > /usr/shew/jails/${jail_name}/etc/hosts
	chmod 0644 /usr/shew/jails/${jail_name}/etc/hosts

	rc_jail_list="`misc_utils__echo_var /etc/rc.conf jail_list`"
	if [ "$rc_jail_list" ]; then
		misc_utils__change_var /etc/rc.conf jail_list "$rc_jail_list $jail_name"
	else
		misc_utils__change_var /etc/rc.conf jail_list "$jail_name"
	fi

	loopback="`misc_utils__generate_unique_loopback`"
	echo "${jail_name}=\"${loopback}\"" \
		>> /usr/shew/install/resources/loopbacks

	cloned_interfaces="`misc_utils__echo_var /etc/rc.conf cloned_interfaces`"
	if [ "$cloned_interfaces" ]; then
		misc_utils__change_var /etc/rc.conf cloned_interfaces "$cloned_interfaces lo$loopback"
	else
		misc_utils__change_var /etc/rc.conf cloned_interfaces "lo$loopback"
	fi

	ifconfig "lo$loopback" create

	echo "
# Added by jail_maint_utils__create_jail for ${jail_name}:
jail_${jail_name}_rootdir=\"/usr/shew/jails/${jail_name}\"
jail_${jail_name}_devfs_enable=\"YES\"
jail_${jail_name}_devfs_ruleset=\"devfsrules_jail\"
jail_${jail_name}_hostname=\"localhost\"
jail_${jail_name}_interface=\"lo${loopback}\"
jail_${jail_name}_ip=\"${ip}\"
" >> /etc/rc.conf

	/etc/rc.d/jail start "$jail_name"

	if [ ! -d /usr/shew/install/done/"$jail_name" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"
		chmod 0700 /usr/shew/install/done/"$jail_name"
	fi

	touch /usr/shew/install/done/"$jail_name"/jail_maint_utils__create_jail
}

jail_maint_utils__create_data() {
	# This function will prepare the /usr/shew/data directory of a jail for use.
	# This directory is meant to contain program or user specific files which are
	# changed during use but are very large or are not accessed normally. User
	# downloaded files is an example use. If this task has already been done, the
	# function complains and returns true.

	jail_name="$1"

	if [ -f /usr/shew/install/done/"$jail_name"/jail_maint_utils__create_data ]; then
		echo "jail_maint_utils__create_data was called on $jail_name but it has
already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "jail_maint_utils__create_data was called on $jail_name but that jail
does not exist."
		return 1
	fi

	user_maint_utils__add_jail_group "$jail_name" data

	gid="`user_maint_utils__return_gid data /usr/shew/jails/"$jail_name"`"

	mkdir -p \
		/usr/shew/data/"$jail_name" \
		/usr/shew/jails/"$jail_name"/usr/shew/data
	chown root:"$gid" /usr/shew/data/"$jail_name"
	chroot /usr/shew/jails/"$jail_name" \
		chown root:data /usr/shew/data
	chmod 0770 \
		/usr/shew/data/"$jail_name" \
		/usr/shew/jails/"$jail_name"/usr/shew/data

	misc_utils__add_clause /etc/fstab "# Added by jail_maint_utils__create_jail for ${jail_name}:" \
		"/usr/shew/data/${jail_name} /usr/shew/jails/${jail_name}/usr/shew/data nullfs rw,noatime 0 0"

	mount /usr/shew/jails/${jail_name}/usr/shew/data

	if [ ! -d /usr/shew/install/done/"$jail_name" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"
		chmod 0700 /usr/shew/install/done/"$jail_name"
	fi

	touch /usr/shew/install/done/"$jail_name"/jail_maint_utils__create_data
}

jail_maint_utils__create_home() {
	# This function will prepare the /home directory of a jail for use. /home is a
	# static partition (/usr/shew/copy_to_mfs) which is copied to a memory filesystem
	# (/usr/shew/mfs). Running /etc/rc.d/shew_mfs in the jail will copy over the
	# files. If this task has already been done, the function complains and returns
	# true.

	jail_name="$1"

	if [ -f /usr/shew/install/done/"$jail_name"/jail_maint_utils__create_home ]; then
		echo "jail_maint_utils__create_home was called on $jail_name but it has
already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "jail_maint_utils__create_home was called on $jail_name but that jail
does not exist."
		return 1
	fi

	user_maint_utils__add_jail_group "$jail_name" home

	gid="`user_maint_utils__return_gid home /usr/shew/jails/"$jail_name"`"

	mkdir -p /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home
	chown root:"$gid" /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home
	#chmod 0750 /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home
	chmod 0755 /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home
		# For some reason, users will not log in correctly unless /home is world
		# readable and executeable. This is a bug.

	ln -s ../usr/shew/mfs/home /usr/shew/jails/"$jail_name"/usr/home
	ln -s ./usr/shew/mfs/home /usr/shew/jails/"$jail_name"/home
	chmod -h 0444 \
		/usr/shew/jails/"$jail_name"/usr/home \
		/usr/shew/jails/"$jail_name"/home

	chroot /usr/shew/jails/"$jail_name" \
		/etc/rc.d/shew_mfs start

	if [ ! -d /usr/shew/install/done/"$jail_name" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"
		chmod 0700 /usr/shew/install/done/"$jail_name"
	fi

	touch /usr/shew/install/done/"$jail_name"/jail_maint_utils__create_home
}

jail_maint_utils__create_permanent() {
	# This function will prepare the /usr/shew/permanent directory of a jail for
	# use. This directory is meant to contain program or user specific files which
	# are unchanging once that program or user is set up. Configuration files are
	# an example of files that would go in the permanent folder, and would normally
	# be linked to from home by symbolic links with schg flags. If this task has
	# already been done, the function complains and returns true.

	jail_name="$1"

	if [ -f /usr/shew/install/done/"$jail_name"/jail_maint_utils__create_permanent ]; then
		echo "jail_maint_utils__create_permanent was called on $jail_name but it
has already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "jail_maint_utils__create_permanent was called on $jail_name but that
jail does not exist."
		return 1
	fi

	user_maint_utils__add_jail_group "$jail_name" permanent

	gid="`user_maint_utils__return_gid permanent /usr/shew/jails/"$jail_name"`"

	mkdir -p /usr/shew/jails/"$jail_name"/usr/shew/permanent
	chown root:"$gid" /usr/shew/jails/"$jail_name"/usr/shew/permanent
	chmod 0750 /usr/shew/jails/"$jail_name"/usr/shew/permanent

	if [ ! -d /usr/shew/install/done/"$jail_name" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"
		chmod 0700 /usr/shew/install/done/"$jail_name"
	fi

	touch /usr/shew/install/done/"$jail_name"/jail_maint_utils__create_permanent
}

jail_maint_utils__create_sensitive() {
	# This function will prepare the /usr/shew/sensitive directory of a jail for
	# use. This directory is meant to contain program or user specific files which
	# are changed during use and need to persist through reboots. An example file
	# is favorites for Firefox, and would normally be linked to from home by
	# symbolic links with schg flags. If this task has already been done, the
	# function complains and returns true.

	jail_name="$1"

	if [ -f /usr/shew/install/done/"$jail_name"/jail_maint_utils__create_sensitive ]; then
		echo "jail_maint_utils__create_sensitive was called on $jail_name but it
has already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "jail_maint_utils__create_sensitive was called on $jail_name but that
jail does not exist."
		return 1
	fi

	user_maint_utils__add_jail_group "$jail_name" sensitive

	gid="`user_maint_utils__return_gid sensitive /usr/shew/jails/"$jail_name"`"

	mkdir -p \
		/usr/shew/sensitive/"$jail_name" \
		/usr/shew/jails/"$jail_name"/usr/shew/sensitive
	chown root:"$gid" /usr/shew/sensitive/"$jail_name"
	chroot /usr/shew/jails/"$jail_name" \
		chown root:sensitive /usr/shew/sensitive
	chmod 0750 \
		/usr/shew/sensitive/"$jail_name" \
		/usr/shew/jails/"$jail_name"/usr/shew/sensitive

	misc_utils__add_clause /etc/fstab "# Added by jail_maint_utils__create_jail for ${jail_name}:" \
		"/usr/shew/sensitive/${jail_name} /usr/shew/jails/${jail_name}/usr/shew/sensitive nullfs rw,noatime 0 0"

	mount /usr/shew/jails/${jail_name}/usr/shew/sensitive

	if [ ! -d /usr/shew/install/done/"$jail_name" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"
		chmod 0700 /usr/shew/install/done/"$jail_name"
	fi

	touch /usr/shew/install/done/"$jail_name"/jail_maint_utils__create_sensitive
}

jail_maint_utils__allow_telnet() {
	# This function configures a jail for use with telnet. inetd is configured to
	# start when the jail starts, and pf is configured to allow this traffic.
	# Normally jail_maint_utils__setup_program_telnet is run to configure specific
	# programs so they can be run from the host system by telnet. This should not
	# be used for external logins, sshd should be used instead. If this task has
	# already been done, the function complains and returns true.

	jail_name="$1"

	if [ -f /usr/shew/install/done/"$jail_name"/jail_maint_utils__allow_telnet ]; then
		echo "jail_maint_utils__allow_telnet was called on $jail_name but it has
already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "jail_maint_utils__allow_telnet was called on $jail_name but that jail
does not exist."
		return 1
	fi

	misc_utils__change_var /usr/shew/jails/"$jail_name"/etc/rc.conf inetd_enable YES

	if [ ! -f /usr/shew/jails/"$jail_name"/usr/libexec/telnetd ]; then
		mkdir -p /usr/shew/jails/"$jail_name"/usr/libexec
		cp -f /usr/libexec/telnetd /usr/shew/jails/"$jail_name"/usr/libexec/telnetd
	fi

	echo "telnet stream tcp4 nowait/10/10 root /usr/libexec/telnetd telnetd -a none -h" \
		> /usr/shew/jails/"$jail_name"/etc/inetd.conf
	chmod 0400 /usr/shew/jails/"$jail_name"/etc/inetd.conf

	jail_ip="`jail_maint_utils__return_jail_ip "$jail_name"`"

	misc_utils__add_clause /etc/pf.conf '## Pass Jails:' \
		"# Added by jail_maint_utils__allow_telnet for ${jail_name}:\\
		pass quick inet proto tcp from 127.0.0.1 to $jail_ip port 23\\
		pass quick inet proto tcp from $jail_ip to 127.0.0.1 port 23"
	pfctl -f /etc/pf.conf

	if [ ! -d /usr/shew/install/done/"$jail_name" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"
		chmod 0700 /usr/shew/install/done/"$jail_name"
	fi

	touch /usr/shew/install/done/"$jail_name"/jail_maint_utils__allow_telnet
}

jail_maint_utils__allow_x() {
	# This function configures a jail for use with x. pf is configured to allow
	# this traffic. WARNING: Unless a method is found to substantially increase the
	# security of xorg, using this function or installing xorg will dramatically
	# decrease security as xorg has a large surface area for attack. If this task
	# has already been done, the function complains and returns true.

	jail_name="$1"

	if [ -f /usr/shew/install/done/"$jail_name"/jail_maint_utils__allow_x ]; then
		echo "jail_maint_utils__allow_x was called on $jail_name but it has already
been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "jail_maint_utils__allow_x was called on $jail_name but that jail does
not exist."
		return 1
	fi

	jail_ip="`jail_maint_utils__return_jail_ip "$jail_name"`"

	misc_utils__add_clause /etc/pf.conf '## Pass Jails:' \
		"# Added by jail_maint_utils__allow_x for ${jail_name}:\\
		pass quick inet proto tcp from $jail_ip to $jail_ip port 6000"
	pfctl -f /etc/pf.conf

	if [ ! -d /usr/shew/install/done/"$jail_name" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"
		chmod 0700 /usr/shew/install/done/"$jail_name"
	fi

	touch /usr/shew/install/done/"$jail_name"/jail_maint_utils__allow_x
}

jail_maint_utils__allow_sound() {
	# This function configures a jail for use with sound output and recording.
	# WARNING: If you unmute recording, any program in the sound group can record you
	# from your microphone! If this task has already been done, the function
	# complains and returns true.

	jail_name="$1"

	if [ -f /usr/shew/install/done/"$jail_name"/jail_maint_utils__allow_sound ]; then
		echo "jail_maint_utils__allow_sound was called on $jail_name but it has
already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "jail_maint_utils__allow_sound was called on $jail_name but that jail
does not exist."
		return 1
	fi

	if
		pw groupshow sound \
			> /dev/null \
			2> /dev/null
	then
		gid="`user_maint_utils__return_gid sound`"
	else
		gid="`user_maint_utils__generate_unique_gid`"
		pw groupadd -n sound -g "$gid"

		if
			cat /etc/devfs.rules \
				| grep '^\[.*=[0-9]*\]$' \
				> /dev/null
		then
			rule_number='5'
			while
				cat /etc/devfs.rules \
					| grep "^\[.*=${rule_number}\]$" \
					> /dev/null
			do
				rule_number="`expr "$rule_number" + 1`"
			done
		else
			rule_number='5'
		fi

		echo "
[devfsrules_snd_jail=${rule_number}]
add include \$devfsrules_hide_all
add include \$devfsrules_unhide_basic
add include \$devfsrules_unhide_login
add path 'audio*' unhide mode 0660 group sound
add path 'dsp*' unhide mode 0660 group sound
add path speaker unhide mode 0660 group sound
" >> /etc/devfs.rules
	fi

	if !
		chroot /usr/shew/jails/"$jail_name" \
			pw groupshow sound \
			> /dev/null \
			2> /dev/null
	then
		chroot /usr/shew/jails/"$jail_name" \
			pw groupadd -n sound -g "$gid"
	fi

	misc_utils__change_var /etc/rc.conf "jail_${jail_name}_devfs_ruleset" devfsrules_snd_jail

	if [ ! -d /usr/shew/install/done/"$jail_name" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"
		chmod 0700 /usr/shew/install/done/"$jail_name"
	fi

	touch /usr/shew/install/done/"$jail_name"/jail_maint_utils__allow_sound
}

jail_maint_utils__setup_program_telnet() {
	# This function configures telnet for use by a specific user or program. It
	# adds the user password to a file accessed by scripts that talk to the jail's
	# telnetd. jail_maint_utils__allow_telnet must have been run for this to work.
	# If this task has already been done, the function complains and returns true.

	jail_name="$1"
	user="$2"
	password="$3"

	if [ -f /usr/shew/install/done/"$jail_name"/"$user"/jail_maint_utils__setup_program_telnet ]; then
		echo "jail_maint_utils__setup_program_telnet was called on $jail_name with
user $user but it has already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "jail_maint_utils__setup_program_telnet was called on $jail_name but
that jail does not exist."
		return 1
	fi

	if !
		chroot /usr/shew/jails/"$jail_name" \
			pw usershow "$user" \
			> /dev/null \
			2> /dev/null
	then
		echo "jail_maint_utils__setup_program_telnet was called with user $user but that
user does not exist in jail ${jail_name}."
		return 1
	fi

	user_maint_utils__add_group login_jail

	if [ ! -d /usr/shew/login_jail ]; then
		mkdir -p /usr/shew/login_jail
		chown root:login_jail /usr/shew/login_jail
		chmod 0750 /usr/shew/login_jail
	fi

	echo "${user}_password=\"$password\"" \
		>> /usr/shew/login_jail/"$jail_name"_pass.conf
	chmod 0750 /usr/shew/login_jail/"$jail_name"_pass.conf

	if [ ! -d /usr/shew/install/done/"$jail_name"/"$user" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"/"$user"
		chmod 0700 /usr/shew/install/done/"$jail_name"/"$user"
	fi

	touch /usr/shew/install/done/"$jail_name"/"$user"/jail_maint_utils__setup_program_telnet
}

jail_maint_utils__setup_program_desktop() {
	# This function configures desktop files so that an icon can be used to call a
	# specific program in a jail. jail_maint_utils__allow_telnet and
	# jail_maint_utils__setup_program_telnet must have been run for this to work.

	jail_name="$1"
	user="$2"
	icon="$3"
	jail_command="$4"

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "jail_maint_utils__setup_program_desktop was called on $jail_name but
that jail does not exist."
		return 1
	fi

	if !
		chroot /usr/shew/jails/"$jail_name" \
			pw usershow "$user" \
			> /dev/null \
			2> /dev/null
	then
		echo "jail_maint_utils__setup_program_desktop was called with user $user but
that user does not exist in jail ${jail_name}."
		return 1
	fi

	if
		echo "$icon" \
			| grep '^/' \
			> /dev/null
	then
		if [ ! -f "$icon" ]; then
			echo "jail_maint_utils__setup_program_desktop was called with icon:
	$icon
but that icon does not exist."
			return 1
		fi
	fi

	if [ ! -f /usr/shew/copy_to_mfs/home/guest/.config/xfce4/panel/shewstring_desktop.menu ]; then
		echo 'jail_maint_utils__setup_program_desktop was called, but shewstring_desktop.menu
does not exist. The window manager needs to be installed first.'
		return 1
	elif !
		cat /usr/shew/copy_to_mfs/home/guest/.config/xfce4/panel/shewstring_desktop.menu \
			| grep "<!-- Added by jail_maint_utils__setup_program_desktop for $jail_name -->" \
			> /dev/null
	then
		misc_utils__add_clause /usr/shew/copy_to_mfs/home/guest/.config/xfce4/panel/shewstring_desktop.menu \
			'<!-- Additional Menus -->' \
			"<!-- Added by jail_maint_utils__setup_program_desktop for $jail_name -->\\
			<Menu>\\
			<Name>${jail_name}</Name>\\
			<Directory>${jail_name}.directory</Directory>\\
			<Include><Category>${jail_name}</Category></Include>\\
			</Menu>"
	fi

	if [ ! -f /usr/local/share/desktop-directories/"${jail_name}.directory" ]; then
		mkdir -p /usr/local/share/desktop-directories
		echo "[Desktop Entry]
Name=$jail_name
Icon=folder
" > /usr/local/share/desktop-directories/"${jail_name}.directory"
		chmod 0444 /usr/local/share/desktop-directories/"${jail_name}.directory"
	fi

	if [ ! -d /usr/local/share/applications ]; then
		mkdir -p /usr/local/share/applications
	fi

	echo "[Desktop Entry]
Name=$user
Icon=$icon
Exec=sh -eu /usr/shew/login_jail/login.sh \"${jail_name}\" \"${user}\" \"${jail_command}\"
Terminal=false
Type=Application
Categories=$jail_name
" > /usr/local/share/applications/"${jail_name}_${user}.desktop"
	chmod 0444 /usr/local/share/applications/"${jail_name}_${user}.desktop"
}

jail_maint_utils__lockdown_jail() {
	# This function lightens and locks down an installed jail. All users are
	# locked, most unnecessary utilites are deleted, and some /etc files are made
	# only readable by root. Since all users are locked, this should be done right
	# after creating the jail, so that users created by install programs are not
	# then locked. If this task has already been done, the function complains and
	# returns true.

	jail_name="$1"

	if [ -f /usr/shew/install/done/"$jail_name"/jail_maint_utils__lockdown_jail ]; then
		echo "jail_maint_utils__lockdown_jail was called on $jail_name but it has
already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "jail_maint_utils__lockdown_jail was called on $jail_name but that
jail does not exist."
		return 1
	fi

	for val in \
		`
			chroot /usr/shew/jails/"$jail_name" \
				cat /etc/master.passwd \
				| grep -v '^#' \
				| grep -v '\*LOCKED\*' \
				| sed 's/:.*//'
			# master.passwd is used instead of passwd because passwd does not show whether
			# users are locked.
		`
	do
		chroot /usr/shew/jails/"$jail_name" \
			pw lock "$val"
	done

	for val in \
		chio		chflags		df		kenv		rmail		\
		setfacl		\
		\
		adjkerntz	atacontrol	atmconfig	badsect		bsdlabel	\
		camcontrol	ccdconfig	clri		comcontrol	conscontrol	\
		ddb		devd		devfs		dhclient	dhclient-script	\
		disklabel	dmesg		dump		dumpfs		dumpon		\
		fastboot	fasthalt	fdisk		ffsinfo		fsck		\
		fsck_4.2bsd	fsck_ffs	fsck_msdosfs	fsck_ufs	fsdb		\
		fsirand		gbde		gcache		gconcat		geli		\
		geom		ggatec		ggated		ggatel		gjournal	\
		glabel		gmirror		gmultipath	gnop		gpart		\
		graid3		growfs		gshsec		gstripe		gvinum		\
		gvirstor	halt		ifconfig	ipf		ipfs		\
		ipfstat		ipftest		ipfw		ipmon		ipnat		\
		ippool		ipresend	iscontrol	kldconfig	kldload		\
		kldstat		kldunload	mdconfig	mdmfs				\
		mknod		mksnap_ffs	mount		mount_cd9660	mount_mfs	\
		mount_msdosfs	mount_newnfs	mount_nfs	mount_ntfs	mount_nullfs	\
		mount_udf	mount_unionfs	natd		newfs		newfs_msdos	\
		nextboot	nfsiod		nos-tun		pfctl				\
		pflogd		ping		ping6		quotacheck	rdump		\
		reboot		recoverdisk	restore		route		routed		\
		rrestore	rtquery		rtsol		savecore	sconfig		\
		setkey		shutdown	spppcontrol	swapctl		swapoff		\
		swapon		tunefs		umount		zfs				\
		zpool										\
		\
		at		batch		atq		atrm		bthost		\
		btsockstat	crontab		\
		fstat		gcore		kdump		kgdb		ktrace		\
		ktrdump		last		lastcomm	lock		lpq		\
		lpr		lprm		netstat		opieinfo	opiepasswd	\
		truss		uname		usbhidaction					\
		usbhidctl	wall		users		write				\
		\
		IPXrouted	acpiconf	acpidb		acpidump	amd		\
		amq		ancontrol	apm		apmd		arp		\
		asf		audit		auditd		auditreduce	authpf		\
		bcmfw		boot0cfg	bootparamd	bootpef		bootptest	\
		bsnmpd		bt3cfw		bthidcontrol	bthidd		btpand		\
		btxld		burncd		cdcontrol	chkprintcap	cpucontrol	\
		crashinfo	cron		dconschat	devinfo		digictl		\
		diskinfo	dtrace		faithd		fdcontrol	fdformat	\
		fdread		fdwrite		fixmount	flowctl		freebsd-update	\
		fsinfo		ftp-proxy	fwcontrol	gssd		gstat		\
		hccontrol	hcsecd		hcseriald	hlfsd		hostapd		\
		hostapd_cli	i2c		ifmcstat	iostat		ip6addrctl	\
		ipfwpcap	jail		jexec		jls		kbdcontrol	\
		kgmon		kldxref		lastlogin	lmcconfig	lpc		\
		lpd		lptcontrol	lwresd		memcontrol	mergemaster	\
		mfiutil		mixer		mk-amd-map	mlxcontrol	mount_nwfs	\
		mount_portalfs	mount_smbfs	mountd		moused		mptable		\
		mptutil		named		named-checkconf	named-checkzone	named-compilezone	\
		named.reconfig	named.reload	ndis_events	ndiscvt		ndp		\
		nfscbd		nfsd		nfsdumpstate	nfsuserd			\
		nscd		ntp-keygen	ntpd		ntpdate		ntpdc		\
		ntptime		ntptrace	pciconf						\
		pmccontrol	powerd		ppp		pppctl		pstat		\
		quot		quotaon		quotaoff	rarpd		repquota	\
		rfcomm_pppd	rmt		route6d		rpc.lockd	rpc.statd	\
		rpc.umntall	rpc.yppasswdd	rpc.ypxfrd	rpcbind		rrenumd		\
		rtadvd		rtsol		rtsold		rwhod		sa		\
		sade		sdpd		sicontrol	smbmsg		snapinfo	\
		sshd		swapinfo	sysinstall	tcpdrop				\
		tcpdump		timed		timedc		traceroute	traceroute6	\
		trpt		tzsetup		uathload	ugidfw		vidcontrol	\
		vidfont		watch		watchdogd	wire-test	wlandebug	\
		wlconfig	wpa_cli		wpa_supplicant	ypbind		ypserv		\
		zdb		zzz
	do
		for val2 in \
				/bin/		/sbin/		/rescue/	/usr/bin/	/usr/sbin/
		do
			if [ -f /usr/shew/jails/"$jail_name"/"${val2}$val" ]; then
				chflags noschg /usr/shew/jails/"$jail_name"/"${val2}$val"
				rm -f /usr/shew/jails/"$jail_name"/"${val2}$val"

				echo '#!/bin/sh
echo "$0 has been replaced by a dummy script." >&2
return 0
' > /usr/shew/jails/"$jail_name"/"${val2}$val"

				chmod 0555 /usr/shew/jails/"$jail_name"/"${val2}$val"
				chflags schg /usr/shew/jails/"$jail_name"/"${val2}$val"
			fi
		done
	done

	for val in \
		/usr/shew/jails/"$jail_name"/sbin/sysctl
	do
		chflags noschg "$val"
		chmod 0500 "$val"
	done

	chflags -R noschg /usr/shew/jails/"$jail_name"/usr/libexec
	rm -Rf /usr/shew/jails/"$jail_name"/usr/libexec
	mkdir -p /usr/shew/jails/"$jail_name"/usr/libexec
	cp -f /usr/libexec/ld-elf.so.1 /usr/shew/jails/"$jail_name"/usr/libexec

	for val in \
		/etc/auth.conf		/etc/devd.conf		/etc/devfs.conf		\
		/etc/dhclient.conf	/etc/pf.conf		/etc/inetd.conf		\
		/etc/rc.conf		/etc/sysctl.conf	/etc/mac.conf		\
		/etc/syslog.conf	/etc/rc.sysctl		/etc/crontab		\
		/etc/fstab		/etc/hosts.allow	/etc/login.access	\
		/etc/master.passwd	/etc/periodic/		/etc/spwd.db		\
		/etc/ttys
	do
		if [ -f /usr/shew/jails/"$jail_name"/"$val" ]; then
			chmod -R 0600 /usr/shew/jails/"$jail_name"/"$val"
			chflags -R opaque /usr/shew/jails/"$jail_name"/"$val"
		fi
	done

	chmod 0644 /etc/login.conf
		# This undoes an undesired chmod from '*.conf'.

	if [ ! -d /usr/shew/install/done/"$jail_name" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"
		chmod 0700 /usr/shew/install/done/"$jail_name"
	fi

	touch /usr/shew/install/done/"$jail_name"/jail_maint_utils__lockdown_jail
}
