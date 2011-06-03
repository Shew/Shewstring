#!/bin/sh

# This is just a short script to check the syntax of all scripts in shewstring.

# Arguments:
  if
	dirname "$0" \
		grep '^/' \
		> /dev/null
  then
	directory="${1:-`dirname "$0"`/../..}"
  else
	directory="${1:-`pwd`/`dirname "$0"`/../..}"
  fi

# Execute:

find "$directory" \
	| while read line; do
		if
			echo "$line" \
				| grep '\.sh$' \
				> /dev/null
		then
			true
		elif
			cat "$line" \
				| head -n 1 \
				| grep '^#!/bin/sh' \
				> /dev/null
		then
			true
		else
			continue
		fi

		: | sh -n "$line"
			# The pipe from the true command prevents sh from seeing the pipe to the while
			# command.
	done
# A while loop is used instead of a for loop because a for loop splits up
# multiword arguments.
