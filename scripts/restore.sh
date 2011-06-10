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

echo */*/* \
	| while read line; do
		uid="`stat -f %u /usr/shew/"$line"`"
		gid="`stat -f %g /usr/shew/"$line"`"

		chown -R "$uid":"$gid" ./"$line"

		cp -af ./"$line"/* /usr/shew/"$line"
	done

rm -RPf ./
