#!/bin/sh

# Contents:	user_maint_utils__generate_unique_gid
#		user_maint_utils__generate_unique_uid
#		user_maint_utils__return_gid
#		user_maint_utils__return_uid
#		user_maint_utils__return_grouplist
#		user_maint_utils__add_group
#		user_maint_utils__add_user
#		user_maint_utils__add_jail_group
#		user_maint_utils__add_jail_user

user_maint_utils__generate_unique_gid() {
	# This function will generate a random group id that is not used by the host or
	# by any jail. This is needed because normal user and group creation is
	# ignorant of users and groups in filesystem hierarchies rooted in another
	# location (e.g. an adjacent jail), and thus id collisions can occur. This
	# prevents that by superceding the normal user and group id creation by pw.

	gid="`jot -r 1 1001 65532`"

	while
		{
			cat /etc/group

			if
				ls /usr/shew/jails/*/etc/group \
					> /dev/null \
					2> /dev/null
				# This protects the loop from having no existent jails.
			then
				for val in /usr/shew/jails/*/etc/group; do
					cat "$val"
				done
			fi
		} \
			| grep ".*:\*:${gid}:" \
			> /dev/null
	do
		gid="`jot -r 1 1001 65532`"
	done

	echo "$gid"
}

user_maint_utils__generate_unique_uid() {
	# This function will generate a random user id that is not used by the host or
	# by any jail. This is needed because normal user and group creation is
	# ignorant of users and groups in filesystem hierarchies rooted in another
	# location (e.g. an adjacent jail), and thus id collisions can occur. This
	# prevents that by superceding the normal user and group id creation by pw.

	uid="`jot -r 1 1001 65532`"

	while
		{
			cat /etc/passwd

			if
				ls /usr/shew/jails/*/etc/passwd \
					> /dev/null \
					2> /dev/null
				# This protects the loop from having no existent jails.
			then
				for val in /usr/shew/jails/*/etc/group; do
					cat "$val"
				done
			fi
		} \
			| grep ".*:\*:${uid}:[0-9]*:.*:.*:.*" \
			> /dev/null
	do
		uid="`jot -r 1 1001 65532`"
	done

	echo "$uid"
}

user_maint_utils__return_gid() {
	# This function will return the group ID in a given chroot.

	group="$1"
	chroot="${2:-/}"

	if [ ! -f "$chroot"/etc/group ]; then
		return 1
	fi

	cat "$chroot"/etc/group \
		| grep "${group}:\*:[0-9]*:" \
		| tail -n 1 \
		| sed 's/.*:\*://' \
		| sed 's/:.*//'
}

user_maint_utils__return_uid() {
	# This function will return the user ID in a given chroot.

	user="$1"
	chroot="${2:-/}"

	if [ ! -f "$chroot"/etc/passwd ]; then
		return 1
	fi

	cat "$chroot"/etc/passwd \
		| grep "${user}:\*:[0-9]*:[0-9]*:" \
		| tail -n 1 \
		| sed 's/.*:\*://' \
		| sed 's/:.*//'
}

