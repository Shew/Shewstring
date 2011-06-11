#!/bin/sh

# In fixit this script will prompt the user for a shewstring installer, prompt
# with query files and run the installer. In post-fixit this script will run
# the installer and any existing customization files. It is recommended that
# this script be run with the install.sh wrapper in the root folder of
# shewstring, since this will properly implement progress saving and restoring.

if [ -f /usr/shew/install/install_vars.conf ]; then
	echo 'Found install_vars.conf. Assuming a post-fixit install.'
	shew__using_fixit='NO'
else
	echo 'install_vars.conf not found. Assuming a fixit install.'
	shew__using_fixit='YES'
fi

if [ "$shew__using_fixit" = YES ]; then
	if
		dirname "$0" \
			| grep '^/' \
			> /dev/null
	then
		shew__fixit_shewstring_installer_dir="${1:-`dirname "$0"`/..}"
	else
		shew__fixit_shewstring_installer_dir="${1:-`pwd`/`dirname "$0"`/..}"
	fi

	if [ ! -f "$shew__fixit_shewstring_installer_dir"/install.sh ]; then
		echo 'Installation files not detected in the specified install directory.'
		exit 1
	fi
fi

if [ "$shew__using_fixit" = YES ]; then
	. "$shew__fixit_shewstring_installer_dir"/lib/global_var_defaults.conf
	. "$shew__fixit_shewstring_installer_dir"/lib/menu_utils.sh
	. "$shew__fixit_shewstring_installer_dir"/lib/misc_utils.sh

	if [ -f /tmp/install_vars.conf ]; then
		. /tmp/install_vars.conf
	fi
else
	. /usr/shew/install/shewstring/lib/global_var_defaults.conf
	. /usr/shew/install/shewstring/lib/misc_utils.sh
	. /usr/shew/install/install_vars.conf
fi

echo
shew__current_script='libexec/main_installer.sh'
misc_utils__echo_progress

if [ "$shew__using_fixit" = YES ]; then
	shew__architecture="`uname -p`"

	shew__freebsd_version="`uname -r`"
fi

