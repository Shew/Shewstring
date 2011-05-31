#!/bin/sh

# This script will install firefox in a jail, and sets up telnet and a default
# desktop file. If user is not specified, it defaults to firefox. The default
# desktop file may be overwritten with jail_maint_utils__setup_program_desktop.
# The Firefox home page: https://www.mozilla.com/en-US/firefox/ the Torbutton
# home page: https://www.torproject.org/torbutton/ the Gnash home page:
# http://www.gnashdev.org/ the Adblock Plus home page:
# https://adblockplus.org/en/ the NoScript home page:
# http://noscript.net/ the Perspectives home page:
# http://www.cs.cmu.edu/~perspectives/ the Beef Taco home page:
# http://jmhobbs.github.com/beef-taco/ and the HTTPS Everywhere home page:
# https://www.eff.org/https-everywhere/

# Arguments:
  jail_name="$arg_1"
  user="${arg_2:-firefox}"
  unset arg_1 arg_2

# Requires:	lib/misc_utils.sh
#		lib/jail_maint_utils.sh
#		lib/ports_pkgs_utils.sh
#		lib/user_maint_utils.sh

# Contents:	firefox__set_proxy_privoxy
#		firefox__install_gnash
#		firefox__install_adblock
#		firefox__install_https_everywhere
#		firefox__install_noscript
#		firefox__install_perspectives
#		firefox__install_taco

# Variable defaults:
  : ${jailed_x_firefox__apps_folder='/usr/shew/install/shewstring/libexec/jailed_x/apps'}
								# The default jailed_x apps folder.
  : ${jailed_x_firefox__make_folder='/usr/shew/install/shewstring/libexec/jailed_x/makefiles'}
								# The default folder for extra makefiles, this is needed
								# for https_everywhere, perspectives, and taco.
  : ${jailed_x_firefox__home_folder='/usr/shew/install/shewstring/libexec/jailed_x/home/firefox'}
								# The default firefox home folder.
  : ${jailed_x_firefox__gnash_home_folder='/usr/shew/install/shewstring/libexec/jailed_x/home/gnash'}
								# The default Gnash home folder.
  : ${jailed_x_firefox__adblock_configs='/usr/shew/install/shewstring/libexec/jailed_x/misc/adblock'}
								# This file is the default Adblock folder for config files.
  : ${jailed_x_firefox__noscript_configs='/usr/shew/install/shewstring/libexec/jailed_x/misc/noscript'}
								# This file is the default NoScript folder for config files.

# Execute:

if [ -f /usr/shew/install/done/"$jail_name"/"$user"/jailed_x_firefox ]; then
	echo "jailed_x/firefox.sh was called on $jail_name with user $user but it has
already been run, skipping."
		# Normally this would return 0, but then you wouldn't be able to load functions
		# if the script has already been run.
