#!/bin/sh

# This script will perform a basic install of things contained within the x
# scripts. The default settings should be fine for most installers.

# Libraries:
  . /usr/shew/install/shewstring/lib/misc_utils.sh
  . /usr/shew/install/shewstring/lib/jail_maint_utils.sh
  . /usr/shew/install/shewstring/lib/user_maint_utils.sh
  . /usr/shew/install/shewstring/lib/ports_pkgs_utils.sh
  . /usr/shew/install/shewstring/libexec/x/xorg.sh
  . /usr/shew/install/shewstring/libexec/x/login.sh

# Execute:

echo
shew__current_script='libexec/x/exec.sh'
misc_utils__echo_progress

misc_utils__save_progress \
	&& {
		echo '
Installing Xorg, which provides access to the display and input devices to
graphical programs.'
		misc_utils__prompt_continue

		echo
		x_xorg__install_xorg
	}

misc_utils__save_progress \
	&& {
		echo '
Installing Xterm, which provides a graphical command line interface.'
		misc_utils__prompt_continue

		echo
		x_xorg__install_xterm
	}

misc_utils__save_progress \
	&& {
		echo '
Installing Xkill, which can be used to shut down frozen graphical programs.'
		misc_utils__prompt_continue

		echo
		x_xorg__install_xkill
	}

misc_utils__save_progress \
	&& {
		echo '
Installing XDM, which manages Xorg and provides a graphical login.'
		misc_utils__prompt_continue

		echo
		x_xorg__install_xdm
	}

misc_utils__save_progress \
	&& {
		echo '
Configuring login script, which logs in to a jail and starts a x program and
then exits.'
		misc_utils__prompt_continue

		echo

		x_login__install_login

		grouplist="`user_maint_utils__return_grouplist guest`"
		pw usermod -n guest -G "${grouplist},login_jail"
	}
