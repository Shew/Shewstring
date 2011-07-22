#!/bin/sh

# Contents:	misc_utils__generate_unique_port
#		misc_utils__generate_unique_loopback
#		misc_utils__echo_var
#		misc_utils__change_var
#		misc_utils__add_clause
#		misc_utils__fetch
#		misc_utils__prompt_continue 
#		misc_utils__condense_output_start
#		misc_utils__condense_output_end
#		misc_utils__echo_progress
#		misc_utils__save_progress
#		misc_utils__move_down_save_progress
#		misc_utils__move_up_save_progress

# Variable defaults:
  : ${misc_utils__md5=''}			# The MD5 checksum used by misc_utils__fetch.
  : ${misc_utils__sha256=''}			# The SHA256 checksum used by misc_utils__fetch.
  : ${misc_utils__prompt_level='0'}		# The maximum depth in the script hierarchy in which the user is prompted
						# to continue the installation.
  : ${misc_utils__condense_pid=''}		# The pid of the process forked by misc_utils__condense_output_start.
  : ${misc_utils__condense_log_file=''}		# The log file that misc_utils__condense_output_start was called with.
  : ${misc_utils__progress='0'}			# A unique state defining which part of which script the installation is on.
  : ${misc_utils__recovery_mode='NO'}		# Recovery mode attempts to spider the script hierarchy and pick up at
						# the point where the install stopped.
  : ${misc_utils__recovery_progress='0'}	# A copy of misc_utils__progress used in recovery mode.

misc_utils__generate_unique_port() {
	# This function will generate a unique IP port to use with a program. The ports
	# are declared in /usr/shew/install/resources/ports, and should take the form of
	# normal variable declarations. A program or service's port can be returned using
	# misc_utils__echo_var.

	port="`jot -r 1 1024 49151`"

	mkdir -p /usr/shew/install/resources
	touch /usr/shew/install/resources/ports

	while
		cat /usr/shew/install/resources/ports \
			| grep "=['\"]${port}['\"]" \
			> /dev/null
	do
		port="`jot -r 1 1024 49151`"
	done

	echo "$port"
}

misc_utils__generate_unique_loopback() {
	# This function will generate a unique loopback interface. The ports are
	# declared in /usr/shew/install/resources/loopbacks, and should take the form
	# of normal variable declarations. A jail or program's loopback can be
	# returned using misc_utils__echo_var. This is usually only used for attaching
	# jails to, but it is also used for transparent proxying with tor.

	loopback="`jot -r 1 1 255`"

	mkdir -p /usr/shew/install/resources
	touch /usr/shew/install/resources/loopbacks

	while
		cat /usr/shew/install/resources/loopbacks \
			| grep "=['\"]${loopback}['\"]" \
			> /dev/null
	do
		loopback="`jot -r 1 1 255`"
	done

	echo "$loopback"
}

misc_utils__echo_var() {
	# This function will echo the value of a variable in a file with the form:
	# variable='value' or variable="value"

	file="$1"
	variable="$2"

	if [ ! -f "$file" ]; then
		return 1
	fi

	if !
		cat "$file" \
			| grep "${variable}=" \
			> /dev/null
	then
		return 1
	fi

	grep "^ *${variable}=" "$file" \
		| sed 's/#.*//' \
		| grep -o -e "${variable}=\".*\"" -e "${variable}='.*'" \
		| tail -n 1 \
		| sed -E "s/${variable}=['\"](.*)['\"]/\1/"
}

misc_utils__change_var() {
	# This function will change the value of a variable in a file with the form:
	# variable='value' or variable="value"
	# This function cannot handle multiline variable declarations, or arguments
	# with ':' in them.

	file="$1"
	variable="$2"
	value="$3"

	if [ ! -f "$file" ]; then
		echo "misc_utils__change_var was called with:
	$file
but that file does not exist."
		return 1
	fi

	if !
		cat "$file" \
			| grep "${variable}=" \
			> /dev/null
	then
		echo "misc_utils__change_var was called with variable $variable in file:
	$file
but that variable does not exist in that file."
		return 1
	fi

	cp -f "$file" "${file}.tmp"
	cat "${file}.tmp" \
		| sed -E "s:^( *)${variable}='.*':\1${variable}='$value':" \
		| sed -E "s:^( *)${variable}=\".*\":\1${variable}=\"$value\":" \
		> "$file"
	rm -f "${file}.tmp"
}

misc_utils__add_clause() {
	# This function will seek out a line in $file which has $section contained
	# within it. It will then place $addition directly after that line.
	# If you wish to add multiple lines:
	# Put a '\\' after all but the last line when using double quotes, and
	# put a '\' after all but the last line when using single quotes.
	# Note: $section counts as a regular expression, so make sure to escape
	# special characters with backslashes!

	file="$1"
	section="$2"
	addition="$3"

	if [ ! -f "$file" ]; then
		echo "misc_utils__add_clause was called with:
	$file
but that file does not exist."
		return 1
	fi

	if !
		cat "$file" \
			| grep "$section" \
			> /dev/null
	then
		echo "misc_utils__add_clause was called with section:
$section
in file:
	$file
but that section does not exist in that file."
		return 1
	fi

	cp -f "$file" "${file}.tmp"
	cat "${file}.tmp" \
		| sed "/$section/ a\\
			$addition
		" > "$file"
	rm -f "${file}.tmp"
}

