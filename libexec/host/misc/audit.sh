#!/bin/sh

# This script will clean out sensitive directories based on the contents of
# *.allow files. These files are lists of regular expressions, which are
# matched against the path to the file with respect to the user's directory.
# For an example hierarchy:
#	/usr/shew/sensitive/jailname/username/dir1/file1
#	/usr/shew/sensitive/jailname/username/dir1/file2
#	/usr/shew/sensitive/jailname/username/file3
# The username.allow file might look like this:
#	dir1
#	dir1/file1
#	file.*
# In which case dir1/file2 would be overwritten and deleted with rm -P and
# everything else would remain unchanged.

# Execute:

if [ `id -u` -ne 0 ]; then
	echo 'You must run this script as root for it to complete successfully.'
	exit 1
fi

for val in \
	`
		ls -F /usr/shew/sensitive \
			| grep '/$'
	`
do
	if !
		ls /usr/shew/sensitive/"$val"/*.allow \
			> /dev/null \
			2> /dev/null
		# This protects the following for loop from invalid input if there are no
		# files.
	then
		continue
	fi

	cd /usr/shew/sensitive/"$val"

	for val2 in *.allow; do
		username="`
			echo "$val2" \
				| sed 's/\.allow$//'
		`"

		echo "Auditing ${val}$username"

		cd /usr/shew/sensitive/"$val"/"$username"

		find ./ \
			| sed 's|^./||' \
			| while read line; do
				if [ -z "$line" ]; then
					continue
				fi

				if [ ! -e /usr/shew/sensitive/"$val"/"$username"/"$line" ]; then
					# If a folder has been removed by an earlier iteration of this loop, the file
					# listing from 'find' will still contain entries for files that no longer exist,
					# which would create errors with the following lines.
					continue
				fi

				if \
[ "`stat -f %i /usr/shew/sensitive/"$val"/"$username"`" \
-eq "`stat -f %i /usr/shew/sensitive/"$val"/"$username"/"$line"`" ]; then
					# This check is to make sure that the whole sensitive folder isn't removed.
					continue
				fi

				if !
					echo "$line" \
						| grep -x -f /usr/shew/sensitive/"$val"/"$val2" \
						> /dev/null
				then
					echo "	Removing: $line"

					rm -RPf /usr/shew/sensitive/"$val"/"$username"/"$line"
				fi
			done
	done
done

rm -RPf /usr/shew/data/.Trash-*
