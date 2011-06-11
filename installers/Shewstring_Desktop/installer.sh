#!/bin/sh

# This script will install the Shewstring Desktop, see description.txt for more
# details.

# Libraries:
	if [ "$shew__using_fixit" != YES ]; then
		. /usr/shew/install/shewstring/lib/misc_utils.sh
		. /usr/shew/install/shewstring/lib/jail_maint_utils.sh
		. /usr/shew/install/shewstring/lib/ports_pkgs_utils.sh
		. /usr/shew/install/shewstring/lib/user_maint_utils.sh
	fi

# Execute:

echo
shew__current_script='installers/Shewstring_Desktop/installer.sh'
misc_utils__echo_progress

if [ "$shew__using_fixit" = YES ]; then
	misc_utils__move_down_save_progress \
		&& {
			echo '
Starting fixit/exec.sh, which will encrypt the hard drive, install BSD, etc.'
			misc_utils__prompt_continue

			if [ -f "`cat /tmp/thumbdrive_path`"/../ports.tar.gz ]; then
				latest_ports="`cat /tmp/thumbdrive_path`/../ports.tar.gz"
			else
				for val in "`cat /tmp/thumbdrive_path`"/../ports-*.tar.gz; do
					latest_ports="$val"
				done
			fi

			if [ ! -f "$latest_ports" ]; then
				echo "
Please place ports.tar.gz or ports-YYYYMMDD.tar.gz (where YYYYMMDD is the build
date of the tarball) into the same directory as Shewstring's folder."
				return 1
			fi

			echo

			arg_1="$installers_shewstring_desktop__thumbdrive_device"
			arg_2="$installers_shewstring_desktop__hard_drive_device"
			. "$shew__fixit_shewstring_installer_dir"/libexec/fixit/exec.sh
		}
	misc_utils__move_up_save_progress

	misc_utils__save_progress \
		&& {
			echo '
Installing some additional configuration files/options needed for Shewstring
Desktop.'
			misc_utils__prompt_continue

			echo

			echo '
# Added by Shewstring_Desktop/installer.sh for Shewstring Desktop:
snd_driver_load="YES"	# Sound driver.

atapicam_load="YES"	# CD/DVD burner driver.
hw.ata.atapi_dma="1"

wlan_scan_ap_load="YES"	# Wireless drivers.
wlan_scan_sta_load="YES"
wlan_wep_load="YES"
wlan_ccmp_load="YES"
wlan_tkip_load="YES"

autoboot_delay="5"	# Reduce boot delay to 3 seconds.
' >> /thumb/boot/loader.conf
			chmod 0400 /thumb/boot/loader.conf

			echo '
# Added by Shewstring_Desktop/installer.sh for Shewstring Desktop:
hint.pcm.0.pcm="100"
hint.vol.0.vol="85"
' >> /thumb/boot/device.hints
			chmod 0400 /thumb/boot/device.hints

			chflags -R schg /thumb
		}
fi

if [ "$shew__using_fixit" != YES ]; then
	stty -echo

	while true; do
		echo '
Please enter the value you want to use as your root (super-user/administrator)
password.'
		read root_password

		if [ -z "$root_password" ]; then
			echo 'Please do not use zero length passwords!'
			continue
		fi

		echo 'Please repeat your password.'
		read root_password_2

		if [ "$root_password" != "$root_password_2" ]; then
			echo 'The passwords were not equivalent.'
			continue
		fi

		break
	done

	while true; do
		echo '
