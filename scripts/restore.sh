#!/bin/sh

# This script is meant to restore a backup created by scripts/backup.sh.
#
# To use this script, simply run it using 'sh'.

# Execute:

if [ `id -u` -ne 0 ]; then
	echo 'You must run this script as root for it to complete successfully.'
	exit 1
fi

echo 'Please exit all programs and then type "ok".'
read answer
while [ "$answer" != ok ]; do
	echo 'Please type "ok" when ready.'
	read answer
done

/usr/shew/permanent/root/audit.sh

echo 'Please provide the path to the backup file:'
read path
while [ ! -f "$path" ]; do
	echo 'That file was not found, or was not a normal file.'
	read path
done

if !
	basename "$path" \
		| grep '^backup_[0-9]*\.7z' \
		> /dev/null
then
	echo 'That file does not look like a backup created by scripts/backup.sh, are
you sure you want to try and use it? y/n'
	read answer
	while [ "$answer" != y -a "$answer" != n ]; do
		echo 'Please answer "y" or "n".'
		read answer
	done

	if [ "$answer" = n ]; then
		echo 'The user exited the script.'
		exit 0
	fi
fi

cd /usr/shew/data/host/root
7z x "$path"
cd ./backup_*/

if
	ls sensitive/*/sylpheed/gnupg \
		> /dev/null \
		2> /dev/null
	# This protects the following for loop from invalid input if there are no
	# files.
then
	for val in sensitive/*/sylpheed/gnupg; do
		mv "$val" "$val"/../../gpa
	done
fi

echo '
Restoring files.
(NOTE: You may see "Operation Not Permitted" errors; this is normal due to chflagged files.)'

for val in */*/*; do
	uid="`stat -f %u /usr/shew/"$val"`"
	gid="`stat -f %g /usr/shew/"$val"`"

	chown -R "$uid":"$gid" ./"$val"

	cp -af ./"$val"/* /usr/shew/"$val"
done

echo '
Removing temporary files.'

rm -RPf "`pwd`"

echo '
Finished!'
