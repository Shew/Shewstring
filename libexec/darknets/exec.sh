#!/bin/sh

# This script will perform a basic install of things contained within the host
# scripts. The default settings will not install the GUI interfaces for the
# darknets (such as vidalia and firefox); they must be installed by calling the
# functions directly. The default settings will also not configure user tunnels
# for i2p, fproxy for freenet, tor ports, or the specialized patched tor
# installs.

# Libraries:
  . /usr/shew/install/shewstring/lib/misc_utils.sh
  . /usr/shew/install/shewstring/lib/ports_pkgs_utils.sh
  . /usr/shew/install/shewstring/lib/user_maint_utils.sh
  . /usr/shew/install/shewstring/lib/jail_maint_utils.sh
  . /usr/shew/install/shewstring/libexec/darknets/tor.sh
  . /usr/shew/install/shewstring/libexec/darknets/java.sh
  . /usr/shew/install/shewstring/libexec/darknets/i2p.sh
  . /usr/shew/install/shewstring/libexec/darknets/freenet.sh

# Execute:

echo
shew__current_script='libexec/darknets/exec.sh'
misc_utils__echo_progress

misc_utils__save_progress \
	&& {
		echo '
Installing the nat_darknets jail, which will hold Tor, I2P, Freenet and their
GUI interfaces.'
		misc_utils__prompt_continue

		echo
		jail_maint_utils__create_jail nat_darknets
	}

misc_utils__save_progress \
	&& {
		echo '
Locking down the nat_darknets jail.'
		misc_utils__prompt_continue

		echo
		jail_maint_utils__lockdown_jail nat_darknets
	}

misc_utils__save_progress \
	&& {
		echo '
Creating special folders for nat_darknets.'
		misc_utils__prompt_continue

		echo
		jail_maint_utils__create_home nat_darknets
		jail_maint_utils__create_permanent nat_darknets
		jail_maint_utils__create_sensitive nat_darknets
		jail_maint_utils__create_data nat_darknets
	}

misc_utils__save_progress \
	&& {
		echo '
Creating NAT PF rules for nat_darknets.'
		misc_utils__prompt_continue

		echo
		. /usr/shew/install/shewstring/libexec/host/network.sh
		host_network__add_jail_nat_rules nat_darknets
	}

misc_utils__save_progress \
	&& {
		echo '
Configuring the nat_darknets resolver to use the local DNS server.'
		misc_utils__prompt_continue

		echo
		. /usr/shew/install/shewstring/libexec/host/dns.sh
		host_dns__add_jail_dns_rules nat_darknets
	}

misc_utils__save_progress \
	&& {
		echo '
Installing Tor.'
		misc_utils__prompt_continue

		echo
		darknets_tor__install_tor
	}

misc_utils__save_progress \
	&& {
		echo '
Configuring the tor_normal instance of Tor.'
		misc_utils__prompt_continue

		echo
		darknets_tor__configure_tor_normal
	}

misc_utils__save_progress \
	&& {
		echo "
Downloading the Sun JDK. Unfortunately, OpenJDK cannot be compiled without
Sun's JDK, though the Sun JDK is not actually used to run Java programs. This
is the only piece of proprietary software in Shewstring. =("
		misc_utils__prompt_continue

		echo
		darknets_java__download_sun_jdk
	}

misc_utils__save_progress \
	&& {
		echo '
Compiling the Sun JDK.'
		misc_utils__prompt_continue

		echo
		darknets_java__compile_sun_jdk
	}

misc_utils__save_progress \
	&& {
		echo '
Using the Sun JDK to compile and install OpenJDK in the nat_darknets jail.'
		misc_utils__prompt_continue

		echo
		darknets_java__install_openjdk
	}

misc_utils__save_progress \
	&& {
		echo '
Installing I2P.'
		misc_utils__prompt_continue

		echo
		darknets_i2p__install_i2p
	}

misc_utils__save_progress \
	&& {
		echo '
Installing Freenet.'
		misc_utils__prompt_continue

		echo
		darknets_freenet__install_freenet
	}
