#!/bin/sh

# This script will perform a basic install of things contained within the host
# scripts. The default settings should be fine for most installers.

# Arguments:
  root_password="$arg_1"
  guest_password="$arg_2"
  unset arg_1 arg_2

# Libraries:
  . /usr/shew/install/shewstring/lib/misc_utils.sh
  . /usr/shew/install/shewstring/lib/user_maint_utils.sh
  . /usr/shew/install/shewstring/libexec/host/configure.sh
  . /usr/shew/install/shewstring/libexec/host/network.sh
  . /usr/shew/install/shewstring/libexec/host/ntp.sh
  . /usr/shew/install/shewstring/libexec/host/dns.sh
  . /usr/shew/install/shewstring/libexec/host/entropy.sh
  . /usr/shew/install/shewstring/libexec/host/audit.sh

# Execute:

echo
shew__current_script='libexec/host/exec.sh'
misc_utils__echo_progress

misc_utils__save_progress \
	&& {
		echo '
Adding and configuring basic configuration files needed to run the system, as
well as some other misc. system configuration files.'
		misc_utils__prompt_continue

		echo
		host_configure__misc_configuration
	}

misc_utils__save_progress \
	&& {
		echo "
Adding special folders: home, permanent, sensitive, and data. These are where
each program's files are separated into those that are static, those that are
temporary, and those that are kept through rebooting."
		misc_utils__prompt_continue

		echo
		host_configure__add_special_folders
	}

misc_utils__save_progress \
	&& {
		echo '
Configuring the root user and its special folders.'
		misc_utils__prompt_continue

		echo
		host_configure__configure_root_user "$root_password"
	}

misc_utils__save_progress \
	&& {
		echo '
Configuring the guest user and its special folders; guest is the default login
user.'
		misc_utils__prompt_continue

		echo
		host_configure__configure_guest_user "$guest_password"
	}

misc_utils__save_progress \
	&& {
		echo '
Installing the MAC changer. This will change the MAC address of the computer to
a new random one which will expire at a random interval between one and two
weeks in length, by default.'
		misc_utils__prompt_continue

		echo
		host_network__install_mac_changer
	}

misc_utils__save_progress \
	&& {
		echo '
Running the MAC changer. This will ensure that the MAC is disguised for the
installation.'
		misc_utils__prompt_continue

		echo
		/usr/shew/permanent/root/mac_changer/mac_changer.sh

		rm -Pf /usr/shew/sensitive/host/root/mac_changer/config
			# This ensures that the MAC is randomized again after the installation
			# completes.
	}

misc_utils__save_progress \
	&& {
		echo '
Unblocking network interfaces.'
		misc_utils__prompt_continue

		echo
		host_network__unblock_all_interfaces
	}

misc_utils__save_progress \
	&& {
		echo '
Passing DHclient traffic and attempting to bring up a wired interface and
configure it with DHclient.'
		misc_utils__prompt_continue

		echo

		misc_utils__add_clause /etc/pf.conf '## Pass Host:' \
			'# Added by host_network__unblock_all_interfaces for dhclient:\
			pass quick inet proto udp from !127.0.0.0/8 to !127.0.0.0/8 port 67\
			pass quick inet proto udp from !127.0.0.0/8 to !127.0.0.0/8 port 68'
		pfctl -f /etc/pf.conf

		cp -f /etc/dhclient.conf /etc/dhclient.conf.old

		cat /etc/dhclient.conf.old \
			| sed 's/supersede domain-name-servers/#&/' \
			> /etc/dhclient.conf
		# This is needed since the DNSSEC enabled DNS server will not work until the
		# computer has the proper time, which requires DNS resolution.

		host_network__bring_up_interface

		cp -f /etc/dhclient.conf.old /etc/dhclient.conf
		rm -f /etc/dhclient.conf.old
	}

misc_utils__save_progress \
	&& {
		echo '
Configuring the network time server. Setting the correct time via NTP.'
		misc_utils__prompt_continue

		echo

		host_ntp__install_ntpd

		echo 'pass quick inet proto udp from !127.0.0.0/8 to !127.0.0.0/8 port 53' \
			| pfctl -m -f -
		ntpd -gqx -c /etc/ntp.conf
		/etc/rc.d/shew_ntpd start
	}

misc_utils__save_progress \
	&& {
		echo '
Configuring and starting the DNS server. This will provide authenticated DNS
resolutions via the DNS security extensions (DNSSEC).'
		misc_utils__prompt_continue

		echo

		host_dns__install_named

		/etc/rc.d/shew_named start

		ip="`
			cat /etc/hosts \
				| grep 'named named.my.domain *$' \
				| tail -n 1 \
				| sed 's/ named.*//'
		`"

		echo "nameserver $ip" \
			> /etc/resolv.conf
		chmod 0444 /etc/resolv.conf
		chflags schg /etc/resolv.conf
	}

misc_utils__save_progress \
	&& {
		echo '
Installing any updates to the system that are availible.'
		misc_utils__prompt_continue

		echo 'pass quick inet proto tcp from !127.0.0.0/8 to !127.0.0.0/8 port 80' \
			| pfctl -m -f -

		echo '
Updating the system. (Log is named update_host):'
		misc_utils__condense_output_start /usr/shew/install/log/update_host

		freebsd-update fetch install \
			>> /usr/shew/install/log/update_host \
			2>> /usr/shew/install/log/update_host

		misc_utils__condense_output_end

		pfctl -f /etc/pf.conf
	}

misc_utils__save_progress \
	&& {
		echo '
Adding entropy directory, and configuring entropy collection.'
		misc_utils__prompt_continue

		echo
		host_entropy__install_entropy
		/etc/rc.d/shew_entropy start
	}

misc_utils__save_progress \
	&& {
		echo '
Configuring the audit script. This will ensure that all unauthorized files in
sensitive (where programs store their files to be kept between reboots) are
cleared when shutting down the computer.'
		misc_utils__prompt_continue

		echo
		host_audit__install_audit
	}