misc_utils__fetch() {
	# This function will try to fetch $file from $websites until it gets a file. If
	# a md5 and/or sha256 hash is given, the file will be checked and redownloaded
	# if it does not match. The script will attempt at least three downloads, and
	# at least the number of websites given before exiting. If the file already
	# exists, and a md5 and/or sha256 hash is given, the file will be checked with
	# the hash(s) and if it matches the function will return true, if it doesn't it
	# will be redownloaded. Hashes are set thusly, and are cleared before the
	# function returns:
	# misc_utils__md5="hash"
	# misc_utils__sha256="hash"

	file="$1"
	shift
	websites="$*"

	echo 'pass quick inet proto tcp from !127.0.0.0/8 to !127.0.0.0/8 port { 20, 21, 80 }' \
		| pfctl -m -f -

	i='0'
	while true; do
		for val in $websites; do
			i="`expr "$i" + 1`"

			if [ ! -f "$file" ]; then
				# An extra file check is done in case the file already exists before the
				# function is called.

				if [ ! -d /usr/shew/install/fetch ]; then
					mkdir -p /usr/shew/install/fetch
					chmod 0700 /usr/shew/install/fetch
				fi

				cd /usr/shew/install/fetch

				fetch "${val}$file"
			fi

			if [ -f "$file" ]; then
				if [ "$misc_utils__md5" -a ! "`md5 -q "$file"`" = "$misc_utils__md5" ]; then
					rm -f "$file"
					continue
				fi

				if [ "$misc_utils__sha256" -a ! "`sha256 -q "$file"`" = "$misc_utils__sha256" ]; then
					rm -f "$file"
					continue
				fi

				break 2
			fi
		done

		if [ "$i" -ge 3 ]; then
			echo "misc_utils__fetch attempted to download file:
	$file
at least three times, but failed each time. The following websites were tried:
$websites"

			export \
				misc_utils__md5='' \
				misc_utils__sha256=''

			pfctl -f /etc/pf.conf

			return 1
		fi
	done

	echo 'Fetch successful.'

	export \
		misc_utils__md5='' \
		misc_utils__sha256=''

	pfctl -f /etc/pf.conf
}

