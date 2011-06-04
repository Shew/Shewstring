#!/bin/sh

# This script will change the MAC address of all interfaces if the variable
# expire_time, contained in config_file, is less than the current date. If
# config_file does not exist, the MAC addresses are changed anyway. Once the
# addresses are changed, a new expire_time value is created that is a random
# number between $expire_time_minimum and $expire_time_maximum (which is
# formtted in epoch time). Once finished, $expire_time and the MAC address
# values are written to $config_file. If the current date is not greater than
# $expire_time, the MAC addresses will be read from $config_file and their
# interfaces will be changed to the MAC addresses in it. To change the MAC
# address the interface is looked up in $wired_interface_list and then
# $wireless_interface_list. If it is detected as wired, an OUI is chosen at
# random from the wired_oui_list and a random NIC specifier is appended. If it
# is detected as wiredless, an OUI is chosen at random from the
# wiredless_oui_list and a random NIC specifier is appended. If the interface
# is not detected in either list, it will be ignored. The interface lists were
# copied from the BSD man pages. The OUI lists were copied from macchanger:
# http://www.alobbs.com/macchanger

# Variable defaults:
  : ${wired_interface_list="/usr/shew/permanent/root/mac_changer/interface_wired"}
						# A list of wired interfaces.
  : ${wireless_interface_list="/usr/shew/permanent/root/mac_changer/interface_wireless"}
						# A list of wireless interfaces.
  : ${wired_oui_list="/usr/shew/permanent/root/mac_changer/oui_all"}
						# A list of normal (wired) OUIs to choose from.
  : ${wireless_oui_list="/usr/shew/permanent/root/mac_changer/oui_wireless"}
						# A list of wireless OUIs to choose from.
  : ${config_file="/usr/shew/sensitive/host/root/mac_changer/config"}
						# The config file which holds expire_time and previous MAC addresses.
  : ${expire_time_minimum="604800"}		# The minimum time from now to make expire_time (604800 is a week).
  : ${expire_time_maximum="1209600"}		# The maximum time from now to make expire_time (1209600 is two weeks).

# Execute:

if [ `id -u` -ne 0 ]; then
	echo 'You must run this script as root for it to complete successfully.'
	exit 1
fi

current_date="`date -j -f "%a %b %d %T %Z %Y" "\`date\`" "+%s"`"
	# This command is listed in date(8) as a method to express the current date in
	# epoch time.

if [ -f "$config_file" ]; then
	. "$config_file"
else
	expire_time='0'
fi

if [ "$current_date" -gt "$expire_time" ]; then
	rm -Pf "$config_file"

	for val in \
		`
			ifconfig -l
		`
	do
		interface_type="`
			echo "$val" \
			| sed 's/[0-9]*$//'
		`"

		if
			cat "$wired_interface_list" \
				| grep -x "$interface_type" \
				> /dev/null
		then
			list="$wired_oui_list"
		elif
			cat "$wireless_interface_list" \
				| grep -x "$interface_type" \
				> /dev/null
		then
			list="$wireless_oui_list"
		else
			continue
		fi

		num_lines="`
			cat "$list" \
			| wc -l
		`"

		random_line="`jot -r 1 1 "$num_lines"`"

		oui="`
			cat "$list" \
				| head -n "$random_line" \
				| tail -n 1 \
				| sed -E 's/(..) (..) (..) .*/\1:\2:\3/'
		`"

		nic_specifier="`
			dd if=/dev/random count=2 \
				2> /dev/null \
				| md5 \
				| sed -E 's/(..)(..)(..).*/\1:\2:\3/'
		`"

		echo "Changing interface $val to MAC address ${oui}:${nic_specifier}."

		ifconfig "$val" down
		ifconfig "$val" ether "${oui}:$nic_specifier"
		ifconfig "$val" up

		if [ "$interfaces" ]; then
			interfaces="$interfaces $val"
		else
			interfaces="$val"
		fi

		echo "${val}=\"${oui}:${nic_specifier}\"" \
			>> "$config_file"
	done

	echo "interfaces=\"${interfaces}\"" \
		>> "$config_file"

	expire_interval="`jot -r 1 "$expire_time_minimum" "$expire_time_maximum"`"

	expire_time="`expr "$current_date" + "$expire_interval"`"

	echo "expire_time=\"${expire_time}\"" \
		>> "$config_file"
else
	for val in $interfaces; do
		mac_address="`eval "echo \$\"${val}\"`"

		echo "Changing interface $val to MAC address ${mac_address}."

		ifconfig "$val" down
		ifconfig "$val" ether "$mac_address"
		ifconfig "$val" up
	done
fi