Please enter the value you want to use as your guest (unprivileged) password.'
		read user_password

		if [ -z "$user_password" ]; then
			echo 'Please do not use zero length passwords!'
			continue
		fi

		echo 'Please repeat your password.'
		read user_password_2

		if [ "$user_password" != "$user_password_2" ]; then
			echo 'The passwords were not equivalent.'
			continue
		fi

		break
	done

	stty echo

	misc_utils__save_progress \
		&& {
			echo '
Remounting the root and usr partitions as read-write.'
			misc_utils__prompt_continue

			echo

			mount -u -o rw /
			mount -u -o rw /usr
		}

	misc_utils__move_down_save_progress \
		&& {
			echo '
Starting host/exec.sh, which will configure basic systems and services.'
			misc_utils__prompt_continue

			echo

			arg_1="$root_password"
			arg_2="$user_password"
			. /usr/shew/install/shewstring/libexec/host/exec.sh
		}
	misc_utils__move_up_save_progress

	misc_utils__save_progress \
		&& {
			echo '
Installing some additional configuration files/options needed for Shewstring
Desktop.'
			misc_utils__prompt_continue

			echo

			echo '
# Added by Shewstring_Desktop/installer.sh for Shewstring Desktop:
dev.pcm.0.play.vchans=6	# Set 6 virtual sound channels for /dev/dsp playing.
dev.pcm.0.rec.vchans=2	# Set 2 virtual sound channels for /dev/dsp recording.
' >> /etc/sysctl.conf
			chmod 0400 /etc/sysctl.conf

			echo '
# Added by Shewstring_Desktop/installer.sh for Shewstring Desktop:
notify 10 {
	match "system"		"ACPI";
	match "subsystem"	"Lid";
	match "notify"		"0x00";
	action "shutdown -p now";
};
	# This will shut down the computer if it has a lid, and the lid is closed. This
	# may protect the encrytion of the hard drive if it is stolen.
' >> /etc/devd.conf
			chmod 0400 /etc/devd.conf
		}

	misc_utils__save_progress \
		&& {
			echo '
Setting the correct time zone.'
			misc_utils__prompt_continue

			echo

			if [ "$installers_shewstring_desktop__time_zone_file_2" ]; then
				cat \
/usr/share/zoneinfo/"$installers_shewstring_desktop__time_zone_file_1"/"$installers_shewstring_desktop__time_zone_file_2" \
					> /etc/localtime
			else
				cat /usr/share/zoneinfo/"$installers_shewstring_desktop__time_zone_file_1" \
					> /etc/localtime
			fi

			chmod 0444 /etc/localtime
		}

	misc_utils__move_down_save_progress \
		&& {
			echo '
Starting x/exec.sh, which will configure Xorg.'
			misc_utils__prompt_continue

			echo
			. /usr/shew/install/shewstring/libexec/x/exec.sh
		}
	misc_utils__move_up_save_progress

# Commands for nat_darknets:

	misc_utils__save_progress \
		&& {
			echo '
Patching Tor to allow two hop tunnels and setting MaxCircuitDirtiness 0.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/darknets/tor.sh
			darknets_tor__patch_circuit_length
			darknets_tor__patch_circuit_dirtiness
		}

	misc_utils__move_down_save_progress \
		&& {
			echo '
Starting darknets/exec.sh, which will configure Tor, I2P and Freenet.'
			misc_utils__prompt_continue

			echo
			. /usr/shew/install/shewstring/libexec/darknets/exec.sh
		}
	misc_utils__move_up_save_progress

	misc_utils__save_progress \
		&& {
			echo '
Configuring the tor_two_hop and tor_zero_dirtiness instances of Tor.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/darknets/tor.sh
			darknets_tor__configure_tor_two_hop
			darknets_tor__configure_tor_zero_dirtiness
		}

	misc_utils__save_progress \
		&& {
			echo '
Enabling SOCKS proxies for Tor installs.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/darknets/tor.sh
			darknets_tor__enable_socks normal
			darknets_tor__enable_socks two_hop
			darknets_tor__enable_socks z_dirt
		}

	misc_utils__save_progress \
		&& {
			echo '
Enabling transparent proxies for Tor installs.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/darknets/tor.sh
			darknets_tor__enable_transparent normal
			darknets_tor__enable_transparent two_hop
			darknets_tor__enable_transparent z_dirt
		}

	misc_utils__save_progress \
		&& {
			echo '
Enabling I2P HTTP, HTTPS, SOCKS, IRC, POP and SMTP tunnels.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/darknets/i2p.sh
			darknets_i2p__enable_http_https
			darknets_i2p__enable_irc
			darknets_i2p__enable_pop_smtp
		}

	misc_utils__save_progress \
		&& {
			echo '
Enabling Freenet HTTP tunnel.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/darknets/freenet.sh
			darknets_freenet__enable_http
		}