else

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "jailed_x/firefox.sh was called on $jail_name but that jail does not exist."
		return 1
	fi

	if [ ! -d "$jailed_x_firefox__apps_folder" ]; then
		echo "jailed_x/firefox.sh could not find a critical install file. It should be:
	$jailed_x_firefox__apps_folder"
		return 1
	fi

	if [ ! -d "$jailed_x_firefox__home_folder" ]; then
		echo "jailed_x/firefox.sh could not find a critical install file. It should be:
	$jailed_x_firefox__home_folder"
		return 1
	fi

	ports_pkgs_utils__configure_port firefox36 "$jailed_x_firefox__apps_folder"
	ports_pkgs_utils__install_pkg firefox36 /usr/shew/jails/"$jail_name"
	ports_pkgs_utils__configure_port xpi-torbutton "$jailed_x_firefox__apps_folder"
	ports_pkgs_utils__install_pkg xpi-torbutton /usr/shew/jails/"$jail_name"

	cp -f /usr/shew/jails/"$jail_name"/usr/local/lib/firefox3/run-mozilla.sh \
		/usr/shew/jails/"$jail_name"/usr/local/lib/firefox3/run-mozilla.sh.old
	cat /usr/shew/jails/"$jail_name"/usr/local/lib/firefox3/run-mozilla.sh.old \
		| sed 's/uname -s/echo FreeBSD/' \
		> /usr/shew/jails/"$jail_name"/usr/local/lib/firefox3/run-mozilla.sh
	rm -f /usr/shew/jails/"$jail_name"/usr/local/lib/firefox3/run-mozilla.sh.old
		# uname is restricted to root in locked down jails.

	password="`
			dd if=/dev/random count=2 \
				| md5
		`"

	user_maint_utils__add_jail_user "$jail_name" "$user" "$password" data home permanent sensitive

	cp -Rf "$jailed_x_firefox__home_folder" /usr/shew/jails/"$jail_name"/tmp/firefox
	chroot /usr/shew/jails/"$jail_name" \
		chown -R "${user}:$user" /tmp/firefox
	cp -af /usr/shew/jails/"$jail_name"/tmp/firefox/ /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"
	rm -Rf /usr/shew/jails/"$jail_name"/tmp/firefox

	ln -s /usr/local/lib/xpi \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/extensions

	mkdir -p /usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/bookmarkbackups
	chroot /usr/shew/jails/"$jail_name" \
		chown -R "${user}:$user" /usr/shew/sensitive/"$user"/bookmarkbackups
	ln -s \
		/usr/shew/sensitive/"$user"/bookmarkbackups \
		/usr/shew/sensitive/"$user"/cert_override.txt \
		/usr/shew/sensitive/"$user"/places.sqlite \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default
	chmod -h 0444 \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/bookmarkbackups \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/cert_override.txt \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/places.sqlite
	chflags -h schg \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/bookmarkbackups \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/cert_override.txt \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/places.sqlite

	chflags noschg /usr/shew/sensitive/"$jail_name"/"${user}.allow"
	echo 'bookmarkbackups
bookmarkbackups/bookmarks-[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]\.json
cert_override\.txt
places\.sqlite' \
		>> /usr/shew/sensitive/"$jail_name"/"${user}.allow"
	chflags schg /usr/shew/sensitive/"$jail_name"/"${user}.allow"

	jail_maint_utils__setup_program_telnet "$jail_name" "$user" "$password"
	jail_maint_utils__setup_program_desktop "$jail_name" "$user" \
		/usr/shew/jails/"$jail_name"/usr/local/lib/firefox3/chrome/icons/default/default48.png \
		'/usr/local/bin/firefox3 -no-remote'

	if [ ! -d /usr/shew/install/done/"$jail_name"/"$user" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"/"$user"
		chmod 0700 /usr/shew/install/done/"$jail_name"/"$user"
	fi

	touch /usr/shew/install/done/"$jail_name"/"$user"/jailed_x_firefox
fi

# Functions:

firefox__set_proxy_privoxy() {
	# This function will configure firefox to use privoxy.

	jail_name="$1"
	user="${2:-firefox}"

	if [ -f /usr/shew/install/done/"$jail_name"/"$user"/firefox__set_proxy_privoxy ]; then
		echo "firefox__set_proxy_privoxy was called on $jail_name with user $user but it
has already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "firefox__set_proxy_privoxy was called on $jail_name but that jail does not
exist."
		return 1
	fi

	if !
		chroot /usr/shew/jails/"$jail_name" \
			pw usershow "$user" \
			> /dev/null \
			2> /dev/null
	then
		echo "firefox__set_proxy_privoxy was called with, or defaulted to $user but that
user does not exist."
		return 1
	fi

	ip="`jail_maint_utils__return_jail_ip "$jail_name"`"
	privoxy_port="`misc_utils__echo_var /usr/shew/install/resources/ports "${jail_name}_privoxy"`"

	cp -f /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/prefs.js \
		/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/prefs.js.tmp
	cat /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/prefs.js.tmp \
		| sed "s/torbutton.no_proxies_on\", \".*\"/torbutton.no_proxies_on\", \"127.0.0.1, ${ip}\"/" \
		> /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/prefs.js
	rm -f /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/prefs.js.tmp

echo "
// Added by firefox__set_proxy_privoxy for Privoxy:
user_pref(\"extensions.torbutton.custom.http_proxy\", \"${ip}\");
user_pref(\"extensions.torbutton.custom.http_port\", ${privoxy_port});
user_pref(\"extensions.torbutton.custom.https_proxy\", \"${ip}\");
user_pref(\"extensions.torbutton.custom.https_port\", ${privoxy_port});
user_pref(\"extensions.torbutton.http_proxy\", \"${ip}\");
user_pref(\"extensions.torbutton.http_port\", ${privoxy_port});
user_pref(\"extensions.torbutton.https_proxy\", \"${ip}\");
user_pref(\"extensions.torbutton.https_port\", ${privoxy_port});
" >> /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/prefs.js

	if [ ! -d /usr/shew/install/done/"$jail_name"/"$user" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"/"$user"
		chmod 0700 /usr/shew/install/done/"$jail_name"/"$user"
	fi

	touch /usr/shew/install/done/"$jail_name"/"$user"/firefox__set_proxy_privoxy
}

firefox__install_gnash() {
	# This function will install and configure gnash for the firefox installation
	# for $user.

	jail_name="$1"
	user="${2:-firefox}"

	if [ -f /usr/shew/install/done/"$jail_name"/"$user"/firefox__install_gnash ]; then
		echo "firefox__install_gnash was called on $jail_name with user $user but it has
already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "firefox__install_gnash was called on $jail_name but that jail does not exist."
		return 1
	fi

	if !
		chroot /usr/shew/jails/"$jail_name" \
			pw usershow "$user" \
			> /dev/null \
			2> /dev/null
	then
		echo "firefox__install_gnash was called with, or defaulted to $user but that user
does not exist."
		return 1
	fi

	if [ ! -d "$jailed_x_firefox__apps_folder" ]; then
		echo "firefox__install_gnash could not find a critical install file. It should be:
	$jailed_x_firefox__apps_folder"
	return 1
	fi

	if [ ! -d "$jailed_x_firefox__gnash_home_folder" ]; then
		echo "firefox__install_gnash could not find a critical install file. It should be:
	$jailed_x_firefox__gnash_home_folder"
		return 1
	fi

	ports_pkgs_utils__configure_port gnash "$jailed_x_firefox__apps_folder"
	ports_pkgs_utils__install_pkg gnash /usr/shew/jails/"$jail_name"

	cp -Rf "$jailed_x_firefox__gnash_home_folder" /usr/shew/jails/"$jail_name"/tmp/gnash
	chroot /usr/shew/jails/"$jail_name" \
		chown -R "${user}:$user" /tmp/gnash
	cp -af /usr/shew/jails/"$jail_name"/tmp/gnash/ /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"
	rm -Rf /usr/shew/jails/"$jail_name"/tmp/gnash

	echo '
// Added by firefox__install_gnash for Gnash:
user_pref("extensions.torbutton.no_tor_plugins", false);
user_pref("extensions.torbutton.isolate_content", false);
user_pref("extensions.torbutton.kill_bad_js", false);
' >> /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/prefs.js
		# Unfortunately, disabling these protections is required for gnash.

	grouplist="`user_maint_utils__return_grouplist "$user" /usr/shew/jails/"$jail_name"`"
	chroot /usr/shew/jails/"$jail_name" \
		pw usermod -n "$user" -G "${grouplist},sound"

	if [ ! -d /usr/shew/install/done/"$jail_name"/"$user" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"/"$user"
		chmod 0700 /usr/shew/install/done/"$jail_name"/"$user"
	fi

	touch /usr/shew/install/done/"$jail_name"/"$user"/firefox__install_gnash
}

firefox__install_adblock() {
	# This function will install and configure xpi-adblock_plus for the firefox
	# installation for $user.

	jail_name="$1"
	user="${2:-firefox}"

	if [ -f /usr/shew/install/done/"$jail_name"/"$user"/firefox__install_adblock ]; then
		echo "firefox__install_adblock was called on $jail_name with user $user but it
has already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "firefox__install_adblock was called on $jail_name but that jail does not exist."
		return 1
	fi

	if !
		chroot /usr/shew/jails/"$jail_name" \
			pw usershow "$user" \
			> /dev/null \
			2> /dev/null
	then
		echo "firefox__install_adblock was called with, or defaulted to $user but that user
does not exist."
		return 1
	fi

	if [ ! -d "$jailed_x_firefox__apps_folder" ]; then
		echo "firefox__install_adblock could not find a critical install file. It should be:
	$jailed_x_firefox__apps_folder"
	return 1
	fi

	if [ ! -d "$jailed_x_firefox__adblock_configs" ]; then
		echo "firefox__install_adblock could not find a critical install file. It should be:
	$jailed_x_firefox__adblock_configs"
		return 1
	fi

	if [ ! -L /usr/shew/jails/compile/usr/ports/packages/Latest/xpi-adblock_plus.tbz ]; then
		ln -s xpi-adblockplus.tbz /usr/shew/jails/compile/usr/ports/packages/Latest/xpi-adblock_plus.tbz
			# This is used because for some reason the xpi-adblock_plus port produces a
			# differently named package (xpi-adblockplus.tbz).
	fi

	ports_pkgs_utils__configure_port xpi-adblock_plus "$jailed_x_firefox__apps_folder"
	ports_pkgs_utils__install_pkg xpi-adblock_plus /usr/shew/jails/"$jail_name"

	mkdir -p /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/adblockplus
	cp -Rf "$jailed_x_firefox__adblock_configs"/patterns.ini \
		/usr/shew/jails/"$jail_name"/usr/shew/sensitive/"$user"/patterns.ini
	ln -s /usr/shew/sensitive/"$user"/patterns.ini \
/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/adblockplus/patterns.ini
	chroot /usr/shew/jails/"$jail_name" \
		chown -R "${user}:$user" \
			/usr/shew/sensitive/"$user"/patterns.ini \
			/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/adblockplus
	chmod -h 0444 \
/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/adblockplus/patterns.ini
	chflags -h schg \
/usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/adblockplus/patterns.ini

	chflags noschg /usr/shew/sensitive/"$jail_name"/"${user}.allow"
	echo 'patterns\.ini' \
		>> /usr/shew/sensitive/"$jail_name"/"${user}.allow"
	chflags schg /usr/shew/sensitive/"$jail_name"/"${user}.allow"

	echo '
// Added by firefox__install_adblock for Adblock:
user_pref("extensions.adblockplus.documentation_link", "");
user_pref("extensions.adblockplus.frameobjects", false);
user_pref("extensions.adblockplus.report_submiturl", "");
user_pref("extensions.adblockplus.savestats", false);
user_pref("extensions.adblockplus.showinstatusbar", true);
user_pref("extensions.adblockplus.showintoolbar", false);
user_pref("extensions.adblockplus.subscriptions_fallbackurl", "");
user_pref("extensions.adblockplus.subscriptions_listurl", "");
' >> /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/prefs.js

	if [ ! -d /usr/shew/install/done/"$jail_name"/"$user" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"/"$user"
		chmod 0700 /usr/shew/install/done/"$jail_name"/"$user"
	fi

	touch /usr/shew/install/done/"$jail_name"/"$user"/firefox__install_adblock
}

firefox__install_https_everywhere() {
	# This function will install and configure xpi-https-everywhere for the firefox
	# installation for $user.

	jail_name="$1"
	user="${2:-firefox}"

	if [ -f /usr/shew/install/done/"$jail_name"/"$user"/firefox__install_https_everywhere ]; then
		echo "firefox__install_https_everywhere was called on $jail_name with user $user
but it has already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "firefox__install_https_everywhere was called on $jail_name but that
jail does not exist."
		return 1
	fi

	if !
		chroot /usr/shew/jails/"$jail_name" \
			pw usershow "$user" \
			> /dev/null \
			2> /dev/null
	then
		echo "firefox__install_https_everywhere was called with, or defaulted to $user
but that user does not exist."
		return 1
	fi

	if [ ! -d "$jailed_x_firefox__apps_folder" ]; then
		echo "firefox__install_https_everywhere could not find a critical install file. It
should be:
	$jailed_x_firefox__apps_folder"
	return 1
	fi

	if [ ! -d "$jailed_x_firefox__make_folder" ]; then
		echo "firefox__install_https_everywhere could not find a critical install file. It
should be:
	$jailed_x_firefox__make_folder"
	return 1
	fi

	mkdir -p /usr/shew/jails/compile/usr/ports/www
	cp -Rf "$jailed_x_firefox__make_folder"/xpi-https-everywhere \
		/usr/shew/jails/compile/usr/ports/www/xpi-https-everywhere

	ports_pkgs_utils__configure_port xpi-https-everywhere "$jailed_x_firefox__apps_folder"
	ports_pkgs_utils__install_pkg xpi-https-everywhere /usr/shew/jails/"$jail_name"

	if [ ! -d /usr/shew/install/done/"$jail_name"/"$user" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"/"$user"
		chmod 0700 /usr/shew/install/done/"$jail_name"/"$user"
	fi

	touch /usr/shew/install/done/"$jail_name"/"$user"/firefox__install_https_everywhere
}

firefox__install_noscript() {
	# This function will install and configure xpi-noscript for the firefox
	# installation for $user.

	jail_name="$1"
	user="${2:-firefox}"

	if [ -f /usr/shew/install/done/"$jail_name"/"$user"/firefox__install_noscript ]; then
		echo "firefox__install_noscript was called on $jail_name with user $user but it
has already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "firefox__install_noscript was called on $jail_name but that jail does not exist."
		return 1
	fi

	if !
		chroot /usr/shew/jails/"$jail_name" \
			pw usershow "$user" \
			> /dev/null \
			2> /dev/null
	then
		echo "firefox__install_noscript was called with, or defaulted to $user but that user
does not exist."
		return 1
	fi

	if [ ! -d "$jailed_x_firefox__apps_folder" ]; then
		echo "firefox__install_noscript could not find a critical install file. It should be:
	$jailed_x_firefox__apps_folder"
	return 1
	fi

	if [ ! -d "$jailed_x_firefox__noscript_configs" ]; then
		echo "firefox__install_noscript could not find a critical install file. It should be:
	$jailed_x_firefox__noscript_configs"
		return 1
	fi

	ports_pkgs_utils__configure_port xpi-noscript "$jailed_x_firefox__apps_folder"
	ports_pkgs_utils__install_pkg xpi-noscript /usr/shew/jails/"$jail_name"

	echo "
// Added by firefox__install_noscript for NoScript:
`cat "$jailed_x_firefox__noscript_configs"/prefs.js`
" >> /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/prefs.js

	if [ ! -d /usr/shew/install/done/"$jail_name"/"$user" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"/"$user"
		chmod 0700 /usr/shew/install/done/"$jail_name"/"$user"
	fi

	touch /usr/shew/install/done/"$jail_name"/"$user"/firefox__install_noscript
}

firefox__install_perspectives() {
	# This function will install and configure xpi-perspectives for the firefox
	# installation for $user.

	jail_name="$1"
	user="${2:-firefox}"

	if [ -f /usr/shew/install/done/"$jail_name"/"$user"/firefox__install_perspectives ]; then
		echo "firefox__install_perspectives was called on $jail_name with user $user but
it has already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "firefox__install_perspectives was called on $jail_name but that jail
does not exist."
		return 1
	fi

	if !
		chroot /usr/shew/jails/"$jail_name" \
			pw usershow "$user" \
			> /dev/null \
			2> /dev/null
	then
		echo "firefox__install_perspectives was called with, or defaulted to $user but
that user does not exist."
		return 1
	fi

	if [ ! -d "$jailed_x_firefox__apps_folder" ]; then
		echo "firefox__install_perspectives could not find a critical install file. It should
be:
	$jailed_x_firefox__apps_folder"
	return 1
	fi

	if [ ! -d "$jailed_x_firefox__make_folder" ]; then
		echo "firefox__install_perspectives could not find a critical install file. It should
be:
	$jailed_x_firefox__make_folder"
	return 1
	fi

	mkdir -p /usr/shew/jails/compile/usr/ports/www
	cp -Rf "$jailed_x_firefox__make_folder"/xpi-perspectives /usr/shew/jails/compile/usr/ports/www/xpi-perspectives

	ports_pkgs_utils__configure_port xpi-perspectives "$jailed_x_firefox__apps_folder"
	ports_pkgs_utils__install_pkg xpi-perspectives /usr/shew/jails/"$jail_name"

	echo '
// Added by firefox__install_perspectives for Perspectives:
user_pref("perspectives.check_good_certificates", false);
user_pref("perspectives.prompt_update_all_https_setting", false);
user_pref("perspectives.require_user_permission", true);
' >> /usr/shew/jails/"$jail_name"/usr/shew/copy_to_mfs/home/"$user"/.mozilla/firefox/default/prefs.js

	if [ ! -d /usr/shew/install/done/"$jail_name"/"$user" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"/"$user"
		chmod 0700 /usr/shew/install/done/"$jail_name"/"$user"
	fi

	touch /usr/shew/install/done/"$jail_name"/"$user"/firefox__install_perspectives
}

firefox__install_taco() {
	# This function will install and configure xpi-beef-taco for the firefox
	# installation for $user.

	jail_name="$1"
	user="${2:-firefox}"

	if [ -f /usr/shew/install/done/"$jail_name"/"$user"/firefox__install_taco ]; then
		echo "firefox__install_taco was called on $jail_name with user $user but it has
already been run, skipping."
		return 0
	fi

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "firefox__install_taco was called on $jail_name but that jail does not
exist."
		return 1
	fi

	if !
		chroot /usr/shew/jails/"$jail_name" \
			pw usershow "$user" \
			> /dev/null \
			2> /dev/null
	then
		echo "firefox__install_taco was called with, or defaulted to $user but that user
does not exist."
		return 1
	fi

	if [ ! -d "$jailed_x_firefox__apps_folder" ]; then
		echo "firefox__install_taco could not find a critical install file. It should be:
	$jailed_x_firefox__apps_folder"
	return 1
	fi

	if [ ! -d "$jailed_x_firefox__make_folder" ]; then
		echo "firefox__install_taco could not find a critical install file. It should be:
	$jailed_x_firefox__make_folder"
	return 1
	fi

	mkdir -p /usr/shew/jails/compile/usr/ports/www
	cp -Rf "$jailed_x_firefox__make_folder"/xpi-beef-taco /usr/shew/jails/compile/usr/ports/www/xpi-beef-taco

	ports_pkgs_utils__configure_port xpi-beef-taco "$jailed_x_firefox__apps_folder"
	ports_pkgs_utils__install_pkg xpi-beef-taco /usr/shew/jails/"$jail_name"

	if [ ! -d /usr/shew/install/done/"$jail_name"/"$user" ]; then
		mkdir -p /usr/shew/install/done/"$jail_name"/"$user"
		chmod 0700 /usr/shew/install/done/"$jail_name"/"$user"
	fi

	touch /usr/shew/install/done/"$jail_name"/"$user"/firefox__install_taco
}
