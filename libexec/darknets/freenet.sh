#!/bin/sh

# The Freenet home page: http://freenetproject.org/

# Requires:	lib/misc_utils.sh
#		lib/user_maint_utils.sh

# Contents:	darknets_freenet__install_freenet
#		darknets_freenet__enable_fcp
#		darknets_freenet__enable_http
#		darknets_freenet__add_jail_freenet_http_rules

# Variable defaults:
  : ${darknets_freenet__freenet_websites='http://downloads.freenetproject.org/alpha/installer/'}
								# The website(s) hosting the freenet installer.
  : ${darknets_freenet__freenet_file='freenet07.tar.gz'}	# The filename of the freenet installer.
  : ${darknets_freenet__freenet_sha256='f66a8e8d55fbbf5d88b1272ac09caedc356a347afd6f1853fb7915bb23e1daba'}
								# The sha256 hash of the freenet installer.
  : ${darknets_freenet__freenet_configs='/usr/shew/install/shewstring/libexec/darknets/misc/freenet'}
								# This file is the default freenet folder for config files.
  : ${darknets_freenet__rcd_freenet='/usr/shew/install/shewstring/libexec/darknets/rc.d/shew_freenet'}
								# This file is the default freenet rc.d file.
  : ${darknets_freenet__store_fraction='2'}			# The fraction of /usr/shew/data used by the freenet
								# data store. NOTE: this is the denominator, so 2 is 50%.