# Commands for host:

	misc_utils__save_progress \
		&& {
			echo '
Installing and configuring Sudo.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/nojailed_nox/sudo.sh
			nojailed_nox_sudo__add_sudo_user guest
			nojailed_nox_sudo__lock_sudoers
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing the XFCE desktop manager and some associated programs: XConsole,
XLock, and Mixer.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/nojailed_x/xfce.sh
			. /usr/shew/install/shewstring/libexec/nojailed_x/xconsole.sh
			. /usr/shew/install/shewstring/libexec/nojailed_x/xlock.sh
			. /usr/shew/install/shewstring/libexec/nojailed_x/mixer.sh
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing desktop programs that require elevated privileges: Sane with NetPBM,
WPA GUI, and Xfburn. These are configured to use the same password as your
unpriveleged user (guest). WPA GUI is only installed if you have a wireless
interface.'
			misc_utils__prompt_continue

			echo

			arg_1="$user_password"
			. /usr/shew/install/shewstring/libexec/nojailed_x/sane.sh
			nojailed_x_sane__install_netpbm

			if
				cat /etc/rc.conf \
					| grep 'wlans_.*="wlan0"' \
					> /dev/null
			then
				arg_1="$user_password"
				. /usr/shew/install/shewstring/libexec/nojailed_x/wpa_gui.sh
			fi

			arg_1="$user_password"
			. /usr/shew/install/shewstring/libexec/nojailed_x/xfburn.sh
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing some misc. desktop programs: Abiword, Evince, File-roller,
Galculator, KeePass, Mousepad, Ristretto, Terminal and VLC.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/nojailed_x/abiword.sh
			. /usr/shew/install/shewstring/libexec/nojailed_x/evince.sh
			. /usr/shew/install/shewstring/libexec/nojailed_x/file_roller.sh
			. /usr/shew/install/shewstring/libexec/nojailed_x/galculator.sh
			. /usr/shew/install/shewstring/libexec/nojailed_x/keepass.sh
			. /usr/shew/install/shewstring/libexec/nojailed_x/mousepad.sh
			. /usr/shew/install/shewstring/libexec/nojailed_x/ristretto.sh
			. /usr/shew/install/shewstring/libexec/nojailed_x/terminal.sh
			. /usr/shew/install/shewstring/libexec/nojailed_x/vlc.sh
		}

# Commands for nat_darknets with desktop integration:

	misc_utils__save_progress \
		&& {
			echo '
Setting up X and Telnet for nat_darknets.'
			misc_utils__prompt_continue

			echo
			jail_maint_utils__allow_telnet nat_darknets
			jail_maint_utils__allow_x nat_darknets
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing Terminal for nat_darknets.'
			misc_utils__prompt_continue

			echo

			arg_1='nat_darknets'
			. /usr/shew/install/shewstring/libexec/jailed_x/terminal.sh
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing and configuring an instance of Vidalia for each Tor install.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/darknets/vidalia.sh
			darknets_vidalia__install_vidalia
			darknets_vidalia__configure_tor_normal_vidalia
			darknets_vidalia__configure_tor_two_hop_vidalia
			darknets_vidalia__configure_tor_zero_dirtiness_vidalia
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing and configuring Firefox to control I2P and Freenet.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/darknets/firefox.sh
			darknets_firefox__firefox_control_i2p
			darknets_firefox__firefox_control_freenet
		}

