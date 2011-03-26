#!/bin/sh

# This script will log in to a jail using telnet and start a x program and then
# exit. It is usually run by the window manager using desktop entries created
# by jail_maint_utils__setup_program_desktop. The passwords for the user login
# are obtained from /usr/shew/login_jail/"${jail_name}_pass.conf" and are
# usually added by jail_maint_utils__setup_program_telnet; they take the form
# of variable declarations.

# Arguments:
  jail_name="$1"
  user="$2"
  jail_command="$3"

# Execute:

jail_ip="`
	grep -m 1 "$jail_name ${jail_name}.my.domain *$" /etc/hosts \
		| sed "s/${jail_name}.*//"
	# Normally this would be a simpler string of single commands, but this should
	# be faster.
`"

. /usr/shew/login_jail/"${jail_name}_pass.conf"

password="`eval "echo \$\"${user}_password\"`"

{
	sleep 0.8

	echo "$user"

	sleep 0.2

	echo "$password"

	echo 'export DISPLAY=127.0.0.1:0.0'
	echo "$jail_command >> ~/login.log 2>> ~/login.log &"

	sleep 10

	echo 'exit'

	sleep 1
} \
	| nc -tn -s 127.0.0.1 "$jail_ip" 23
