#!/bin/sh

# Requires:	lib/misc_utils.sh

# Contents:	host_network__install_mac_changer
#		host_network__unblock_all_interfaces
#		host_network__bring_up_interface
#		host_network__add_jail_nat_rules

# Variable defaults:
  : ${host_network__network="/usr/shew/install/shewstring/libexec/host/misc/network"}
							# This file is the default network folder for config files.
  : ${host_network__rcd_mac_changer="/usr/shew/install/shewstring/libexec/host/rc.d/shew_mac_changer"}
							# This file is the default mac_changer rc.d file.

host_network__install_mac_changer() {
	# This function will install and configure the MAC address changer. See
	# mac_changer.sh in $host_network__network for an extensive description of
	# what it does. If this task has already been done, the function complains and
	# returns true.

	if [ -f /usr/shew/install/done/host_network__install_mac_changer ]; then
		echo "host_network__install_mac_changer was called but it has already been run,
skipping."
		return 0
	fi

	if [ ! -d "$host_network__network" ]; then
		echo "host_network__install_mac_changer could not find a critical install file. It
should be:
	$host_network__network"
		return 1
	fi

	if [ ! -f "$host_network__rcd_mac_changer" ]; then
		echo "host_network__install_mac_changer could not find a critical install file. It
should be:
	$host_network__rcd_mac_changer"
		return 1
	fi

	mkdir -p /usr/shew/permanent/root/mac_changer
	cp -Rf "$host_network__network"/ /usr/shew/permanent/root/mac_changer
	chmod 0500 /usr/shew/permanent/root/mac_changer
	chmod 0400 /usr/shew/permanent/root/mac_changer/*
	chmod 0500 /usr/shew/permanent/root/mac_changer/mac_changer.sh

	mkdir -p /usr/shew/sensitive/host/root/mac_changer
	chmod 0700 /usr/shew/sensitive/host/root/mac_changer

	chflags noschg /usr/shew/sensitive/host/root.allow
	echo 'mac_changer
mac_changer/config' \
		>> /usr/shew/sensitive/host/root.allow
	chflags schg /usr/shew/sensitive/host/root.allow

	cp -f "$host_network__rcd_mac_changer" /etc/rc.d/shew_mac_changer
	chmod 0500 /etc/rc.d/shew_mac_changer

	echo '
# Added by host_network__install_mac_changer for mac_changer:
shew_mac_changer_enable="YES"
' >> /etc/rc.conf

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/host_network__install_mac_changer
}

host_network__unblock_all_interfaces() {
	# This function will attempt to detect network interfaces and set them up for
	# scripts to unblock later. The interface names are stored in the pf macro
	# interfaces for use by pf rules. If this task has already been done, the
	# function complains and returns true.

	if [ -f /usr/shew/install/done/host_network__unblock_all_interfaces ]; then
		echo "host_network__unblock_all_interfaces was called but it has already been run,
skipping."
		return 0
	fi

	if [ ! -d "$host_network__network" ]; then
		echo "host_network__install_mac_changer could not find a critical install file. It
should be:
	$host_network__network"
		return 1
	fi

	wlan_number='0'
	interfaces=''
	for val in \
		`
			ifconfig -l
		`
	do
		if
			echo "$val" \
				| grep \
					`
						cat "$host_network__network"/interface_wired \
							| sed 's/^/ -e /' \
							| sed 's/$/\[0-9\]\*/'
					` \
				> /dev/null
		then
			if [ -z "$interfaces" ]; then
				interfaces="$val"
			else
				interfaces="${interfaces}, $val"
			fi
		fi

		if
			echo "$val" \
				| grep \
					`
						cat "$host_network__network"/interface_wireless \
							| sed 's/^/ -e /' \
							| sed 's/$/\[0-9\]\*/'
					` \
				> /dev/null
		then
			if [ -z "$interfaces" ]; then
				interfaces="$val"
			else
				interfaces="${interfaces}, $val"
			fi

			if !
				cat /etc/rc.conf \
					| grep '# Added by host_network__unblock_all_interfaces for wlan:' \
					> /dev/null
			then
				echo '
# Added by host_network__unblock_all_interfaces for wlan:' \
					>> /etc/rc.conf
			fi

			echo "wlans_${val}=\"wlan${wlan_number}\"" \
				>> /etc/rc.conf

			wlan_number="`expr "$wlan_number" + 1`"
		fi
	done

	if [ -z "$interfaces" ]; then
		echo 'host_network__unblock_all_interfaces detected no useable network interfaces!'
		exit 1
	fi

	misc_utils__add_clause /etc/pf.conf '## Macros:' \
		"# Added by host_network__unblock_all_interfaces:\\
		interfaces = \"{ $interfaces }\""

	misc_utils__add_clause /etc/pf.conf '## Scrub:' \
		'# Added by host_network__unblock_all_interfaces:\
		scrub in on $interfaces'

	pfctl -f /etc/pf.conf

	if [ ! -d /usr/shew/install/done ]; then
		mkdir -p /usr/shew/install/done
		chmod 0700 /usr/shew/install/done
	fi

	touch /usr/shew/install/done/host_network__unblock_all_interfaces
}

host_network__bring_up_interface() {
	# This function will select an available wired interface and bring it up via
	# DHCP. The interfaces are tested in alphabetical order. If there are no wired
	# interfaces available, or DHCP fails for all the wired interfaces, the user
	# will be prompted to connect one. Wireless is not supported by this method,
	# since configuring a wireless interface is usually more involved.

	if [ ! -d "$host_network__network" ]; then
		echo "host_network__install_mac_changer could not find a critical install file. It
should be:
	$host_network__network"
		return 1
	fi

	while true; do
		for val in \
			`
				ifconfig -l
			`
		do
			if
				echo "$val" \
					| grep \
						`
							cat "$host_network__network"/interface_wired \
								| sed 's/^/ -e /' \
								| sed 's/$/\[0-9\]\*/'
						` \
					> /dev/null
			then
				if
					dhclient "$val"
				then
					if !
						cat /etc/rc.conf \
							| grep "ifconfig_${val}=" \
							> /dev/null
					then
						echo "
# Added by host_network__bring_up_interface for dhclient:
ifconfig_${val}=\"DHCP\"
" >> /etc/rc.conf
					fi

					break 2
				else
					continue
				fi
			fi
		done

		echo 'No suitable wired network interface detected. Please connect a wired interface
that can be configured by DHCP.'

		echo 'Are you ready to continue? y/n'
		read answer

		until [ "$answer" = y -o "$answer" = n ]; do
			echo 'Please enter y or n.'
			read answer
		done

		if [ "$answer" = n ]; then
			echo 'The user exited host_network__bring_up_interface.'

			return 1
		fi
	done
}

host_network__add_jail_nat_rules() {
	# This function will add the pf rules that allow a jail to nat to the local
	# network.

	jail_name="$1"

	if [ ! -d /usr/shew/jails/"$jail_name" ]; then
		echo "host_network__add_jail_nat_rules was called on $jail_name but that
jail does not exist."
		return 1
	fi

	ip="`jail_maint_utils__return_jail_ip "$jail_name"`"
	interfaces="`
		cat /etc/pf.conf \
			| grep 'interfaces = ' \
			| sed 's/interfaces = "{ //' \
			| sed 's/ }"//'
	`"

	nats=''
	for val in $interfaces; do
		val="`
			echo "$val" \
				| sed 's/,//'
		`"

		if [ "$nats" ]; then
			nats="${nats}\\
nat pass on $val from $ip to !127.0.0.0/8 -> ( $val ) static-port"
		else
			nats="nat pass on $val from $ip to !127.0.0.0/8 -> ( $val ) static-port"
		fi
	done
		# This ugly hack is needed because PF does not support using macros in NAT
		# statements.

	misc_utils__add_clause /etc/pf.conf '## NAT:' \
		"# Added by host_network__add_jail_nat_rules for ${jail_name}:\\
		no nat on \$interfaces from $ip to 127.0.0.0/8\\
		$nats"
	pfctl -f /etc/pf.conf
}