# Commands for nat_insecure:

	misc_utils__save_progress \
		&& {
			echo '
Installing the nat_insecure jail, which will hold Firefox with Gnash, and VLC.'
			misc_utils__prompt_continue

			echo
			jail_maint_utils__create_jail nat_insecure
		}

	misc_utils__save_progress \
		&& {
			echo '
Locking down the nat_insecure jail.'
			misc_utils__prompt_continue

			echo
			jail_maint_utils__lockdown_jail nat_insecure
		}

	misc_utils__save_progress \
		&& {
			echo '
Creating special folders for nat_insecure.'
			misc_utils__prompt_continue

			echo

			jail_maint_utils__create_home nat_insecure
			jail_maint_utils__create_permanent nat_insecure
			jail_maint_utils__create_sensitive nat_insecure
			jail_maint_utils__create_data nat_insecure
		}

	misc_utils__save_progress \
		&& {
			echo '
Setting up X, Telnet and sound for nat_insecure.'
			misc_utils__prompt_continue

			echo

			jail_maint_utils__allow_telnet nat_insecure
			jail_maint_utils__allow_x nat_insecure
			jail_maint_utils__allow_sound nat_insecure
		}

	misc_utils__save_progress \
		&& {
			echo '
Creating NAT PF rules for nat_insecure.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/host/network.sh
			host_network__add_jail_nat_rules nat_insecure
		}

	misc_utils__save_progress \
		&& {
			echo '
Configuring the nat_insecure resolver to use the local DNS server.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/host/dns.sh
			host_dns__add_jail_dns_rules nat_insecure
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing some misc. programs for nat_insecure: Abiword, Evince, Terminal, VLC.'
			misc_utils__prompt_continue

			echo

			arg_1='nat_insecure'
			. /usr/shew/install/shewstring/libexec/jailed_x/abiword.sh

			arg_1='nat_insecure'
			. /usr/shew/install/shewstring/libexec/jailed_x/evince.sh

			arg_1='nat_insecure'
			. /usr/shew/install/shewstring/libexec/jailed_x/terminal.sh

			arg_1='nat_insecure'
			. /usr/shew/install/shewstring/libexec/jailed_x/vlc.sh
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing Firefox with Gnash for nat_insecure. Also installing Addons:
Torbutton, Adblock, HTTPS Everywhere, Perspectives, and Beef TACO.'
			misc_utils__prompt_continue

			echo

			arg_1='nat_insecure'
			. /usr/shew/install/shewstring/libexec/jailed_x/firefox.sh

			# Gnash is disabled since it doesn't work:
			#firefox__install_gnash nat_insecure

			# Remove if Gnash is enabled:
			grouplist="`user_maint_utils__return_grouplist firefox /usr/shew/jails/nat_insecure`"
			chroot /usr/shew/jails/nat_insecure \
				pw usermod -n firefox -G "${grouplist},sound"

			firefox__install_adblock nat_insecure
			firefox__install_https_everywhere nat_insecure
			firefox__install_noscript nat_insecure
			firefox__install_perspectives nat_insecure
			firefox__install_taco nat_insecure

			echo '
// Added by Shewstring_Desktop/install.sh for Torbutton:
user_pref("extensions.torbutton.display_panel", false);
' >> /usr/shew/jails/nat_insecure/usr/shew/copy_to_mfs/home/firefox/.mozilla/firefox/default/prefs.js
			# This will disable displaying 'Tor Enabled' since this firefox does not use Tor.

		cp -f /usr/shew/install/shewstring/installers/Shewstring_Desktop/misc/nat_insecure/firefox/bookmarks.html \
			/usr/shew/jails/nat_insecure/usr/shew/copy_to_mfs/home/firefox/.mozilla/firefox/default/bookmarks.html
		}

