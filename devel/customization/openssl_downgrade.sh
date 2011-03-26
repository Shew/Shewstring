#!/bin/sh

# This script, and the makefiles folder, will dowgrade OpenSSL to the 9.x
# branch so that Vidalia will work with it. WARNING: The 9.x branch is
# unmaintained on FreeBSD and it contains many security vulnerabilities! Use
# only for testing!

. /usr/shew/install/shewstring/lib/misc_utils.sh
. /usr/shew/install/shewstring/lib/jail_maint_utils.sh
. /usr/shew/install/shewstring/lib/ports_pkgs_utils.sh
. /usr/shew/install/shewstring/lib/user_maint_utils.sh

rm -f /usr/shew/jails/compile/var/db/portaudit/auditfile.tbz
	# Portaudit woln't let vulnurable versions be installed.

package_name="`
	chroot /usr/shew/jails/compile \
		pkg_info \
		| grep '^openssl-' \
		| sed 's/ .*//'
	`"

chroot /usr/shew/jails/compile pkg_delete -f "$package_name"
chroot /usr/shew/jails/nat_darknets pkg_delete -f "$package_name"

rm -f /usr/shew/jails/compile/usr/ports/packages/*/openssl*

mv /usr/shew/jails/compile/usr/ports/security/openssl /usr/shew/jails/compile/usr/ports/security/openssl-old

cp -Rf /usr/shew/install/shewstring/installers/Shewstring_Desktop/customization/makefiles/openssl \
	/usr/shew/jails/compile/usr/ports/security/openssl

ports_pkgs_utils__configure_port openssl
echo 'i' \
	| ports_pkgs_utils__install_pkg openssl /usr/shew/jails/nat_darknets
# For some reason, make tries to build the package and fails, this ignores the failure.

package_name="`
	chroot /usr/shew/jails/compile \
		pkg_info \
		| grep '^openssl-' \
		| sed 's/ .*//'
	`"

chroot /usr/shew/jails/compile pkg_delete -f "$package_name"

rm -Rf \
	/usr/shew/jails/compile/usr/ports/security/openssl \
	/usr/shew/jails/compile/usr/ports/packages/*/openssl*

mv /usr/shew/jails/compile/usr/ports/security/openssl-old /usr/shew/jails/compile/usr/ports/security/openssl
