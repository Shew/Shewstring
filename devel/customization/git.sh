#!/bin/sh

# For working with Shewstring using git.

. /usr/shew/install/shewstring/lib/misc_utils.sh
. /usr/shew/install/shewstring/lib/jail_maint_utils.sh
. /usr/shew/install/shewstring/lib/ports_pkgs_utils.sh
. /usr/shew/install/shewstring/lib/user_maint_utils.sh

ports_pkgs_utils__configure_port git
ports_pkgs_utils__install_pkg git
ports_pkgs_utils__install_pkg git /usr/shew/jails/tor_pseudonym_2