user_maint_utils__return_grouplist() {
	# This function will return the list of groups a user belongs to, comma 
	# formatted for pw.

	user="$1"
	chroot="${2:-/}"

	if [ ! -f "$chroot"/etc/group ]; then
		return 1
	fi

	groups="`
		cat "$chroot"/etc/group \
			| grep "^.*:\*:[0-9]*:.*${user}" \
			| sed 's/:.*//'
	`"

	grouplist=''
	for val in $groups; do
		if [ "$grouplist" ]; then
			grouplist="${grouplist},$val"
		else
			grouplist="$val"
		fi
	done

	echo "$grouplist"
}

user_maint_utils__add_group() {
	# This function will add a group with a unique id to the host system. If this
	# task has already been done, the function complains and returns true.

	group="$1"

	if
		pw groupshow "$group" \
			> /dev/null \
			2> /dev/null
	then
		echo "user_maint_utils__add_group was called on $group but that group already
exists, skipping."
		return 0
	fi

	gid="`user_maint_utils__generate_unique_gid`"

	pw groupadd -n "$group" -g "$gid"
}

user_maint_utils__add_user() {
	# This function will add a user to the host system, and create any associated
	# groups. The home folder and any user specific files will be locked down. If
	# the user already exists, the function will attempt to set everything
	# correctly. If $password is set to 'none', no password will be set. If the
	# groups data, home, permanent, or sensitive are given, folders for the user
	# will be created in those special directories.

	user="$1"
	password="$2"
	shift 2
	groups="${@:-}"

	for val in $user $groups; do
		if !
			pw groupshow "$val" \
				> /dev/null \
				2> /dev/null
		then
			user_maint_utils__add_group "$val"
		fi
	done

	if
		pw usershow "$user" \
			> /dev/null \
			2> /dev/null
	then
		pw usermod -n "$user" -g "$user" -G "$groups" -d /nonexistent -s sh
	else
		uid="`user_maint_utils__generate_unique_uid`"

		pw useradd -n "$user" -u "$uid" -g "$user" -G "$groups" -d /nonexistent -s sh
	fi

	if [ "$password" != none ]; then
		echo "$password" \
			| pw usermod -n "$user" -h 0
	fi

	if
		echo "$groups" \
			| grep -e ' data ' -e '^data ' -e ' data$' -e '^data$' \
			> /dev/null
	then
		mkdir -p /usr/shew/data/host/"$user"
		chown "${user}:$user" /usr/shew/data/host/"$user"
		chmod 0750 /usr/shew/data/host/"$user"
	fi

	if
		echo "$groups" \
			| grep -e ' home ' -e '^home ' -e ' home$' -e '^home$' \
			> /dev/null
	then
		pw usermod -n "$user" -m -d /usr/shew/copy_to_mfs/home/"$user"

		pw usermod -n "$user" -d /home/"$user"

		chmod 0750 /usr/shew/copy_to_mfs/home/"$user"

		for val in \
			/usr/shew/copy_to_mfs/home/"$user"/.cshrc \
			/usr/shew/copy_to_mfs/home/"$user"/.hushlogin \
			/usr/shew/copy_to_mfs/home/"$user"/.login \
			/usr/shew/copy_to_mfs/home/"$user"/.login_conf \
			/usr/shew/copy_to_mfs/home/"$user"/.mail_aliases \
			/usr/shew/copy_to_mfs/home/"$user"/.mailrc \
			/usr/shew/copy_to_mfs/home/"$user"/.profile \
			/usr/shew/copy_to_mfs/home/"$user"/.rhosts \
			/usr/shew/copy_to_mfs/home/"$user"/.shrc
		do
			chflags noschg "$val" \
				> /dev/null \
				2> /dev/null \
				|| true
	
			touch "$val"
			chown "${user}:$user" "$val"
			chmod 0440 "$val"
			chflags schg "$val"
		done

		for val in \
			/usr/shew/copy_to_mfs/home/"$user"/.history \
			/usr/shew/copy_to_mfs/home/"$user"/.xsession-errors
				# Logging from remote X connections appears in .xsession-errors.
		do
			chflags nosappnd "$val" \
				> /dev/null \
				2> /dev/null \
				|| true
	
			touch "$val"
			chown "${user}:$user" "$val"
			chmod 0640 "$val"
			chflags sappnd "$val"
		done
	fi

	if
		echo "$groups" \
			| grep -e ' permanent ' -e '^permanent ' -e ' permanent$' -e '^permanent$' \
			> /dev/null
	then
		mkdir -p /usr/shew/permanent/"$user"
		chown "${user}:$user" /usr/shew/permanent/"$user"
		chmod 0550 /usr/shew/permanent/"$user"
	fi

	if
		echo "$groups" \
			| grep -e ' sensitive ' -e '^sensitive ' -e ' sensitive$' -e '^sensitive$' \
			> /dev/null
	then
		mkdir -p /usr/shew/sensitive/host/"$user"
		chown "${user}:$user" /usr/shew/sensitive/host/"$user"
		chmod 0750 /usr/shew/sensitive/host/"$user"

		touch /usr/shew/sensitive/host/"${user}.allow"
		chmod 0400 /usr/shew/sensitive/host/"${user}.allow"
		chflags schg,opaque /usr/shew/sensitive/host/"${user}.allow"
	fi

	/etc/rc.d/shew_mfs start
}

user_maint_utils__add_jail_group() {
	# This function will add a group to a jail. Additionally, a copy of the group
	# will be created on the host system, the name prefixed with the jail name,
	# followed by an underscore. This is so that a group with the same gid cannot
	# be created on the host system without first removing this group. If this task
	# has already been done, the function complains and returns true.

	jail_name="$1"
	group="$2"

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "user_maint_utils__add_jail_group was called on $jail_name but that
jail does not exist."
		return 1
	fi

	if
		chroot /usr/shew/jails/"$jail_name" \
			pw groupshow "$group" \
			> /dev/null \
			2> /dev/null
	then
		echo "user_maint_utils__add_group was called on $jail_name with group
$group but that group already exists, skipping."
		return 0
	fi

	gid="`user_maint_utils__generate_unique_gid`"

	pw groupadd -n "$gid" -g "$gid"
		# A locked group is created so that a group with the same gid cannot be created
		# in the host system. FreeBSD determines permissions by gid, so a group with
		# the same gid could access files in one of the jails that they are not the
		# owner of.

	chroot /usr/shew/jails/"$jail_name" \
		pw groupadd -n "$group" -g "$gid"
}

user_maint_utils__add_jail_user() {
	# This function will add a user in a jail, and create any associated groups.
	# The home folder and any user specific files will be locked down. If the user
	# already exists, the function will attempt to set everything correctly. If
	# $password is set to 'none', no password will be set. If the groups data,
	# home, permanent, or sensitive are given, folders for the user will be created
	# in those special directories.

	jail_name="$1"
	user="$2"
	password="$3"
	shift 3
	groups="${@:-}"

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "user_maint_utils__add_jail_user was called on $jail_name but that
jail does not exist."
		return 1
	fi

	for val in $user $groups; do
		if !
			chroot /usr/shew/jails/"$jail_name" \
				pw groupshow "$val" \
				> /dev/null \
				2> /dev/null
		then
			user_maint_utils__add_jail_group "$jail_name" "$val"
		fi
	done

	if
		chroot /usr/shew/jails/"$jail_name" \
			pw usershow "$user" \
			> /dev/null \
			2> /dev/null
	then
		uid="`user_maint_utils__return_uid "$user" /usr/shew/jails/"$jail_name"`"

		pw usermod -u "$uid" -s /sbin/nologin
		pw lock "$uid" \
			|| true
		# This is set to true since the user may already be locked.

		chroot /usr/shew/jails/"$jail_name" \
			pw usermod -n "$user" -g "$user" -G "$groups" -d /nonexistent -s sh
	else
		uid="`user_maint_utils__generate_unique_uid`"

		pw useradd -d /nonexistent -n "$uid" -u "$uid" -s /sbin/nologin
		pw lock "$uid"
			# A locked user is created so that a user with the same uid cannot be created
			# in the host system. FreeBSD determines permissions by uid, so a user with the
			# same uid could access files in one of the jails that they are not the owner
			# of.

		chroot /usr/shew/jails/"$jail_name" \
			pw useradd -n "$user" -u "$uid" -g "$user" -G "$groups" -d /nonexistent -s sh
	fi

	if [ "$password" != none ]; then
		echo "$password" \
			| chroot /usr/shew/jails/"$jail_name" \
			pw usermod -n "$user" -h 0
	fi

	if
		echo "$groups" \
			| grep -e ' data ' -e '^data ' -e ' data$' -e '^data$' \
			> /dev/null
	then
		mkdir -p /usr/shew/jails/"$jail_name"/usr/shew/data/"$user"
		chroot /usr/shew/jails/"$jail_name" \
			chown "${user}:$user" /usr/shew/data/"$user"
		chmod 0750 /usr/shew/jails/"$jail_name"/usr/shew/data/"$user"
	fi

	if
		echo "$groups" \
			| grep -e ' home ' -e '^home ' -e ' home$' -e '^home$' \
			> /dev/null
	then
		chroot /usr/shew/jails/"$jail_name" \
			pw usermod -n "$user" -m -d /usr/shew/copy_to_mfs/home/"$user"

		chroot /usr/shew/jails/"$jail_name" \
			pw usermod -n "$user" -d /home/"$user"

		chmod 0750 /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"

		for val in \
			/usr/shew/copy_to_mfs/home/"$user"/.cshrc \
			/usr/shew/copy_to_mfs/home/"$user"/.hushlogin \
			/usr/shew/copy_to_mfs/home/"$user"/.login \
			/usr/shew/copy_to_mfs/home/"$user"/.login_conf \
			/usr/shew/copy_to_mfs/home/"$user"/.mail_aliases \
			/usr/shew/copy_to_mfs/home/"$user"/.mailrc \
			/usr/shew/copy_to_mfs/home/"$user"/.profile \
			/usr/shew/copy_to_mfs/home/"$user"/.rhosts \
			/usr/shew/copy_to_mfs/home/"$user"/.shrc
		do
			chflags noschg /usr/shew/jails/"$jail_name"/"$val" \
				> /dev/null \
				2> /dev/null \
				|| true
	
			touch /usr/shew/jails/"$jail_name"/"$val"
			chmod 0440 /usr/shew/jails/"$jail_name"/"$val"
			chroot /usr/shew/jails/"$jail_name" \
				chown "${user}:$user" "$val"
			chflags schg /usr/shew/jails/"$jail_name"/"$val"
		done

		for val in \
			/usr/shew/copy_to_mfs/home/"$user"/.history
		do
			chflags nosappnd /usr/shew/jails/"$jail_name"/"$val" \
				> /dev/null \
				2> /dev/null \
				|| true
	
			touch /usr/shew/jails/"$jail_name"/"$val"
			chmod 0640 /usr/shew/jails/"$jail_name"/"$val"
			chroot /usr/shew/jails/"$jail_name" \
				chown "${user}:$user" "$val"
			chflags sappnd /usr/shew/jails/"$jail_name"/"$val"
		done
	fi

	if
		echo "$groups" \
			| grep -e ' permanent ' -e '^permanent ' -e ' permanent$' -e '^permanent$' \
			> /dev/null
	then
		mkdir -p /usr/shew/jails/"$jail_name"/usr/shew/permanent/"$user"
		chroot /usr/shew/jails/"$jail_name" \
			chown "${user}:$user" /usr/shew/permanent/"$user"
		chmod 0550 /usr/shew/jails/"$jail_name"/usr/shew/permanent/"$user"
	fi

	if
		echo "$groups" \
			| grep -e ' sensitive ' -e '^sensitive ' -e ' sensitive$' -e '^sensitive$' \
			> /dev/null
	then
		mkdir -p /usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"
		chroot /usr/shew/jails/"$jail_name" \
			chown "${user}:$user" /usr/shew/sensitive/"$user"
		chmod 0750 /usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"

		touch /usr/shew/jails/"$jail_name"/usr/shew/sensitive/"${user}.allow"
		chmod 0400 /usr/shew/jails/"$jail_name"/usr/shew/sensitive/"${user}.allow"
		chflags schg,opaque /usr/shew/jails/"$jail_name"/usr/shew/sensitive/"${user}.allow"
	fi

	chroot /usr/shew/jails/"$jail_name" \
		/etc/rc.d/shew_mfs start
}
