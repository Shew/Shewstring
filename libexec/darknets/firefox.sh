#!/bin/sh

# Requires:	lib/misc_utils.sh
#		lib/ports_pkgs_utils.sh
#		lib/user_maint_utils.sh

# Contents:	darknets_firefox__firefox_control_i2p
#		darknets_firefox__firefox_control_freenet

darknets_firefox__firefox_control_i2p() {
	# This function will configure a firefox installation for controlling i2p. If
	# this task has already been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_firefox__firefox_control_i2p ]; then
		echo "darknets_firefox__firefox_control_i2p was called but it has already been run,
skipping."
		return 0
	fi

	arg_1='nat_darknets'
	arg_2='firefox_i2p'
	. /usr/shew/install/shewstring/libexec/jailed_x/firefox.sh

	ip="`jail_maint_utils__return_jail_ip nat_darknets`"

	i2p_port="`misc_utils__generate_unique_port`"
	echo "i2p_console=\"${i2p_port}\"" \
		>> /usr/shew/install/resources/ports

	cp -f /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_i2p/.mozilla/firefox/default/prefs.js \
		/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_i2p/.mozilla/firefox/default/prefs.js.tmp
	cat /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_i2p/.mozilla/firefox/default/prefs.js.tmp \
		| sed "s/browser.startup.homepage\", \".*\"/browser.startup.homepage\", \"${ip}:${i2p_port}\"/" \
		| sed "s/browser.startup.page\", ./browser.startup.page\", 1/" \
		| sed "s/torbutton.no_proxies_on\", \".*\"/torbutton.no_proxies_on\", \"127.0.0.1, ${ip}\"/" \
		| sed 's/security.warn_submit_insecure", true/security.warn_submit_insecure", false/' \
		> /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_i2p/.mozilla/firefox/default/prefs.js
	rm -f /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_i2p/.mozilla/firefox/default/prefs.js.tmp

	echo '
// Added by darknets_firefox__firefox_control_i2p for I2P:
user_pref("extensions.torbutton.custom.socks_host", "127.0.0.1");
user_pref("extensions.torbutton.custom.socks_port", 4);
user_pref("extensions.torbutton.display_panel", false);
user_pref("extensions.torbutton.socks_host", "127.0.0.1");
user_pref("extensions.torbutton.socks_port", 4);
' >> /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_i2p/.mozilla/firefox/default/prefs.js
		# The proxy is set to a nonexistent proxy, port 4 is the lowest
		# officially unassigned port.

echo "<!DOCTYPE NETSCAPE-Bookmark-file-1>
<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=UTF-8\">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks Menu</H1>

<DL><p>
<DT><A HREF=\"http://${ip}:${i2p_port}/\" ADD_DATE=\"0000000001\" LAST_MODIFIED=\"0000000001\">I2P Web Interface</A>
</DL><p>
" > /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_i2p/.mozilla/firefox/default/bookmarks.html
chroot /usr/shew/jails/nat_darknets \
	chown firefox_i2p:firefox_i2p /usr/shew/copy_to_mfs/home/firefox_i2p/.mozilla/firefox/default/bookmarks.html

chflags -h noschg \
	/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_i2p/.mozilla/firefox/default/bookmarkbackups \
	/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_i2p/.mozilla/firefox/default/cert_override.txt \
	/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_i2p/.mozilla/firefox/default/places.sqlite \
	/usr/shew/sensitive/nat_darknets/firefox_i2p.allow
rm -Rf \
	/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_i2p/.mozilla/firefox/default/bookmarkbackups \
	/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_i2p/.mozilla/firefox/default/cert_override.txt \
	/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_i2p/.mozilla/firefox/default/places.sqlite \
	/usr/shew/jails/nat_darknets/usr/shew/sensitive/firefox_i2p/bookmarkbackups
: > /usr/shew/sensitive/nat_darknets/firefox_i2p.allow
chflags schg /usr/shew/sensitive/nat_darknets/firefox_i2p.allow

	if !
		cat /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/clients.config \
			| grep '^clientApp\.[0-9]*\.' \
			> /dev/null
	then
		client_id='0'
	else
		client_id='1'
		while
			cat /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/clients.config \
				| grep "^clientApp\.${tunnel_id}\." \
				> /dev/null
		do
			client_id="`expr "$client_id" + 1`"
		done
	fi

	echo "
# Added by darknets_firefox__firefox_control_i2p for the I2P Web Console:
clientApp.${client_id}.args=$i2p_port $ip ./webapps/
clientApp.${client_id}.main=net.i2p.router.web.RouterConsoleRunner
clientApp.${client_id}.name=I2P Router Console
clientApp.${client_id}.onBoot=true
clientApp.${client_id}.startOnLoad=true
" >> /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/clients.config

	cp -f /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/webapps.config \
		/usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/webapps.config.tmp
	cat /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/webapps.config.tmp \
		| sed 's/webapps.routerconsole.startOnLoad=false/webapps.routerconsole.startOnLoad=true/' \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/webapps.config
	rm -f /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/webapps.config.tmp

	misc_utils__add_clause /etc/pf.conf '## Pass Jails:' \
		"# Added by darknets_firefox__firefox_control_i2p for the i2p web console:\\
		pass quick inet proto tcp from $ip to $ip port $i2p_port"
	pfctl -f /etc/pf.conf

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_firefox__firefox_control_i2p
}