misc_utils__prompt_continue() {
	# This function will ask the user if they want to continue if the depth in the
	# script hierarchy is less than $misc_utils__prompt_level. If the user answers
	# no, the script will exit (not return) false.

	progress="`
		echo "$misc_utils__progress" \
			| sed 's/ 0$//'
	`"
	# This removes the last number if it is 0. If this is not done, the user will
	# not get a prompt at the proper prompt level when
	# misc_utils__move_down_save_progress has just been called.

	i='0'
	for val in $progress; do
		i="`expr "$i" + 1`"
	done

	if [ "$i" -le "$misc_utils__prompt_level" ]; then
		echo 'Do you want to continue? y/n'
		read answer

		until [ "$answer" = y -o "$answer" = n ]; do
			echo 'Please enter y or n.'
			read answer
		done

		if [ "$answer" = n ]; then
			echo 'The user exited the script.'

			exit 1
		fi
	fi
}

misc_utils__condense_output_start() {
	# This function will condense the output of verbose programs into an expanding
	# row of single periods. It will also place a copy of each line in a gzipped
	# log file, it is recommended that /usr/shew/install/log be used for log files.
	# New logs will replace old ones of the same name. This is particulary useful
	# for extremely verbose and long running processes like compiling software.
	# The logs can be read using:
	# zcat file | more
	# The correct usage of this function is:
	#	misc_utils__condense_output_start file
	#	command > file
	#	misc_utils__condense_output_end

	misc_utils__condense_log_file="$1"

	dirname="`dirname "$misc_utils__condense_log_file"`"
	if [ ! -d "$dirname" ]; then
		mkdir -p "$dirname"
		chmod 0700 "$dirname"
	fi

	touch "$misc_utils__condense_log_file"
	chmod 0600 "$misc_utils__condense_log_file"

	export misc_utils__condense_log_file
	export shewstring_pid="$$"

	sh -eu -c '
		wc="0"
		while sleep 10; do
			if !
				ps -p "$shewstring_pid" \
					> /dev/null
			then
				break
			fi
				# This prevents the loop from continuing if Shewstring exits.

			new_wc="`
				cat "$misc_utils__condense_log_file" \
				| wc -l
			`"

			if [ "$new_wc" -gt "$wc" ]; then
				echo -n "."
			fi

			wc="$new_wc"
		done
	' &
		# A new shell is spawned so that the debug options does not output the lines
		# executed hundreds of times. It also produces a good ps entry.

	misc_utils__condense_pid="$!"
}

misc_utils__condense_output_end() {
	# This function ends misc_utils__condense_output_start, see that function for
	# more detail.

	kill "$misc_utils__condense_pid" \
		|| true

	if [ -f "$misc_utils__condense_log_file" ]; then
		echo 'y' \
			| gzip -f "$misc_utils__condense_log_file"
	fi
}

misc_utils__echo_progress() {
	# This function echos the current script, step, and total progress.

	script_step="`
		echo "$misc_utils__progress" \
			| grep -o '[0-9]*$'
	`"
	echo "Running script $shew__current_script on step $script_step"
	echo "Full progress: $misc_utils__progress"
}

misc_utils__save_progress() {
	# This function will save progress when operating in non-recovery mode. In
	# recovery mode it will skip code until it reaches the point where the script
	# stopped. This is critical for restarting the installation process if it
	# encounters errors, since the scripts would have needed to be modified to
	# start in the correct location after the error has been corrected. The form of
	# $misc_utils__progress incrementing the last number at each save step,
	# appending a '1' whenever calling a script (i.e. decending in the script
	# hierarchy) and removing the last number when ascending the script hierarchy.
	# The correct usage is to run the step's code only when the output of this
	# function is true:
	#	misc_utils__save_progress && { command 1; command 2; command 3; }

	script_step="`
		echo "$misc_utils__progress" \
			| grep -o '[0-9]*$'
	`"
	script_step="`
		expr "$script_step" + 1
	`"

        misc_utils__progress="`
		echo "$misc_utils__progress" \
			| sed 's/ *[0-9]*$//'
	`"

	if [ "$$misc_utils__progress" ]; then
	        misc_utils__progress="$misc_utils__progress $script_step"
	else
		misc_utils__progress="$script_step"
	fi

	echo "$misc_utils__progress" \
		> /tmp/crash_recovery

	if [ "$misc_utils__recovery_mode" = YES ]; then
		if [ "$misc_utils__progress" = "$misc_utils__recovery_progress" ]; then
			misc_utils__recovery_mode='NO'
			return 0
		fi

		return 1		
	fi
}

misc_utils__move_down_save_progress() {
	# This function will save progress indicating that a new script has been
	# called, moving down in the depth of the script hierarchy. This is critical
	# for restarting the installation process if it encounters errors, since the
	# scripts would have needed to be modified to start in the correct location
	# after the error has been corrected. The form of $misc_utils__progress
	# incrementing the last number at each save step, appending a '1' whenever
	# calling a script (i.e. decending in the script hierarchy) and removing the
	# last number when ascending the script hierarchy. The correct usage is to run
	# the new script only when the output of this function is true:
	#	misc_utils__move_down_save_progress && . script
	#	misc_utils__move_up_save_progress

	script_step="`
		echo "$misc_utils__progress" \
			| grep -o '[0-9]*$'
	`"
	script_step="`
		expr "$script_step" + 1
	`"

        misc_utils__progress="`
		echo "$misc_utils__progress" \
			| sed 's/ *[0-9]*$//'
	`"

	progress_part="$misc_utils__progress $script_step"

	if [ "$$misc_utils__progress" ]; then
	        misc_utils__progress="$misc_utils__progress $script_step 0"
	else
		misc_utils__progress="$script_step"
	fi

	echo "$misc_utils__progress" \
		> /tmp/crash_recovery

	if [ "$misc_utils__recovery_mode" = YES ]; then
		if [ "$misc_utils__progress" = "$misc_utils__recovery_progress" ]; then
			misc_utils__recovery_mode='NO'
		elif
			echo "$misc_utils__recovery_progress" \
				| grep "^$progress_part " \
				> /dev/null
		then
			true
		else
			return 1
		fi	
	fi
}

misc_utils__move_up_save_progress() {
	# This function will save progress indicating that a script has just been
	# completed, moving up in the depth of the script hierarchy. This is critical
	# for restarting the installation process if it encounters errors, since the
	# scripts would have needed to be modified to start in the correct location
	# after the error has been corrected. The form of $misc_utils__progress
	# incrementing the last number at each save step, appending a '1' whenever
	# calling a script (i.e. decending in the script hierarchy) and removing the
	# last number when ascending the script hierarchy. The correct usage is to call
	# this function immediately after the completion of a script which used
	# misc_utils__move_down_save_progress:
	#	misc_utils__move_down_save_progress && . script
	#	misc_utils__move_up_save_progress

	shew__current_script="$0"

        misc_utils__progress="`
		echo "$misc_utils__progress" \
			| sed 's/ [0-9]*$//'
	`"

	misc_utils__save_progress \
		|| true
	# This command is set to always be true because normally misc_utils__save_progress is used as:
	# misc_utils__save_progress && command, which will not give an error when using sh -e.

	echo "$misc_utils__progress" \
		> /tmp/crash_recovery
}
