#!/bin/sh

# Contents:	x_login__install_login

# Variable defaults:
  : ${x_login__login_script="/usr/shew/install/shewstring/libexec/x/misc/login.sh"}
									# This file is the default location for login.sh.

x_login__install_login() {
	# This function will install login.sh, which logs in to a jail and starts a x
	# program and then exits. It is usually run by the window manager using desktop
	# entries created by jail_maint_utils__setup_program_desktop. The passwords for
	# the user login are obtained from
	# /usr/shew/login_jail/"$jail_name"_passwords.config and are usually added by
	# jail_maint_utils__setup_program_telnet; they take the form of variable
	# declarations. If this task has already been done, the function complains and
	# returns true.

	if [ -f /usr/shew/install/done/x_login__install_login ]; then
		echo "x_login__install_login was called but it has already been run, skipping."
		return 0
	fi

	if [ ! -f "$x_login__login_script" ]; then
		echo "x_login__install_login could not find a critical install file. It should be:
	$x_login__login_script"
		return 1
	fi

	user_maint_utils__add_group login_jail

	mkdir -p /usr/shew/login_jail

	cp -f "$x_login__login_script" /usr/shew/login_jail/login.sh

	chown -R root:login_jail /usr/shew/login_jail
	chmod -R 0550 /usr/shew/login_jail

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/x_login__install_login
}