darknets_firefox__firefox_control_freenet() {
	# This function will configure a firefox installation for controlling freenet.
	# If this task has already been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_firefox__firefox_control_freenet ]; then
		echo "darknets_firefox__firefox_control_freenet was called but it has already been
run, skipping."
		return 0
	fi

	. /usr/shew/install/shewstring/libexec/darknets/freenet.sh
	darknets_freenet__enable_http

	arg_1='nat_darknets'
	arg_2='firefox_freenet'
	. /usr/shew/install/shewstring/libexec/jailed_x/firefox.sh

	ip="`jail_maint_utils__return_jail_ip nat_darknets`"
	freenet_port="`misc_utils__echo_var /usr/shew/install/resources/ports freenet_http`"

	cp -f /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_freenet/.mozilla/firefox/default/prefs.js \
		/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_freenet/.mozilla/firefox/default/prefs.js.tmp
	cat /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_freenet/.mozilla/firefox/default/prefs.js.tmp \
		| sed "s/browser.startup.homepage\", \".*\"/browser.startup.homepage\", \"${ip}:${freenet_port}\"/" \
		| sed "s/browser.startup.page\", ./browser.startup.page\", 1/" \
		| sed "s/torbutton.no_proxies_on\", \".*\"/torbutton.no_proxies_on\", \"127.0.0.1, ${ip}\"/" \
		| sed 's/security.warn_submit_insecure", true/security.warn_submit_insecure", false/' \
		> /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_freenet/.mozilla/firefox/default/prefs.js
	rm -f /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_freenet/.mozilla/firefox/default/prefs.js.tmp

	echo '
// Added by darknets_firefox__firefox_control_freenet for Freenet:
user_pref("extensions.torbutton.custom.socks_host", "127.0.0.1");
user_pref("extensions.torbutton.custom.socks_port", 4);
user_pref("extensions.torbutton.display_panel", false);
user_pref("extensions.torbutton.socks_host", "127.0.0.1");
user_pref("extensions.torbutton.socks_port", 4);
' >> /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_freenet/.mozilla/firefox/default/prefs.js
		# The proxy is set to a nonexistent proxy, port 4 is the lowest
		# officially unassigned port.

echo "<!DOCTYPE NETSCAPE-Bookmark-file-1>
<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=UTF-8\">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks Menu</H1>

<DL><p>
<DT><A HREF=\"http://${ip}:${freenet_port}/\" ADD_DATE=\"0000000001\" LAST_MODIFIED=\"0000000001\">Freenet Web Interface</A>
</DL><p>
" > /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_freenet/.mozilla/firefox/default/bookmarks.html
chroot /usr/shew/jails/nat_darknets \
  chown firefox_freenet:firefox_freenet /usr/shew/copy_to_mfs/home/firefox_freenet/.mozilla/firefox/default/bookmarks.html

chflags -h noschg \
	/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_freenet/.mozilla/firefox/default/bookmarkbackups \
	/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_freenet/.mozilla/firefox/default/cert_override.txt \
	/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_freenet/.mozilla/firefox/default/places.sqlite \
	/usr/shew/sensitive/nat_darknets/firefox_freenet.allow
rm -Rf \
	/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_freenet/.mozilla/firefox/default/bookmarkbackups \
	/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_freenet/.mozilla/firefox/default/cert_override.txt \
	/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/firefox_freenet/.mozilla/firefox/default/places.sqlite \
	/usr/shew/jails/nat_darknets/usr/shew/sensitive/firefox_freenet/bookmarkbackups
: > /usr/shew/sensitive/nat_darknets/firefox_freenet.allow
chflags schg /usr/shew/sensitive/nat_darknets/firefox_freenet.allow

	misc_utils__add_clause /etc/pf.conf '## Pass Jails:' \
		"# Added by darknets_firefox__firefox_control_freenet for the freenet http proxy:\\
		pass quick inet proto tcp from $ip to $ip port $freenet_port"
	pfctl -f /etc/pf.conf

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_firefox__firefox_control_freenet
}
