#!/bin/sh

# This script will enable do some final security tweaks.

# Libraries:
  . /usr/shew/install/shewstring/lib/misc_utils.sh
  . /usr/shew/install/shewstring/lib/jail_maint_utils.sh
  . /usr/shew/install/shewstring/lib/ports_pkgs_utils.sh
  . /usr/shew/install/shewstring/lib/user_maint_utils.sh
  . /usr/shew/install/shewstring/libexec/lockdown/ttys.sh
  . /usr/shew/install/shewstring/libexec/lockdown/restrict_files.sh
  . /usr/shew/install/shewstring/libexec/lockdown/securelevel.sh
  . /usr/shew/install/shewstring/libexec/lockdown/portaudit.sh

# Execute:

echo
shew__current_script='libexec/lockdown/exec.sh'
misc_utils__echo_progress

misc_utils__save_progress \
	&& {
		echo '
Securing the ttys file.'
		misc_utils__prompt_continue

		echo
		lockdown_ttys__secure_ttys
	}

misc_utils__save_progress \
	&& {
		echo '
Securing the /etc files.'
		misc_utils__prompt_continue

		echo
		lockdown_restrict_files__restrict_etc
	}

misc_utils__save_progress \
	&& {
		echo '
Securing the suid and sgid binaries.'
		misc_utils__prompt_continue

		echo
		lockdown_restrict_files__suid_sgid
	}

misc_utils__save_progress \
	&& {
		echo '
Setting the securelevel to raise to 3 after booting.'
		misc_utils__prompt_continue

		echo
		lockdown_securelevel__boot_raise_securelevel
	}

misc_utils__save_progress \
	&& {
		echo '
Auditing all ports for vulnerabilities.'
		misc_utils__prompt_continue

		echo
		lockdown_portaudit__install_portaudit
		lockdown_portaudit__print_full_audit
	}