# Commands for nat_secure:

	misc_utils__save_progress \
		&& {
			echo '
Installing the nat_secure jail, which will hold Sylpheed, GnuPG/GPA and Pidgin.'
			misc_utils__prompt_continue

			echo
			jail_maint_utils__create_jail nat_secure
		}

	misc_utils__save_progress \
		&& {
			echo '
Locking down the nat_secure jail.'
			misc_utils__prompt_continue

			echo
			jail_maint_utils__lockdown_jail nat_secure
		}

	misc_utils__save_progress \
		&& {
			echo '
Creating special folders for nat_secure.'
			misc_utils__prompt_continue

			echo

			jail_maint_utils__create_home nat_secure
			jail_maint_utils__create_permanent nat_secure
			jail_maint_utils__create_sensitive nat_secure
		}

	misc_utils__save_progress \
		&& {
			echo '
Setting up X, Telnet and sound for nat_secure.'
			misc_utils__prompt_continue

			echo

			jail_maint_utils__allow_telnet nat_secure
			jail_maint_utils__allow_x nat_secure
			jail_maint_utils__allow_sound nat_secure
		}

	misc_utils__save_progress \
		&& {
			echo '
Creating NAT PF rules for nat_secure.'
			misc_utils__prompt_continue

			echo
			. /usr/shew/install/shewstring/libexec/host/network.sh
			host_network__add_jail_nat_rules nat_secure
		}

	misc_utils__save_progress \
		&& {
			echo '
Configuring the nat_secure resolver to use the local DNS server.'
			misc_utils__prompt_continue

			echo
			. /usr/shew/install/shewstring/libexec/host/dns.sh
			host_dns__add_jail_dns_rules nat_secure
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing some misc. programs for nat_secure: Abiword, Evince, and Terminal.'
			misc_utils__prompt_continue

			echo

			arg_1='nat_secure'
			. /usr/shew/install/shewstring/libexec/jailed_x/abiword.sh

			arg_1='nat_secure'
			. /usr/shew/install/shewstring/libexec/jailed_x/evince.sh

			arg_1='nat_secure'
			. /usr/shew/install/shewstring/libexec/jailed_x/terminal.sh
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing Sylpheed with GnuPG/GPA for nat_secure.'
			misc_utils__prompt_continue

			echo

			arg_1='nat_secure'
			. /usr/shew/install/shewstring/libexec/jailed_x/gnupg.sh

			# This was disabled due to GnuPG not allowing group reads:
			#gnupg__install_gpa nat_secure

			export jailed_x_sylpheed__install_gpa='YES'
				# GPA should really be installed by directly calling the gnupg__install_gpa function,
				# but this doesn't work correctly. See the comments for gnupg__install_gpa and sylpheed.sh.

			arg_1='nat_secure'
			. /usr/shew/install/shewstring/libexec/jailed_x/sylpheed.sh
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing Pidgin with Pidgin-OTR for nat_secure.'
			misc_utils__prompt_continue

			echo
			arg_1='nat_secure'
			. /usr/shew/install/shewstring/libexec/jailed_x/pidgin.sh
		}

# Commands for tor_fast:

	misc_utils__save_progress \
		&& {
			echo '
Installing the tor_fast jail, which will hold Firefox and Liferea.'
			misc_utils__prompt_continue

			echo
			jail_maint_utils__create_jail tor_fast
		}

	misc_utils__save_progress \
		&& {
			echo '
Locking down the tor_fast jail.'
			misc_utils__prompt_continue

			echo
			jail_maint_utils__lockdown_jail tor_fast
		}

	misc_utils__save_progress \
		&& {
			echo '
Creating special folders for tor_fast.'
			misc_utils__prompt_continue

			echo

			jail_maint_utils__create_home tor_fast
			jail_maint_utils__create_permanent tor_fast
			jail_maint_utils__create_sensitive tor_fast
			jail_maint_utils__create_data tor_fast
		}

	misc_utils__save_progress \
		&& {
			echo '
Setting up X, Telnet and sound for tor_fast.'
			misc_utils__prompt_continue

			echo

			jail_maint_utils__allow_telnet tor_fast
			jail_maint_utils__allow_x tor_fast
			jail_maint_utils__allow_sound tor_fast
		}

	misc_utils__save_progress \
		&& {
			echo '
Creating Tor proxy PF rules for tor_fast.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/darknets/tor.sh
			darknets_tor__add_jail_tor_socks_rules tor_fast two_hop
			darknets_tor__add_jail_tor_transparent_rules tor_fast two_hop
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing some misc. programs for tor_fast: Abiword, Evince, VLC and Terminal.'
			misc_utils__prompt_continue

			echo

			arg_1='tor_fast'
			. /usr/shew/install/shewstring/libexec/jailed_x/abiword.sh

			arg_1='tor_fast'
			. /usr/shew/install/shewstring/libexec/jailed_x/evince.sh

			arg_1='tor_fast'
			. /usr/shew/install/shewstring/libexec/jailed_x/vlc.sh

			arg_1='tor_fast'
			. /usr/shew/install/shewstring/libexec/jailed_x/terminal.sh
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing Firefox for tor_fast. Also installing Addons: Torbutton, Adblock,
HTTPS Everywhere, Perspectives, and Beef TACO.'
			misc_utils__prompt_continue

			echo

			arg_1='tor_fast'
			. /usr/shew/install/shewstring/libexec/jailed_x/firefox.sh

			firefox__install_adblock tor_fast
			firefox__install_https_everywhere tor_fast
			firefox__install_noscript tor_fast
			firefox__install_perspectives tor_fast
			firefox__install_taco tor_fast

			grouplist="`user_maint_utils__return_grouplist firefox /usr/shew/jails/tor_fast`"
			chroot /usr/shew/jails/tor_fast \
				pw usermod -n firefox -G "${grouplist},sound"

		cp -f /usr/shew/install/shewstring/installers/Shewstring_Desktop/misc/tor_fast/firefox/bookmarks.html \
			/usr/shew/jails/tor_fast/usr/shew/copy_to_mfs/home/firefox/.mozilla/firefox/default/bookmarks.html
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing Liferea for tor_fast.'
			misc_utils__prompt_continue

			echo
			arg_1='tor_fast'
			. /usr/shew/install/shewstring/libexec/jailed_x/liferea.sh
		}