darknets_freenet__install_freenet() {
	# This function will install and configure freenet. fcp and fproxy are disabled
	# by default, and must be enabled by other functions. If this task has already
	# been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_freenet__install_freenet ]; then
		echo "darknets_freenet__install_freenet was called but it has already been run,
skipping."
		return 0
	fi

	if [ ! -d "$darknets_freenet__freenet_configs" ]; then
		echo "darknets_freenet__install_freenet could not find a critical install file. It
should be:
	$darknets_freenet__freenet_configs"
		return 1
	fi

	if [ ! -f "$darknets_freenet__rcd_freenet" ]; then
		echo "darknets_freenet__install_freenet could not find a critical install file. It
should be:
	$darknets_freenet__rcd_freenet"
		return 1
	fi

	user_maint_utils__add_jail_user nat_darknets freenet none home permanent sensitive data
	chroot /usr/shew/jails/nat_darknets \
		pw usermod -n freenet -s /sbin/nologin

	export misc_utils__sha256="$darknets_freenet__freenet_sha256"
	misc_utils__fetch "$darknets_freenet__freenet_file" "$darknets_freenet__freenet_websites"

	cd /usr/shew/jails/nat_darknets/usr/shew/permanent
	tar -x -f /usr/shew/install/fetch/"$darknets_freenet__freenet_file"

	chroot /usr/shew/jails/nat_darknets \
		chown -R freenet:freenet /usr/shew/permanent/freenet

	physmem="`sysctl hw.physmem`"

	cp -f /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/run.sh \
		/usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/run.sh.tmp
	cat /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/run.sh.tmp \
		| sed "s/uname -m/echo ${shew__architecture}/" \
		| sed 's/uname -s/echo FreeBSD/' \
		| sed 's/uname/echo FreeBSD/' \
		| sed "s/sysctl hw.physmem/echo \"${physmem}\"/" \
		| sed 's/CHANGED=true/CHANGED=""; REALPATH="$SCRIPT"/' \
		| sed 's|eval $NO_WRAPPER|& > /home/freenet/logs/rc.d.log 2>\&1 \&|' \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/run.sh
	rm -f /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/run.sh.tmp
		# uname is disabled by jail_maint_utils__lockdown_jail, sysctl is made root
		# only, the CHANGED line prevents Freenet from detecting the difference
		# between the real path and the symbolic links (which would normally prevent
		# symbolic links from working properly), the eval line will daemonize Freenet.

	cp -f /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/bin/1run.sh \
		/usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/bin/1run.sh.tmp
	cat /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/bin/1run.sh.tmp \
		| sed 's/uname -s/echo FreeBSD/' \
		| sed 's|./run.sh start|# $|' \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/bin/1run.sh
	rm -f /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/bin/1run.sh.tmp
		# Library is added to the list of plugins and running the node is disabled.

	# Disabled because plugins don't work:
	#	| sed 's/"pluginmanager.loadplugin=.*"/"pluginmanager.loadplugin=Library;JSTUN;UPnP"/' \
	#
	#misc_utils__add_clause /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/bin/1run.sh \
	#	'echo "pluginmanager.loadplugin=Library;JSTUN;UPnP" >> freenet.ini' \
	#	'echo "Downloading the Library plugin"\
	#	java $JOPTS -jar bin/sha1test.jar Library.jar plugins "$CAFILE" >/dev/null 2>&1'
	# These lines mimic other plugin download lines.

	jid="`jail_maint_utils__return_jail_jid nat_darknets`"

	echo 'Installing Freenet. (Log is named freenet):'
	misc_utils__condense_output_start /usr/shew/install/log/freenet

	jexec "$jid" \
		sh "-$-" -c '
			cd /usr/shew/permanent/freenet
			su -m freenet -c \
				/usr/shew/permanent/freenet/bin/1run.sh
		' \
	>> /usr/shew/install/log/freenet \
	2>> /usr/shew/install/log/freenet
	misc_utils__condense_output_end

	cp -f /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/update.sh \
		/usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/update.sh.old
	echo '#!/bin/sh
echo "$0 has been replaced by a dummy script." >&2
return 0
' > /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/update.sh
	chmod 0555 /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/update.sh

	jexec "$jid" \
		sh "-$-" -c '
			chmod 0550 /usr/shew/permanent/freenet

			mkdir -p \
				/usr/shew/copy_to_mfs/home/freenet/downloads \
				/usr/shew/copy_to_mfs/home/freenet/freenet/temp \
				/usr/shew/copy_to_mfs/home/freenet/freenet \
				/usr/shew/copy_to_mfs/home/freenet/logs \
				/usr/shew/data/freenet/datastore \
				/usr/shew/sensitive/freenet/certs \
				/usr/shew/sensitive/freenet/node \
				/usr/shew/sensitive/freenet/user

			rm -Rf \
				/usr/shew/permanent/freenet/datastore \
				/usr/shew/permanent/freenet/downloads \
				/usr/shew/permanent/freenet/logs

			ln -s /usr/shew/permanent/freenet/* /usr/shew/copy_to_mfs/home/freenet/freenet
			ln -s /usr/shew/permanent/freenet/.isInstalled \
				/usr/shew/copy_to_mfs/home/freenet/freenet/.isInstalled

			ln -s /home/freenet/logs /usr/shew/copy_to_mfs/home/freenet/freenet/logs
			ln -s /home/freenet/logs /usr/shew/permanent/freenet/logs

			ln -s /usr/shew/permanent/freenet/seednodes.fref /usr/shew/sensitive/freenet/node/seednodes.fref

			chown freenet:freenet \
				/usr/shew/copy_to_mfs/home/freenet/downloads \
				/usr/shew/copy_to_mfs/home/freenet/freenet/temp \
				/usr/shew/copy_to_mfs/home/freenet/freenet \
				/usr/shew/copy_to_mfs/home/freenet/logs \
				/usr/shew/data/freenet/datastore \
				/usr/shew/sensitive/freenet/certs \
				/usr/shew/sensitive/freenet/node \
				/usr/shew/sensitive/freenet/user
		'

	chmod -h 0444 \
		/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/freenet/freenet/* \
		/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/freenet/freenet/.isInstalled \
		/usr/shew/jails/nat_darknets/usr/shew/sensitive/freenet/node/seednodes.fref
	chmod 0777 \
		/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/freenet/downloads \
		/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/freenet/freenet/temp
	chflags -h schg \
		/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/freenet/freenet/* \
		/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/freenet/freenet/.isInstalled \
		/usr/shew/jails/nat_darknets/usr/shew/sensitive/freenet/node/seednodes.fref
	chflags noschg \
		/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/freenet/downloads \
		/usr/shew/jails/nat_darknets/usr/shew/copy_to_mfs/home/freenet/freenet/temp

	fnet_ip="`jail_maint_utils__return_jail_ip nat_darknets`"

	fopen_port="`misc_utils__generate_unique_port`"
	echo "freenet_opennet_external=\"${fopen_port}\"" \
		>> /usr/shew/install/resources/ports

	fdark_port="`misc_utils__generate_unique_port`"
	echo "freenet_darknet_external=\"${fdark_port}\"" \
		>> /usr/shew/install/resources/ports

	freenet_store_size="`
		df -k /usr/shew/data \
			| tail -n 1 \
			| sed 's|/dev/[a-z0-9]*\.[a-z0-9]* *[0-9]* *[0-9]* *||' \
			| sed 's/ *[0-9]*%.*//'
	`"
	freenet_store_size="`expr "$freenet_store_size" / "$darknets_freenet__store_fraction"`KiB"

	cat "$darknets_freenet__freenet_configs"/freenet.ini \
		| sed "s/node.opennet.listenPort=/node.opennet.listenPort=${fopen_port}/" \
		| sed "s/node.storeSize=/node.storeSize=${freenet_store_size}/" \
		| sed "s/node.listenPort=/node.listenPort=${fdark_port}/" \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/freenet.ini

	chflags noschg /usr/shew/sensitive/nat_darknets/freenet.allow
	echo 'certs
master\.keys
node
node/node-[0-9]*
node/opennet-[0-9]*
node/openpeers-[0-9]*
node/openpeers-old-[0-9]*
node/peers-[0-9]*
node/seednodes\.fref
user
user/bookmarks\.dat
user/prng\.seed' \
		>> /usr/shew/sensitive/nat_darknets/freenet.allow
	chflags schg /usr/shew/sensitive/nat_darknets/freenet.allow

	misc_utils__add_clause /etc/pf.conf '## Redirect External:' \
		"# Added by darknets_freenet__install_freenet for freenet:\\
		rdr pass on \$interfaces inet proto udp from !127.0.0.0/8 to port $fopen_port -> $fnet_ip port ${fopen_port}\\
		rdr pass on \$interfaces inet proto udp from !127.0.0.0/8 to port $fdark_port -> $fnet_ip port $fdark_port"
	pfctl -f /etc/pf.conf

	cp -f "$darknets_freenet__rcd_freenet" /usr/shew/jails/nat_darknets/etc/rc.d/shew_freenet
	chmod 0500 /usr/shew/jails/nat_darknets/etc/rc.d/shew_freenet

	echo '
# Added by darknets_freenet__install_freenet for freenet:
shew_freenet_enable="YES"
' >> /usr/shew/jails/nat_darknets/etc/rc.conf

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_freenet__install_freenet
}


darknets_freenet__enable_fcp() {
	# This function will enable fcp on freenet. If this task has already been done,
	# the function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_freenet__enable_fcp ]; then
		echo "darknets_freenet__enable_fcp was called but it has already been run, skipping."
		return 0
	fi

	freenet_ip="`jail_maint_utils__return_jail_ip nat_darknets`"

	freenet_port="`misc_utils__generate_unique_port`"
	echo "freenet_fcp=\"${freenet_port}\"" \
		>> /usr/shew/install/resources/ports

	cp -f /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/freenet.ini \
		/usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/freenet.ini.tmp
	cat /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/freenet.ini.tmp \
		| sed "s/fcp.enabled=false/fcp.enabled=true/" \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/freenet.ini
	rm -f /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/freenet.ini.tmp

	misc_utils__add_clause /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/freenet.ini '## Additional entries:' \
		"# Added by darknets_freenet__enable_fcp for fcp:\\
		fcp.port=${freenet_port}\\
		fcp.allowedHosts=*\\
		fcp.persistentDownloadsEnabled=true\\
		fcp.ssl=false\\
		fcp.bindTo=${freenet_ip}\\
		fcp.allowedHostsFullAccess=${freenet_ip}"

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_freenet__enable_fcp
}

darknets_freenet__enable_http() {
	# This function will enable the http proxy on freenet. If this task has already
	# been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_freenet__enable_http ]; then
		echo "darknets_freenet__enable_http was called but it has already been run, skipping."
		return 0
	fi

	ip="`jail_maint_utils__return_jail_ip nat_darknets`"

	port="`misc_utils__generate_unique_port`"
	echo "freenet_http=\"${port}\"" \
		>> /usr/shew/install/resources/ports

	cp -f /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/freenet.ini \
		/usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/freenet.ini.tmp
	cat /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/freenet.ini.tmp \
		| sed "s/fproxy.enabled=false/fproxy.enabled=true/" \
		> /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/freenet.ini
	rm -f /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/freenet.ini.tmp

	misc_utils__add_clause /usr/shew/jails/nat_darknets/usr/shew/permanent/freenet/freenet.ini '## Additional entries:' \
		"# Added by darknets_freenet__enable_http for http:\\
		fproxy.port=${port}\\
		fproxy.allowedHosts=*\\
		fproxy.doRobots=true\\
		fproxy.publicGatewayMode=true\\
		fproxy.showPanicButton=false\\
		fproxy.ssl=false\\
		fproxy.bindTo=${ip}\\
		fproxy.allowedHostsFullAccess=${ip}\\
		fproxy.noConfirmPanic=false\\
		fproxy.hasCompletedWizard=true"

	loopback="`misc_utils__generate_unique_loopback`"
	echo "freenet=\"${loopback}\"" \
		>> /usr/shew/install/resources/loopbacks

	cloned_interfaces="`misc_utils__echo_var /etc/rc.conf cloned_interfaces`"
	misc_utils__change_var /etc/rc.conf cloned_interfaces "$cloned_interfaces lo$loopback"

	misc_utils__add_clause /etc/pf.conf '## Redirect Internal:' \
		"# Added by darknets_freenet__enable_http for FProxy:\\
		rdr pass on lo$loopback inet proto tcp from 127.0.0.0/8 to 127.0.0.0/8 port 8888 -> $ip port $port"
	pfctl -f /etc/pf.conf

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_freenet__enable_http
}

darknets_freenet__add_jail_freenet_http_rules() {
	# This function will add the pf rules that allow a jail to use freenet's http
	# proxy. The function calls darknets_freenet__enable_http if freenet does not
	# have it's proxy enabled.

	jail_name="$1"
	
	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "darknets_freenet__add_jail_freenet_http_rules was called on $jail_name
but that jail does not exist."
		return 1
	fi

	if !
		cat /usr/shew/install/resources/ports \
			| grep 'freenet_http=' \
			> /dev/null
	then
		darknets_freenet__enable_http
	fi

	ip="`jail_maint_utils__return_jail_ip "$jail_name"`"
	loopback="`misc_utils__echo_var /usr/shew/install/resources/loopbacks freenet`"

	misc_utils__add_clause /etc/pf.conf '## Route-to:' \
		"# Added by darknets_freenet__add_jail_freenet_http_rules for FProxy:\\
		pass out route-to lo$loopback inet proto tcp from $ip to 127.0.0.0/8 port 8888"
	pfctl -f /etc/pf.conf
}