if [ "$shew__using_fixit" = YES ]; then
	misc_utils__save_progress \
		&& {
			echo '
Searching for Shewstring installers...'
			misc_utils__prompt_continue

			echo

			installer_chosen='NO'
			until [ "$installer_chosen" = YES ]; do
				echo '
Please select an installer. A detailed description will then be displayed for
that installer.'

				installer_number='0'
				cd "$shew__fixit_shewstring_installer_dir"/installers
				for val in \
					`
						ls
					`
				do
					installer_number="`expr "$installer_number" + 1`"
					echo "  $installer_number ) $val"
				done

				read answer

				until [ "$answer" -ge 1 -a "$answer" -le "$installer_number" ]; do
					echo 'Please enter the number of one of the options above.'
					read answer
				done

				installer_number='1'
				for val in \
					`
						ls
					`
				do
					if [ "$answer" -eq "$installer_number" ]; then
						shew__shewstring_installer="$val"
						break
					else
						installer_number="`expr "$installer_number" + 1`"
					fi
				done

				more \
"$shew__fixit_shewstring_installer_dir"/installers/"$shew__shewstring_installer"/description.txt
				echo

				sleep 1

				echo 'Do you wish to use this installer? y/n'

				read answer

				until [ "$answer" = y -o "$answer" = n ]; do
					echo 'Please enter y or n.'
					read answer
				done

				if [ "$answer" = y ]; then
					echo "shew__shewstring_installer=\"${shew__shewstring_installer}\"" \
						>> /tmp/install_vars.conf

					installer_chosen='YES'
				fi
			done
		}

	misc_utils__save_progress \
		&& {
			echo '
Backing up the Shewstring install files, so that they can be moved later.'

			cd "$shew__fixit_shewstring_installer_dir"
			find ./ \
				| sed 's|^./||' \
				| while read line; do
					if
						echo "$line" \
							| grep -x -f \
"$shew__fixit_shewstring_installer_dir"/installers/"$shew__shewstring_installer"/fixit_backup_files.txt \
							> /dev/null
					then
						mkdir -p /tmp/shewstring/"`dirname "$line"`"
						cp -Rf "$line" /tmp/shewstring/"$line"
					fi
				done

			echo "$shew__fixit_shewstring_installer_dir" \
				> /tmp/thumbdrive_path

			misc_utils__save_progress \
				|| true
			# Normally misc_utils__save_progress is not used this way. What this statement
			# will do is make the installer think it has started on the next step of the
			# installation, when it actually has not. This is necessary because of the exit
			# statement here.

			if
				echo "$-" \
					| grep 'x' \
					> /dev/null
			then
				mv /tmp/shewstring_log.txt /tmp/shewstring_log2.txt

				sh /tmp/shewstring/install.sh debug \
					&& exit 0 || exit 1
			else
				sh /tmp/shewstring/install.sh \
					&& exit 0 || exit 1
			fi
		}

	misc_utils__save_progress \
		&& {
			echo '
Searching for query files...'
			misc_utils__prompt_continue

			echo

			installer_dir="${shew__fixit_shewstring_installer_dir}/installers/${shew__shewstring_installer}"

			if [ -d "$installer_dir"/query ]; then
				menu_utils__prompt_all "$installer_dir"/query

				echo '
# Added by menu_utils__write_conf_file for shewstring:' \
					>> /tmp/install_vars.conf

				menu_utils__write_conf_file "$installer_dir"/query /tmp/install_vars.conf
			fi
		}

	misc_utils__move_down_save_progress \
		&& {
			installer_dir="${shew__fixit_shewstring_installer_dir}/installers/${shew__shewstring_installer}"

			if [ -f "$installer_dir"/customization/custom_variables.conf ]; then
				. "$installer_dir"/customization/custom_variables.conf
			fi

			echo

			echo "
Starting the $shew__shewstring_installer installer."
			misc_utils__prompt_continue

			. "$installer_dir"/installer.sh
		}
	misc_utils__move_up_save_progress

	misc_utils__save_progress \
		&& {
			echo '
Writing install variables to a file.'
			misc_utils__prompt_continue

			echo

			if [ ! -d /encrypted/usr/shew/install ]; then
				mkdir -p /encrypted/usr/shew/install
				chmod 0500 /encrypted/usr/shew/install
			fi

			cp /tmp/install_vars.conf /encrypted/usr/shew/install/install_vars.conf

			echo "
# Added by libexec/main_installer.sh for shewstring:
shew__architecture=\"${shew__architecture}\"
shew__fixit_shewstring_installer_dir=\"${shew__fixit_shewstring_installer_dir}\"
shew__freebsd_version=\"${shew__freebsd_version}\"
shew__shewstring_installer=\"${shew__shewstring_installer}\"
" >> /encrypted/usr/shew/install/install_vars.conf
			chmod 0400 /encrypted/usr/shew/install/install_vars.conf
		}

	misc_utils__save_progress \
		&& {
			echo '
Backing up log files.'
			misc_utils__prompt_continue

			echo

			if [ -f /tmp/shewstring_log.txt ]; then
				if [ ! -d /encrypted/usr/shew/install/log ]; then
					mkdir -p /encrypted/usr/shew/install/log
					chmod 0700 /encrypted/usr/shew/install/log
				fi

				cp -f /tmp/shewstring_log.txt /encrypted/usr/shew/install/log/shewstring_fixit_log
				cp -f /tmp/shewstring_log2.txt /encrypted/usr/shew/install/log/shewstring_fixit2_log
				echo 'y' \
					| gzip -f /encrypted/usr/shew/install/log/shewstring_fixit_log
			fi

			if
				ls /usr/shew/install/log/* \
					> /dev/null \
					2> /dev/null
				# This protects the following for loop from invalid input if there are no
				# files.
			then
				if [ ! -d /encrypted/usr/shew/install/log ]; then
					mkdir -p /encrypted/usr/shew/install/log
					chmod 0700 /encrypted/usr/shew/install/log
				fi

				for val in /usr/shew/install/log/*; do
					cp -f "$val" /encrypted/usr/shew/install/log
				done
			fi
		}


	misc_utils__save_progress \
		&& {
			echo '
Fixit install completed. Please reboot your computer and run install.sh again.
You can log in using the username root without a password.'
			exit 0
		}

else

	misc_utils__move_down_save_progress \
		&& {
			echo "
Restarting the $shew__shewstring_installer installer."
			misc_utils__prompt_continue

			echo

			installer_dir="/usr/shew/install/shewstring/installers/${shew__shewstring_installer}"

			if [ -f "$installer_dir"/customization/custom_variables.conf ]; then
				. "$installer_dir"/customization/custom_variables.conf
			fi

			. /usr/shew/install/shewstring/installers/"$shew__shewstring_installer"/installer.sh
		}
	misc_utils__move_up_save_progress

	misc_utils__save_progress \
		&& {
			echo '
Running any customization scripts.'
			misc_utils__prompt_continue

			echo

			installer_dir="/usr/shew/install/shewstring/installers/${shew__shewstring_installer}"

			if
				ls "$installer_dir"/customization/*.sh \
					> /dev/null \
					2> /dev/null
				# This protects the following for loop from invalid input if there are no files.
			then
				for val in \
					"$installer_dir"/customization/*.sh
				do
					. "$val"
				done
			fi
		}

	misc_utils__save_progress \
		&& {
			echo '
Backing up log files.'
			misc_utils__prompt_continue

			echo

			if [ -f /tmp/shewstring_log.txt ]; then
				if [ ! -d /usr/shew/install/log ]; then
					mkdir -p /usr/shew/install/log
					chmod 0700 /usr/shew/install/log
				fi

				cp -f /tmp/shewstring_log.txt /usr/shew/install/log/shewstring_post_fixit_log
				echo 'y' \
					| gzip -f /usr/shew/install/log/shewstring_post_fixit_log
			fi
		}

	misc_utils__save_progress \
		&& {
			echo '
Install completed! You can now reboot and start using your new system.'
			exit 0
		}

fi