# Commands for tor_normal:

	misc_utils__save_progress \
		&& {
			echo '
Installing the tor_normal jail, which will hold Firefox with Privoxy.'
			misc_utils__prompt_continue

			echo
			jail_maint_utils__create_jail tor_normal
		}

	misc_utils__save_progress \
		&& {
			echo '
Locking down the tor_normal jail.'
			misc_utils__prompt_continue

			echo
			jail_maint_utils__lockdown_jail tor_normal
		}

	misc_utils__save_progress \
		&& {
			echo '
Creating special folders for tor_normal.'
			misc_utils__prompt_continue

			echo

			jail_maint_utils__create_home tor_normal
			jail_maint_utils__create_permanent tor_normal
			jail_maint_utils__create_sensitive tor_normal
			jail_maint_utils__create_data tor_normal
		}

	misc_utils__save_progress \
		&& {
			echo '
Setting up X and Telnet for tor_normal.'
			misc_utils__prompt_continue

			echo
			jail_maint_utils__allow_telnet tor_normal
			jail_maint_utils__allow_x tor_normal
		}

	misc_utils__save_progress \
		&& {
			echo '
Creating Tor proxy PF rules for tor_normal.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/darknets/tor.sh
			darknets_tor__add_jail_tor_socks_rules tor_normal normal
			darknets_tor__add_jail_tor_transparent_rules tor_normal normal
		}

	misc_utils__save_progress \
		&& {
			echo '
Creating I2P proxy PF rules for tor_normal.'
			misc_utils__prompt_continue

			echo
			. /usr/shew/install/shewstring/libexec/darknets/i2p.sh
			darknets_i2p__add_jail_i2p_http_https_rules tor_normal
		}

	misc_utils__save_progress \
		&& {
			echo '
Creating Freenet proxy PF rules for tor_normal.'
			misc_utils__prompt_continue

			echo
			. /usr/shew/install/shewstring/libexec/darknets/freenet.sh
			darknets_freenet__add_jail_freenet_http_rules tor_normal
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing Privoxy for tor_normal.'
			misc_utils__prompt_continue

			echo

			arg_1='tor_normal'
			. /usr/shew/install/shewstring/libexec/jailed_nox/privoxy.sh

			jailed_nox_privoxy__enable_tor_socks tor_normal normal
			jailed_nox_privoxy__enable_i2p_http_https tor_normal
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing some misc. programs for tor_normal: Abiword, Evince, and Terminal.'
			misc_utils__prompt_continue

			echo

			arg_1='tor_normal'
			. /usr/shew/install/shewstring/libexec/jailed_x/abiword.sh

			arg_1='tor_normal'
			. /usr/shew/install/shewstring/libexec/jailed_x/evince.sh

			arg_1='tor_normal'
			. /usr/shew/install/shewstring/libexec/jailed_x/terminal.sh
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing Firefox for tor_normal. Also installing Addons: Torbutton and HTTPS
Everywhere.'
			misc_utils__prompt_continue

			echo

			arg_1='tor_normal'
			. /usr/shew/install/shewstring/libexec/jailed_x/firefox.sh

			firefox__set_proxy_privoxy tor_normal
			firefox__install_https_everywhere tor_normal
			firefox__install_noscript tor_normal

		cp -f /usr/shew/install/shewstring/installers/Shewstring_Desktop/misc/tor_normal/firefox/bookmarks.html \
			/usr/shew/jails/tor_normal/usr/shew/copy_to_mfs/home/firefox/.mozilla/firefox/default/bookmarks.html
		}

