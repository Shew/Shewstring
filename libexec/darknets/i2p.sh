#!/bin/sh

# The I2P home page: http://www.i2p2.de/

# Requires:	lib/misc_utils.sh
#		lib/user_maint_utils.sh

# Contents:	darknets_i2p__install_i2p
#		darknets_i2p__enable_http_https
#		darknets_i2p__enable_socks
#		darknets_i2p__enable_irc
#		darknets_i2p__enable_pop_smtp
#		darknets_i2p__add_jail_i2p_http_https_rules
#		darknets_i2p__add_jail_i2p_socks_rules
#		darknets_i2p__add_jail_i2p_irc_rules
#		darknets_i2p__add_jail_i2p_pop_smtp_rules

# Variable defaults:
  : ${darknets_i2p__apps_folder='/usr/shew/install/shewstring/libexec/darknets/apps'}
								# The default darknets apps folder.
  : ${darknets_i2p__i2p_websites='http://mirror.i2p2.de/'}	# The website(s) hosting the i2p installer.
  : ${darknets_i2p__i2p_file='i2pinstall_0.8.7.exe'}		# The filename of the i2p installer.
  : ${darknets_i2p__i2p_sha256='9f0b1d565e0250cefe3998e1ccabda062d057f794ccb976c147608f005a022c4'}
								# The sha256 hash of the i2p installer.
  : ${darknets_i2p__i2p_configs='/usr/shew/install/shewstring/libexec/darknets/misc/i2p'}
								# This file is the default i2p folder for config files.
  : ${darknets_i2p__rcd_i2p='/usr/shew/install/shewstring/libexec/darknets/rc.d/shew_i2p'}
								# This file is the default i2p rc.d file.

