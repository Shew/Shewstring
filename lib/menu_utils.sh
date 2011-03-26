#!/bin/sh

# Contents:	menu_utils__prompt_option
#		menu_utils__prompt_all
#		menu_utils__write_conf_file

menu_utils__prompt_option() {
	# This function will prompt a user based on the contents of a query file.
	# The query files contain definitions for the following variables:
	# prompt		- Defines whether to query the user. May be YES, NO, or
	#			  MAYBE. MAYBE queries only when prompt_condition is
	#			  true when executed.
	# prompt_condition	- Executed when prompt is set to MAYBE. The contents of
	#			  prompt_condition are executed and the query is asked
	#			  if the commands return true.
	# message		- The messaged echoed to the user when querying.
	# exec_message		- This will be executed if defined when querying.
	# check			- This will be executed and if true will accept the
	#			  answer as the value for query_variable.
	# check_error_message	- If check is false, this will echo and the user will
	#			  need to supply different input.
	# The value the user typed in will be placed in a variable with a name which is
	# the value of query_variable.

	query_directory="$1"
	query_variable="$2"

	if [ ! -f "${query_directory}/$query_variable" ]; then
		echo "menu_utils__prompt_option was called with file:
	${query_directory}/$query_variable
but that file does not exist."
		return 1
	fi

	local prompt prompt_condition_deps message exec_message check check_error_message
	. "${query_directory}/$query_variable"

	if [ "$prompt" = YES ]; then
		true
	elif [ "$prompt" = NO ]; then
		return 0
	elif [ "$prompt" = MAYBE ]; then
		if !
			sh -u -c "$prompt_condition"
				# For some reason, exec and `` do not work correctly here.
		then
			setvar "$query_variable" ''
			return 0
		fi
	else
		echo "menu_utils__prompt_option was called with file:
	${query_directory}$query_variable
but it does not have a valid prompt entry."
		return 1
	fi

	echo "$message"

	if [ "${exec_message:-}" ]; then
		sh -u -c "$exec_message"
			# For some reason, exec and `` do not work correctly here.
	fi

	read line
	export line

	until
		sh -u -c "$check"
			# For some reason, exec and `` do not work correctly here.
	do
		echo "$check_error_message"

		read line
		export line
	done

	setvar "$query_variable" "$line"
}

menu_utils__prompt_all() {
	# This function will run menu_utils__prompt_option for all query files in
	# query_directory.

	query_directory="$1"

	if [ ! -d "$query_directory" ]; then
		echo "menu_utils__prompt_all was called on $query_directory but it does not exist."
		return 1
	fi

	if !
		ls "$query_directory"/* \
			> /dev/null \
			2> /dev/null
		# This protects the following for loop from invalid input if there are no
		# files.
	then
		return 0
	fi

	cd "$query_directory"
	for val in *; do
		menu_utils__prompt_option "$query_directory" "$val"
	done

	echo
	echo 'Are you satisfied with your choices? y/n'
	read answer

	until [ "$answer" = y -o "$answer" = n ]; do
		echo 'Please enter y or n.'
		read answer
	done

	until [ "$answer" = y ]; do
		for val in "$query_directory"/*; do
			menu_utils__prompt_option "$query_directory" "$val"
		done

		echo
		echo 'Are you satisfied with your choices? y/n'
		read answer

		until [ "$answer" = y -o "$answer" = n ]; do
			echo 'Please enter y or n.'
			read answer
		done
	done
}

menu_utils__write_conf_file() {
	# This function will dump query variables into a configuration file. The
	# variables dumped are based on the names of the files in query_directory. If
	# there are no query files, nothing is dumped.

	query_directory="$1"
	query_conf_file="$2"

	if [ ! -d "${query_directory}" ]; then
		echo "menu_utils__write_conf_file was with directory:
	$query_directory
but that directory does not exist."
		return 1
	fi

	if !
		ls "$query_directory"/* \
			> /dev/null \
			2> /dev/null
		# This protects the following for loop from invalid input if there are no
		# files.
	then
		return 0
	fi

	cd "$query_directory"
	for val in *; do
		variable_value="`eval "echo \$\"${val}\"`"
			# This line assigns the value of the variable whose name is the value of the
			# variable val.

		echo "${val}=\"$variable_value\"" \
			>> "$query_conf_file"
	done

	chmod 0700 "$query_conf_file"
}