# Commands for tor_pseudonym_1:

	misc_utils__save_progress \
		&& {
			echo '
Installing the tor_pseudonym_1 jail, which will hold Sylpheed, GnuPG/GPA and
Pidgin.'
			misc_utils__prompt_continue

			echo
			jail_maint_utils__create_jail tor_pseudonym_1
		}

	misc_utils__save_progress \
		&& {
			echo '
Locking down the tor_pseudonym_1 jail.'
			misc_utils__prompt_continue

			echo
			jail_maint_utils__lockdown_jail tor_pseudonym_1
		}

	misc_utils__save_progress \
		&& {
			echo '
Creating special folders for tor_pseudonym_1.'
			misc_utils__prompt_continue

			echo

			jail_maint_utils__create_home tor_pseudonym_1
			jail_maint_utils__create_permanent tor_pseudonym_1
			jail_maint_utils__create_sensitive tor_pseudonym_1
		}

	misc_utils__save_progress \
		&& {
			echo '
Setting up X, Telnet and sound for tor_pseudonym_1.'
			misc_utils__prompt_continue

			echo

			jail_maint_utils__allow_telnet tor_pseudonym_1
			jail_maint_utils__allow_x tor_pseudonym_1
			jail_maint_utils__allow_sound tor_pseudonym_1
		}

	misc_utils__save_progress \
		&& {
			echo '
Creating Tor proxy PF rules for tor_pseudonym_1.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/darknets/tor.sh
			darknets_tor__add_jail_tor_socks_rules tor_pseudonym_1 z_dirt
			darknets_tor__add_jail_tor_transparent_rules tor_pseudonym_1 z_dirt
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing some misc. programs for tor_pseudonym_1: Abiword, Evince, Terminal.'
			misc_utils__prompt_continue

			echo

			arg_1='tor_pseudonym_1'
			. /usr/shew/install/shewstring/libexec/jailed_x/abiword.sh

			arg_1='tor_pseudonym_1'
			. /usr/shew/install/shewstring/libexec/jailed_x/evince.sh

			arg_1='tor_pseudonym_1'
			. /usr/shew/install/shewstring/libexec/jailed_x/terminal.sh
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing Sylpheed with GnuPG/GPA for tor_pseudonym_1.'
			misc_utils__prompt_continue

			echo

			arg_1='tor_pseudonym_1'
			. /usr/shew/install/shewstring/libexec/jailed_x/gnupg.sh

			# This was disabled due to GnuPG not allowing group reads:
#			gnupg__install_gpa tor_pseudonym_1

			export jailed_x_sylpheed__install_gpa='YES'
				# GPA should really be installed by directly calling the gnupg__install_gpa function,
				# but this doesn't work correctly. See the comments for gnupg__install_gpa and sylpheed.sh.

			arg_1='tor_pseudonym_1'
			. /usr/shew/install/shewstring/libexec/jailed_x/sylpheed.sh
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing Pidgin with Pidgin-OTR for tor_pseudonym_1.'
			misc_utils__prompt_continue

			echo
			arg_1='tor_pseudonym_1'
			. /usr/shew/install/shewstring/libexec/jailed_x/pidgin.sh

			chflags noschg /usr/shew/jails/tor_pseudonym_1/usr/shew/sensitive/pidgin/prefs.xml
			misc_utils__add_clause \
				/usr/shew/jails/tor_pseudonym_1/usr/shew/sensitive/pidgin/prefs.xml \
				"<pref name='blist'>" \
				"<pref name='x' type='int' value='250'/>"
			chflags schg /usr/shew/jails/tor_pseudonym_1/usr/shew/sensitive/pidgin/prefs.xml

			# Change the default location, so different Pidgin buddylists do not stack on top of each other.
		}