darknets_i2p__install_i2p() {
	# This function will install and configure i2p. The router console and client
	# tunnels are disabled by default, and must be enabled by other functions.
	# i2p's ntp feature is also turned off, so ntpd should be enabled. If this task
	# has already been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_i2p__install_i2p ]; then
		echo "darknets_i2p__install_i2p was called but it has already been run, skipping."
		return 0
	fi

	if [ ! -d "$darknets_i2p__apps_folder" ]; then
		echo "darknets_i2p__install_i2p could not find a critical install file. It
should be:
	$darknets_i2p__apps_folder"
		return 1
	fi

	if [ ! -d "$darknets_i2p__i2p_configs" ]; then
		echo "darknets_i2p__install_i2p could not find a critical install file. It should be:
	$darknets_i2p__i2p_configs"
		return 1
	fi

	if [ ! -f "$darknets_i2p__rcd_i2p" ]; then
		echo "darknets_i2p__install_i2p could not find a critical install file. It should be:
	$darknets_i2p__rcd_i2p"
		return 1
	fi

	# This is commented out because the wrapper does not work:
	#if [ ! -L /usr/shew/jails/compile/usr/ports/packages/Latest/compat4x.tbz ]; then
	#	ln -s compat4x.tbz /usr/shew/jails/compile/usr/ports/packages/Latest/"compat4x-${shew__architecture}.tbz"
	#		# This is used because for some reason the compat4x port produces a differently
	#		# named package (e.g. compat4x-i386.tbz).
	#fi
	#
	#ports_pkgs_utils__configure_port compat4x "$darknets_i2p__apps_folder"
	#ports_pkgs_utils__install_pkg compat4x /usr/shew/jails/nat_darknets

	user_maint_utils__add_jail_user nat_darknets i2p none home permanent sensitive
	chroot /usr/shew/jails/nat_darknets \
		pw usermod -n i2p -s /sbin/nologin

	export misc_utils__sha256="$darknets_i2p__i2p_sha256"
	misc_utils__fetch "$darknets_i2p__i2p_file" "$darknets_i2p__i2p_websites"

	cp -f /usr/shew/install/fetch/"$darknets_i2p__i2p_file" /usr/shew/jails/nat_darknets/tmp/"$darknets_i2p__i2p_file"

	{
		echo 1
		sleep 3
		echo '/usr/shew/permanent/i2p'
		sleep 3
		echo 1
		sleep 3
	} \
		| chroot /usr/shew/jails/nat_darknets \
		/usr/local/bin/java -jar /tmp/"$darknets_i2p__i2p_file" -console
	# This chooses the correct options from the I2P console install prompt.

	rm -f /usr/shew/jails/nat_darknets/tmp/"$darknets_i2p__i2p_file"

	i2p_ip="`jail_maint_utils__return_jail_ip nat_darknets`"

	i2p_port="`misc_utils__generate_unique_port`"
	echo "i2p_external=\"${i2p_port}\"" \
		>> /usr/shew/install/resources/ports

	i2p_i2cp="`misc_utils__generate_unique_port`"
	echo "i2p_i2cp=\"${i2p_i2cp}\"" \
		>> /usr/shew/install/resources/ports

	cp -f "$darknets_i2p__i2p_configs"/clients.config \
		/usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/clients.config

	echo '## I2P Tunnels:' \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2ptunnel.config

	cat "$darknets_i2p__i2p_configs"/router.config \
		| sed "s/i2cp.tcp.host=/i2cp.tcp.host=${i2p_ip}/" \
		| sed "s/i2cp.tcp.port=/i2cp.tcp.port=${i2p_i2cp}/" \
		| sed "s/i2np.udp.internalPort=/i2np.udp.internalPort=${i2p_port}/" \
		| sed "s/i2np.udp.port=/i2np.udp.port=${i2p_port}/" \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/router.config

	cp -f /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/runplain.sh \
		/usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/runplain.sh.tmp
	cat /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/runplain.sh.tmp \
		| sed 's|^I2P=".*"|I2P="/home/i2p/i2p"|' \
		| sed 's|^I2PTEMP=".*"|I2PTEMP="/home/i2p/tmp"|' \
		| sed 's|^JAVA=.*|JAVA="/usr/local/bin/java"|' \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/runplain.sh
	rm -f /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/runplain.sh.tmp

	cp -f "$darknets_i2p__i2p_configs"/webapps.config \
		/usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/webapps.config

	cp -f /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2prouter \
		/usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2prouter.tmp
	cat /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2prouter.tmp \
		| sed 's|^I2P=".*"|I2P="/home/i2p/i2p"|' \
		| sed 's|^I2PTEMP=".*"|I2PTEMP="/home/i2p/tmp"|' \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2prouter
	rm -f /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2prouter.tmp

	cp -f /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/wrapper.config \
		/usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/wrapper.config.tmp
	cat /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/wrapper.config.tmp \
	| sed 's|^wrapper.java.additional.4=-Di2p.dir.base=.*|wrapper.java.additional.4=-Di2p.dir.base="/home/i2p/i2p"|' \
		| sed 's|^wrapper.java.command=.*|wrapper.java.command=/usr/local/bin/java|' \
		| sed 's|^wrapper.java.pidfile=.*|wrapper.java.pidfile=/home/i2p/tmp/routerjvm.pid|' \
		| sed 's|^wrapper.logfile=.*|wrapper.logfile=/home/i2p/logs/wrapper.log|' \
		| sed 's|^wrapper.pidfile=.*|wrapper.pidfile=/home/i2p/tmp/i2p.pid|' \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/wrapper.config
	rm -f /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/wrapper.config.tmp

	if
		ls /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/docs/*-header.ht \
			> /dev/null \
			2> /dev/null
		# This protects the following for loop from invalid input if there are no files.
	then
		for val in /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/docs/*-header.ht; do
			cp -f "$val" "${val}.tmp"
			cat "${val}.tmp" \
				| sed 's/ *<link rel="shortcut icon".*//' \
				> "$val"
			rm -f "${val}.tmp"
		done
	fi
		# This removes the favicons from the i2p proxy error pages.
		# This is done because the favicons replace the favicon the eepsite has selected when you bookmark
		# the eepsite and then hit an error when reaching it. This is a minor annoyance.

	chroot /usr/shew/jails/nat_darknets \
		sh "-$-" -c '
			mkdir -p \
				/usr/shew/copy_to_mfs/home/i2p/i2p \
				/usr/shew/copy_to_mfs/home/i2p/logs \
				/usr/shew/copy_to_mfs/home/i2p/tmp
			ln -s /usr/shew/permanent/i2p/* /usr/shew/copy_to_mfs/home/i2p/i2p

			rm -f /usr/shew/copy_to_mfs/home/i2p/i2p/logs
			ln -s ../logs /usr/shew/copy_to_mfs/home/i2p/i2p/logs

			rm -f \
				/usr/shew/copy_to_mfs/home/i2p/i2p/hosts.txt \
				/usr/shew/copy_to_mfs/home/i2p/i2p/keyBackup \
				/usr/shew/copy_to_mfs/home/i2p/i2p/netDb \
				/usr/shew/copy_to_mfs/home/i2p/i2p/peerProfiles
			touch /usr/shew/permanent/i2p/hosts.txt
			mv /usr/shew/permanent/i2p/hosts.txt /usr/shew/sensitive/i2p/hosts.txt
			mkdir -p \
				/usr/shew/sensitive/i2p/keyBackup \
				/usr/shew/sensitive/i2p/netDb \
				/usr/shew/sensitive/i2p/peerProfiles
			ln -s \
				/usr/shew/sensitive/i2p/hosts.txt \
				/usr/shew/sensitive/i2p/keyBackup \
				/usr/shew/sensitive/i2p/netDb \
				/usr/shew/sensitive/i2p/peerProfiles \
				/usr/shew/sensitive/i2p/prngseed.rnd \
				/usr/shew/sensitive/i2p/router.info \
				/usr/shew/sensitive/i2p/router.keys \
				/usr/shew/copy_to_mfs/home/i2p/i2p

			chown -R i2p:i2p /usr/shew/permanent/i2p
			chown i2p:i2p \
				/usr/shew/copy_to_mfs/home/i2p/i2p \
				/usr/shew/copy_to_mfs/home/i2p/logs \
				/usr/shew/copy_to_mfs/home/i2p/tmp
			chown -R i2p:i2p /usr/shew/sensitive/i2p
		'

	chmod -h 0444 /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/i2p/i2p/*
	chflags -h schg /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/i2p/i2p/*

	chflags noschg /usr/shew/sensitive/nat_darknets/i2p.allow
	echo 'hosts\.txt
keyBackup
keyBackup/.*\.key
netDb
netDb/routerInfo-.*\.dat
peerProfiles
peerProfiles/profile-.*\.txt\.gz
prngseed\.rnd
router\.info
router\.keys' \
		>> /usr/shew/sensitive/nat_darknets/i2p.allow
	chflags schg /usr/shew/sensitive/nat_darknets/i2p.allow

	misc_utils__add_clause /etc/pf.conf '## Pass Jails:' \
		"# Added by darknets_i2p__install_i2p for i2p:\\
		pass quick inet proto tcp from $i2p_ip to $i2p_ip port 32000\\
		pass quick inet proto tcp from $i2p_ip to $i2p_ip port $i2p_i2cp"

	misc_utils__add_clause /etc/pf.conf '## Redirect External:' \
		"# Added by darknets_i2p__install_i2p for i2p:\\
		rdr pass on \$interfaces inet proto tcp from !127.0.0.0/8 to port $i2p_port -> $i2p_ip port ${i2p_port}\\
		rdr pass on \$interfaces inet proto udp from !127.0.0.0/8 to port $i2p_port -> $i2p_ip port $i2p_port"

	pfctl -f /etc/pf.conf

	cp -f "$darknets_i2p__rcd_i2p" /usr/shew/jails/nat_darknets/etc/rc.d/shew_i2p
	chmod 0500 /usr/shew/jails/nat_darknets/etc/rc.d/shew_i2p

	echo '
# Added by darknets_i2p__install_i2p for i2p:
shew_i2p_enable="YES"
' >> /usr/shew/jails/nat_darknets/etc/rc.conf

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_i2p__install_i2p
}

darknets_i2p__enable_http_https() {
	# This function will enable the http and https proxies on i2p. Outproxies are
	# disabled, because tor should handle that instead. If this task has already
	# been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_i2p__enable_http_https ]; then
		echo "darknets_i2p__enable_http_https was called but it has already been run,
skipping."
		return 0
	fi

	if !
		cat /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2ptunnel.config \
			| grep '^tunnel\.[0-9]*\.' \
			> /dev/null
	then
		tunnel_id='0'
	else
		tunnel_id='1'
		while
			cat /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2ptunnel.config \
				| grep "^tunnel\.${tunnel_id}\." \
				> /dev/null
		do
			tunnel_id="`expr "$tunnel_id" + 1`"
		done
	fi

	i2p_ip="`jail_maint_utils__return_jail_ip nat_darknets`"

	i2p_port="`misc_utils__generate_unique_port`"
	echo "i2p_http=\"${i2p_port}\"" \
		>> /usr/shew/install/resources/ports

	i2p_i2cp="`misc_utils__echo_var /usr/shew/install/resources/ports i2p_i2cp`"

	mkdir -p /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/addressbook
	cat "$darknets_i2p__i2p_configs"/addressbook/config.txt \
		| sed "s/proxy_port=/proxy_port=${i2p_port}/" \
		| sed "s/proxy_host=/proxy_host=${i2p_ip}/" \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/addressbook/config.txt

	cp -f "$darknets_i2p__i2p_configs"/addressbook/subscriptions.txt \
		/usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/addressbook/subscriptions.txt

	chroot /usr/shew/jails/nat_darknets \
		chown -R i2p:i2p /usr/shew/permanent/i2p/addressbook

	mkdir -p /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/i2p/i2p/addressbook
	chroot /usr/shew/jails/nat_darknets \
		ln -s /usr/shew/permanent/i2p/addressbook/* /usr/shew/copy_to_mfs/home/i2p/i2p/addressbook
	chroot /usr/shew/jails/nat_darknets \
		chown -Rh i2p:i2p /usr/shew/copy_to_mfs/home/i2p/i2p/addressbook
	chmod -h 0444 /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/i2p/i2p/addressbook/*
	chflags -h schg /usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/i2p/i2p/addressbook/*

	cp -f /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/webapps.config \
		/usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/webapps.config.tmp
	cat /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/webapps.config.tmp \
		| sed 's/webapps.addressbook.startOnLoad=false/webapps.addressbook.startOnLoad=true/' \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/webapps.config
	rm -f /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/webapps.config.tmp

	echo "
# Added by darknets_i2p__configure_http_https for http and https:

tunnel.${tunnel_id}.name=I2P HTTP Proxy
tunnel.${tunnel_id}.description=HTTP Proxy
tunnel.${tunnel_id}.i2cpHost=$i2p_ip
tunnel.${tunnel_id}.i2cpPort=$i2p_i2cp
tunnel.${tunnel_id}.interface=$i2p_ip
tunnel.${tunnel_id}.listenPort=$i2p_port
tunnel.${tunnel_id}.option.i2cp.reduceIdleTime=900000
tunnel.${tunnel_id}.option.i2cp.reduceOnIdle=true
tunnel.${tunnel_id}.option.i2cp.reduceQuantity=1
tunnel.${tunnel_id}.option.i2p.streaming.connectDelay=1000
tunnel.${tunnel_id}.option.inbound.length=3
tunnel.${tunnel_id}.option.inbound.lengthVariance=0
tunnel.${tunnel_id}.option.inbound.nickname=HTTP Proxy
tunnel.${tunnel_id}.option.outbound.length=3
tunnel.${tunnel_id}.option.outbound.lengthVariance=0
tunnel.${tunnel_id}.option.outbound.nickname=HTTP Proxy
tunnel.${tunnel_id}.sharedClient=false
tunnel.${tunnel_id}.startOnLoad=true
tunnel.${tunnel_id}.type=httpclient" \
		>> /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2ptunnel.config

	tunnel_id="`expr "$tunnel_id" + 1`"

	i2p_port="`misc_utils__generate_unique_port`"
	echo "i2p_https=\"${i2p_port}\"" \
		>> /usr/shew/install/resources/ports

	echo "
tunnel.${tunnel_id}.name=I2P HTTPS Proxy
tunnel.${tunnel_id}.description=HTTPS Proxy
tunnel.${tunnel_id}.i2cpHost=$i2p_ip
tunnel.${tunnel_id}.i2cpPort=$i2p_i2cp
tunnel.${tunnel_id}.interface=$i2p_ip
tunnel.${tunnel_id}.listenPort=$i2p_port
tunnel.${tunnel_id}.option.i2cp.reduceIdleTime=900000
tunnel.${tunnel_id}.option.i2cp.reduceOnIdle=true
tunnel.${tunnel_id}.option.i2cp.reduceQuantity=1
tunnel.${tunnel_id}.option.i2p.streaming.connectDelay=1000
tunnel.${tunnel_id}.option.inbound.length=3
tunnel.${tunnel_id}.option.inbound.lengthVariance=0
tunnel.${tunnel_id}.option.inbound.nickname=HTTPS Proxy
tunnel.${tunnel_id}.option.outbound.length=3
tunnel.${tunnel_id}.option.outbound.lengthVariance=0
tunnel.${tunnel_id}.option.outbound.nickname=HTTPS Proxy
tunnel.${tunnel_id}.sharedClient=false
tunnel.${tunnel_id}.startOnLoad=true
tunnel.${tunnel_id}.type=connectclient
" >> /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2ptunnel.config

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_i2p__enable_http_https
}

darknets_i2p__enable_socks() {
	# This function will enable the socks proxy on i2p. If this task has already
	# been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_i2p__enable_socks ]; then
		echo "darknets_i2p__enable_socks was called but it has already been run, skipping."
		return 0
	fi

	if !
		cat /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2ptunnel.config \
			| grep '^tunnel\.[0-9]*\.' \
			> /dev/null
	then
		tunnel_id='0'
	else
		tunnel_id='1'
		while
			cat /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2ptunnel.config \
				| grep "^tunnel\.${tunnel_id}\." \
				> /dev/null
		do
			tunnel_id="`expr "$tunnel_id" + 1`"
		done
	fi

	i2p_ip="`jail_maint_utils__return_jail_ip nat_darknets`"

	i2p_port="`misc_utils__generate_unique_port`"
	echo "i2p_socks=\"${i2p_port}\"" \
		>> /usr/shew/install/resources/ports

	i2p_i2cp="`misc_utils__echo_var /usr/shew/install/resources/ports i2p_i2cp`"

	echo "
# Added by darknets_i2p__configure_socks for socks:
tunnel.${tunnel_id}.name=I2P SOCKS Proxy
tunnel.${tunnel_id}.description=SOCKS Proxy
tunnel.${tunnel_id}.i2cpHost=$i2p_ip
tunnel.${tunnel_id}.i2cpPort=$i2p_i2cp
tunnel.${tunnel_id}.interface=$i2p_ip
tunnel.${tunnel_id}.listenPort=$i2p_port
tunnel.${tunnel_id}.option.i2cp.reduceIdleTime=900000
tunnel.${tunnel_id}.option.i2cp.reduceOnIdle=true
tunnel.${tunnel_id}.option.i2cp.reduceQuantity=1
tunnel.${tunnel_id}.option.i2p.streaming.connectDelay=1000
tunnel.${tunnel_id}.option.inbound.length=3
tunnel.${tunnel_id}.option.inbound.lengthVariance=0
tunnel.${tunnel_id}.option.inbound.nickname=SOCKS Proxy
tunnel.${tunnel_id}.option.outbound.length=3
tunnel.${tunnel_id}.option.outbound.lengthVariance=0
tunnel.${tunnel_id}.option.outbound.nickname=SOCKS Proxy
tunnel.${tunnel_id}.sharedClient=false
tunnel.${tunnel_id}.startOnLoad=true
tunnel.${tunnel_id}.type=sockstunnel
" >> /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2ptunnel.config

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_i2p__enable_socks
}

darknets_i2p__enable_irc() {
	# This function will enable the irc proxy on i2p. This proxy points to the irc
	# servers at irc.postmani2p and irc.freshcoffeei2p (which is the i2p default).
	# If you want to connect to arbitrary servers, socks should probably be used
	# instead. If this task has already been done, the function complains and
	# returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_i2p__enable_irc ]; then
		echo "darknets_i2p__enable_irc was called but it has already been run, skipping."
		return 0
	fi

	if !
		cat /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2ptunnel.config \
			| grep '^tunnel\.[0-9]*\.' \
			> /dev/null
	then
		tunnel_id='0'
	else
		tunnel_id='1'
		while
			cat /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2ptunnel.config \
				| grep "^tunnel\.${tunnel_id}\." \
				> /dev/null
		do
			tunnel_id="`expr "$tunnel_id" + 1`"
		done
	fi

	ip="`jail_maint_utils__return_jail_ip nat_darknets`"

	port="`misc_utils__generate_unique_port`"
	echo "i2p_irc=\"${port}\"" \
		>> /usr/shew/install/resources/ports

	i2p_i2cp="`misc_utils__echo_var /usr/shew/install/resources/ports i2p_i2cp`"

	echo "
# Added by darknets_i2p__configure_irc for irc:
tunnel.${tunnel_id}.name=I2P IRC Proxy
tunnel.${tunnel_id}.description=IRC Proxy to irc.postman.i2p and irc.freshcoffee.i2p
tunnel.${tunnel_id}.i2cpHost=$i2p_ip
tunnel.${tunnel_id}.i2cpPort=$i2p_i2cp
tunnel.${tunnel_id}.interface=$ip
tunnel.${tunnel_id}.listenPort=$port
tunnel.${tunnel_id}.option.i2cp.closeIdleTime=1200000
tunnel.${tunnel_id}.option.i2cp.closeOnIdle=true
tunnel.${tunnel_id}.option.i2cp.delayOpen=true
tunnel.${tunnel_id}.option.i2cp.newDestOnResume=false
tunnel.${tunnel_id}.option.i2cp.reduceIdleTime=600000
tunnel.${tunnel_id}.option.i2cp.reduceOnIdle=true
tunnel.${tunnel_id}.option.i2cp.reduceQuantity=1
tunnel.${tunnel_id}.option.i2p.streaming.connectDelay=1000
tunnel.${tunnel_id}.option.i2p.streaming.maxWindowSize=16
tunnel.${tunnel_id}.option.inbound.length=3
tunnel.${tunnel_id}.option.inbound.lengthVariance=0
tunnel.${tunnel_id}.option.inbound.nickname=Client Proxies
tunnel.${tunnel_id}.option.outbound.length=3
tunnel.${tunnel_id}.option.outbound.lengthVariance=0
tunnel.${tunnel_id}.option.outbound.nickname=Client Proxies
tunnel.${tunnel_id}.sharedClient=true
tunnel.${tunnel_id}.startOnLoad=true
tunnel.${tunnel_id}.targetDestination=irc.postman.i2p,irc.freshcoffee.i2p
tunnel.${tunnel_id}.type=ircclient
" >> /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2ptunnel.config

	if !
		misc_utils__echo_var /usr/shew/install/resources/loopbacks i2p \
			> /dev/null
	then
		loopback="`misc_utils__generate_unique_loopback`"
		echo "i2p=\"${loopback}\"" \
			>> /usr/shew/install/resources/loopbacks

		cloned_interfaces="`misc_utils__echo_var /etc/rc.conf cloned_interfaces`"
		misc_utils__change_var /etc/rc.conf cloned_interfaces "$cloned_interfaces lo$loopback"
	else
		loopback="`misc_utils__echo_var /usr/shew/install/resources/loopbacks i2p`"
	fi

	misc_utils__add_clause /etc/pf.conf '## Redirect Internal:' \
		"# Added by darknets_i2p__enable_irc for IRC:\\
		rdr pass on lo$loopback inet proto tcp from 127.0.0.0/8 to 127.0.0.0/8 port 6668 -> $ip port $port"
	pfctl -f /etc/pf.conf

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_i2p__enable_irc
}

darknets_i2p__enable_pop_smtp() {
	# This function will enable the pop3 and smtp proxies on i2p. This proxy points
	# to the mail servers pop.postmani2p and smtp.postmani2p (which is the i2p
	# default). If you want to connect to arbitrary servers, socks should probably
	# be used instead. If this task has already been done, the function complains
	# and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_i2p__enable_pop_smtp ]; then
		echo "darknets_i2p__enable_pop_smtp was called but it has already been run, skipping."
		return 0
	fi

	if !
		cat /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2ptunnel.config \
			| grep '^tunnel\.[0-9]*\.' \
			> /dev/null
	then
		tunnel_id='0'
	else
		tunnel_id='1'
		while
			cat /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2ptunnel.config \
				| grep "^tunnel\.${tunnel_id}\." \
				> /dev/null
		do
			tunnel_id="`expr "$tunnel_id" + 1`"
		done
	fi

	ip="`jail_maint_utils__return_jail_ip nat_darknets`"

	pop_port="`misc_utils__generate_unique_port`"
	echo "i2p_pop=\"${pop_port}\"" \
		>> /usr/shew/install/resources/ports

	i2p_i2cp="`misc_utils__echo_var /usr/shew/install/resources/ports i2p_i2cp`"

	echo "
# Added by darknets_i2p__configure_pop_smtp for pop and smtp:

tunnel.${tunnel_id}.name=I2P POP3 Proxy
tunnel.${tunnel_id}.description=POP3 Proxy to pop3.postman.i2p
tunnel.${tunnel_id}.i2cpHost=$i2p_ip
tunnel.${tunnel_id}.i2cpPort=$i2p_i2cp
tunnel.${tunnel_id}.interface=$ip
tunnel.${tunnel_id}.listenPort=$pop_port
tunnel.${tunnel_id}.option.i2cp.reduceIdleTime=900000
tunnel.${tunnel_id}.option.i2cp.reduceOnIdle=true
tunnel.${tunnel_id}.option.i2cp.reduceQuantity=1
tunnel.${tunnel_id}.option.i2p.streaming.connectDelay=1000
tunnel.${tunnel_id}.option.inbound.length=3
tunnel.${tunnel_id}.option.inbound.lengthVariance=0
tunnel.${tunnel_id}.option.inbound.nickname=Client Proxies
tunnel.${tunnel_id}.option.outbound.length=3
tunnel.${tunnel_id}.option.outbound.lengthVariance=0
tunnel.${tunnel_id}.option.outbound.nickname=Client Proxies
tunnel.${tunnel_id}.sharedClient=true
tunnel.${tunnel_id}.startOnLoad=true
tunnel.${tunnel_id}.targetDestination=pop.postman.i2p
tunnel.${tunnel_id}.type=client" \
	>> /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2ptunnel.config

	tunnel_id="`expr "$tunnel_id" + 1`"

	smtp_port="`misc_utils__generate_unique_port`"
	echo "i2p_smtp=\"${smtp_port}\"" \
		>> /usr/shew/install/resources/ports

	echo "
tunnel.${tunnel_id}.name=I2P SMTP Proxy
tunnel.${tunnel_id}.description=SMTP Proxy to smtp.postman.i2p
tunnel.${tunnel_id}.i2cpHost=$i2p_ip
tunnel.${tunnel_id}.i2cpPort=$i2p_i2cp
tunnel.${tunnel_id}.interface=$ip
tunnel.${tunnel_id}.listenPort=$smtp_port
tunnel.${tunnel_id}.option.i2cp.reduceIdleTime=900000
tunnel.${tunnel_id}.option.i2cp.reduceOnIdle=true
tunnel.${tunnel_id}.option.i2cp.reduceQuantity=1
tunnel.${tunnel_id}.option.i2p.streaming.connectDelay=1000
tunnel.${tunnel_id}.option.inbound.length=3
tunnel.${tunnel_id}.option.inbound.lengthVariance=0
tunnel.${tunnel_id}.option.inbound.nickname=Client Proxies
tunnel.${tunnel_id}.option.outbound.length=3
tunnel.${tunnel_id}.option.outbound.lengthVariance=0
tunnel.${tunnel_id}.option.outbound.nickname=Client Proxies
tunnel.${tunnel_id}.sharedClient=true
tunnel.${tunnel_id}.startOnLoad=true
tunnel.${tunnel_id}.targetDestination=smtp.postman.i2p
tunnel.${tunnel_id}.type=client
" >> /usr/shew/jails/nat_darknets/usr/shew/permanent/i2p/i2ptunnel.config

	if !
		misc_utils__echo_var /usr/shew/install/resources/loopbacks i2p \
			> /dev/null
	then
		loopback="`misc_utils__generate_unique_loopback`"
		echo "i2p=\"${loopback}\"" \
			>> /usr/shew/install/resources/loopbacks

		cloned_interfaces="`misc_utils__echo_var /etc/rc.conf cloned_interfaces`"
		misc_utils__change_var /etc/rc.conf cloned_interfaces "$cloned_interfaces lo$loopback"
	else
		loopback="`misc_utils__echo_var /usr/shew/install/resources/loopbacks i2p`"
	fi

	misc_utils__add_clause /etc/pf.conf '## Redirect Internal:' \
		"# Added by darknets_i2p__enable_pop_smtp for Email:\\
		rdr pass on lo$loopback inet proto tcp from 127.0.0.0/8 to 127.0.0.0/8 port 7654 -> $ip port ${pop_port}\\
		rdr pass on lo$loopback inet proto tcp from 127.0.0.0/8 to 127.0.0.0/8 port 7659 -> $ip port $smtp_port"
	pfctl -f /etc/pf.conf

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_i2p__enable_pop_smtp
}

darknets_i2p__add_jail_i2p_http_https_rules() {
	# This function will add the pf rules that allow a jail to use i2p's http
	# proxy. The function calls darknets_i2p__enable_http_https if i2p does not
	# have it's proxy enabled.

	jail_name="$1"
	
	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "darknets_i2p__add_jail_i2p_http_https_rules was called on $jail_name
but that jail does not exist."
		return 1
	fi

	if !
		cat /usr/shew/install/resources/ports \
			| grep 'i2p_http=' \
			> /dev/null \
		&& \
			cat /usr/shew/install/resources/ports \
				| grep 'i2p_https=' \
				> /dev/null
	then
		darknets_i2p__enable_http_https
	fi

	ip="`jail_maint_utils__return_jail_ip "$jail_name"`"
	nat_darknets_ip="`jail_maint_utils__return_jail_ip nat_darknets`"
	http_port="`misc_utils__echo_var /usr/shew/install/resources/ports i2p_http`"
	https_port="`misc_utils__echo_var /usr/shew/install/resources/ports i2p_https`"

	misc_utils__add_clause /etc/pf.conf '## Pass Jails:' \
		"# Added by darknets_i2p__add_jail_i2p_http_https_rules for ${jail_name}:\\
		pass quick inet proto tcp from $ip to $nat_darknets_ip port $http_port\\
		pass quick inet proto tcp from $ip to $nat_darknets_ip port $https_port"
	pfctl -f /etc/pf.conf
}

darknets_i2p__add_jail_i2p_socks_rules() {
	# This function will add the pf rules that allow a jail to use i2p's socks
	# proxy. The function calls darknets_i2p__enable_socks if i2p does not have
	# it's proxy enabled.

	jail_name="$1"
	
	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "darknets_i2p__add_jail_i2p_socks_rules was called on $jail_name but
that jail does not exist."
		return 1
	fi

	if !
		cat /usr/shew/install/resources/ports \
			| grep 'i2p_socks=' \
			> /dev/null
	then
		darknets_i2p__enable_socks
	fi

	ip="`jail_maint_utils__return_jail_ip "$jail_name"`"
	nat_darknets_ip="`jail_maint_utils__return_jail_ip nat_darknets`"
	port="`misc_utils__echo_var /usr/shew/install/resources/ports i2p_socks`"

	misc_utils__add_clause /etc/pf.conf '## Pass Jails:' \
		"# Added by darknets_i2p__add_jail_i2p_socks_rules for ${jail_name}:\\
		pass quick inet proto tcp from $ip to $nat_darknets_ip port $port"
	pfctl -f /etc/pf.conf
}

darknets_i2p__add_jail_i2p_irc_rules() {
	# This function will add the pf rules that allow a jail to use i2p's irc proxy.
	# The function calls darknets_i2p__enable_irc if i2p does not have it's proxy
	# enabled.

	jail_name="$1"
	
	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "darknets_i2p__add_jail_i2p_irc_rules was called on $jail_name but
that jail does not exist."
		return 1
	fi

	if !
		cat /usr/shew/install/resources/ports \
			| grep 'i2p_irc=' \
			> /dev/null
	then
		darknets_i2p__enable_irc
	fi

	ip="`jail_maint_utils__return_jail_ip "$jail_name"`"
	loopback="`misc_utils__echo_var /usr/shew/install/resources/loopbacks i2p`"

	misc_utils__add_clause /etc/pf.conf '## Route-to:' \
		"# Added by darknets_i2p__add_jail_i2p_irc_rules for ${jail_name}:\\
		pass out route-to lo$loopback inet proto tcp from $ip to 127.0.0.0/8 port 6668"
	pfctl -f /etc/pf.conf
}

darknets_i2p__add_jail_i2p_pop_smtp_rules() {
	# This function will add the pf rules that allow a jail to use i2p's pop and
	# smtp proxies. The function calls darknets_i2p__enable_pop_smtp if i2p does
	# not have it's proxies enabled.

	jail_name="$1"
	
	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "darknets_i2p__add_jail_i2p_pop_smtp_rules was called on $jail_name
but that jail does not exist."
		return 1
	fi

	if !
		cat /usr/shew/install/resources/ports \
			| grep 'i2p_pop=' \
			> /dev/null \
		&& \
			cat /usr/shew/install/resources/ports \
				| grep 'i2p_smtp=' \
				> /dev/null
	then
		darknets_i2p__enable_pop_smtp
	fi

	ip="`jail_maint_utils__return_jail_ip "$jail_name"`"
	loopback="`misc_utils__echo_var /usr/shew/install/resources/loopbacks i2p`"

	misc_utils__add_clause /etc/pf.conf '## Route-to:' \
		"# Added by darknets_i2p__add_jail_i2p_pop_smtp_rules for ${jail_name}:\\
		pass out route-to lo$loopback inet proto tcp from $ip to 127.0.0.0/8 port 7654\\
		pass out route-to lo$loopback inet proto tcp from $ip to 127.0.0.0/8 port 7659"
	pfctl -f /etc/pf.conf
}