# Commands for tor_pseudonym_2:

	misc_utils__save_progress \
		&& {
			echo '
Installing the tor_pseudonym_2 jail, which will hold Sylpheed, GnuPG/GPA and
Pidgin.'
			misc_utils__prompt_continue

			echo
			jail_maint_utils__create_jail tor_pseudonym_2
		}

	misc_utils__save_progress \
		&& {
			echo '
Locking down the tor_pseudonym_2 jail.'
			misc_utils__prompt_continue

			echo
			jail_maint_utils__lockdown_jail tor_pseudonym_2
		}

	misc_utils__save_progress \
		&& {
			echo '
Creating special folders for tor_pseudonym_2.'
			misc_utils__prompt_continue

			echo

			jail_maint_utils__create_home tor_pseudonym_2
			jail_maint_utils__create_permanent tor_pseudonym_2
			jail_maint_utils__create_sensitive tor_pseudonym_2
		}

	misc_utils__save_progress \
		&& {
			echo '
Setting up X, Telnet and sound for tor_pseudonym_2.'
			misc_utils__prompt_continue

			echo

			jail_maint_utils__allow_telnet tor_pseudonym_2
			jail_maint_utils__allow_x tor_pseudonym_2
			jail_maint_utils__allow_sound tor_pseudonym_2
		}

	misc_utils__save_progress \
		&& {
			echo '
Creating Tor proxy PF rules for tor_pseudonym_2.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/darknets/tor.sh
			darknets_tor__add_jail_tor_socks_rules tor_pseudonym_2 z_dirt
			darknets_tor__add_jail_tor_transparent_rules tor_pseudonym_2 z_dirt
		}

	misc_utils__save_progress \
		&& {
			echo '
Creating I2P proxy PF rules for tor_pseudonym_2.'
			misc_utils__prompt_continue

			echo

			. /usr/shew/install/shewstring/libexec/darknets/i2p.sh
			darknets_i2p__add_jail_i2p_irc_rules tor_pseudonym_2
			darknets_i2p__add_jail_i2p_pop_smtp_rules tor_pseudonym_2
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing some misc. programs for tor_pseudonym_2: Abiword, Evince, Terminal.'
			misc_utils__prompt_continue

			echo

			arg_1='tor_pseudonym_2'
			. /usr/shew/install/shewstring/libexec/jailed_x/abiword.sh

			arg_1='tor_pseudonym_2'
			. /usr/shew/install/shewstring/libexec/jailed_x/evince.sh

			arg_1='tor_pseudonym_2'
			. /usr/shew/install/shewstring/libexec/jailed_x/terminal.sh
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing Sylpheed with GnuPG/GPA for tor_pseudonym_2.'
			misc_utils__prompt_continue

			echo

			arg_1='tor_pseudonym_2'
			. /usr/shew/install/shewstring/libexec/jailed_x/gnupg.sh

			# This was disabled due to GnuPG not allowing group reads:
#			gnupg__install_gpa tor_pseudonym_2

			export jailed_x_sylpheed__install_gpa='YES'
				# GPA should really be installed by directly calling the gnupg__install_gpa function,
				# but this doesn't work correctly. See the comments for gnupg__install_gpa and sylpheed.sh.

			arg_1='tor_pseudonym_2'
			. /usr/shew/install/shewstring/libexec/jailed_x/sylpheed.sh
		}

	misc_utils__save_progress \
		&& {
			echo '
Installing Pidgin with Pidgin-OTR for tor_pseudonym_2.'
			misc_utils__prompt_continue

			echo
			arg_1='tor_pseudonym_2'
			. /usr/shew/install/shewstring/libexec/jailed_x/pidgin.sh

			chflags noschg /usr/shew/jails/tor_pseudonym_2/usr/shew/sensitive/pidgin/prefs.xml
			misc_utils__add_clause \
				/usr/shew/jails/tor_pseudonym_2/usr/shew/sensitive/pidgin/prefs.xml \
				"<pref name='blist'>" \
				"<pref name='x' type='int' value='500'/>"
			chflags schg /usr/shew/jails/tor_pseudonym_2/usr/shew/sensitive/pidgin/prefs.xml

			# Change the default location, so different Pidgin buddylists do not stack on top of each other.
		}

# Other commands:

	misc_utils__move_down_save_progress \
		&& {
			echo '
Starting lockdown/exec.sh, which will do some final security tweaks.'
			misc_utils__prompt_continue

			echo
			. /usr/shew/install/shewstring/libexec/lockdown/exec.sh
		}
	misc_utils__move_up_save_progress
fi
