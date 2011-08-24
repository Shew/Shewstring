#!/bin/sh

# This script is meant to backup files in the Shewstring directory hierarchy.
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

date="`date +%y%m%d`"
if [ -d /usr/shew/data/host/root/"backup_$date" ]; then
	rm -RPf /usr/shew/data/host/root/"backup_$date"
else
	mkdir -p /usr/shew/data/host/root/"backup_$date"
	chmod 0700 /usr/shew/data/host/root/"backup_$date"
	chflags opaque /usr/shew/data/host/root/"backup_$date"
fi

rm -Pf /usr/shew/data/host/root/"backup_$date".7z

echo 'For new users who are unfamiliar with the Shewstring directory layout, the
recommended backup choice is to choose "y" for the "sensitive" folder (which
mostly stores restricted application data, such as Firefox favorites), "c" for
the data folder, "c" for the host folder in the data folder, and "y" for the
guest user in the data folder (which stores the users Desktop folder).
'

for val in sensitive data; do
	echo "Store $val files? y/n/c (custom)"
	read answer
	while [ "$answer" != y -a "$answer" != n -a "$answer" != c ]; do
		echo 'Please answer: y/n/c'
		read answer
	done

	if [ "$answer" = n ]; then
		continue
	fi

	for val2 in \
		`
			ls -F /usr/shew/"$val" \
				| grep '/$' \
				| grep --invert-match '^\.' \
				| sed 's|/$||'
		`
	do
		if [ "$answer" = c ]; then
			echo "Store "$val" files for users in ${val2}? y/n/c (custom)"
			read answer2
			while [ "$answer2" != y -a "$answer2" != n -a "$answer2" != c ]; do
				echo 'Please answer: y/n/c'
				read answer2
			done

			if [ "$answer2" = n ]; then
				continue
			fi
		fi

		if !
			ls -F /usr/shew/"$val"/"$val2" \
				| grep '/$' \
				> /dev/null \
				2> /dev/null
			# This protects the following for loop from invalid input if there are no
			# files.
		then
			continue
		fi

		for val3 in \
			`
				ls -F /usr/shew/"$val"/"$val2" \
					| grep '/$' \
					| sed 's|/$||'
			`
		do
			if [ "$answer2" = c ]; then
				echo "Store $val files for $val3 user in ${val2}? y/n/c (custom)"
				read answer3
				while [ "$answer3" != y -a "$answer3" != n -a "$answer3" != c ]; do
					echo 'Please answer: y/n/c'
					read answer3
				done

				if [ "$answer3" = n ]; then
					continue
				fi
			fi

			if [ "/usr/shew/${val}/${val2}/${val3}" = "/usr/shew/data/host/root" ]; then
				for val4 in \
					`
						ls
					`
				do
					if !
						echo "$val4" \
							| grep \
								-e "backup_$date" \
								-e 'backup_[0-9]*\.7z' \
							> /dev/null
						# Do not backup backups.
					then
						mkdir -p /usr/shew/data/host/root/"backup_$date"/data/host/root
						cp -Rf /usr/shew/data/host/root/"$val4" \
							/usr/shew/data/host/root/"backup_$date"/data/host/root
					fi
				done

				continue
			fi

			mkdir -p /usr/shew/data/host/root/"backup_$date"/"$val"/"$val2"
			cp -Rf /usr/shew/"$val"/"$val2"/"$val3" \
				/usr/shew/data/host/root/"backup_$date"/"$val"/"$val2"
		done
	done
done

if
	ls /usr/shew/data/host/root/"backup_$date"/sensitive/*/sylpheed/gnupg \
		> /dev/null \
		2> /dev/null
	# This protects the following for loop from invalid input if there are no
	# files.
then
	for val in /usr/shew/data/host/root/"backup_$date"/sensitive/*/sylpheed/gnupg; do
		mv "$val" "$val"/../../gpa
	done
fi

if [ -d /etc/keys ]; then
	cp -Rf /etc/keys /usr/shew/data/host/root/"backup_$date"/keys
fi

/usr/local/bin/7z a -mhe=on -p /usr/shew/data/host/root/"backup_$date".7z /usr/shew/data/host/root/"backup_$date"

echo '
Securely wiping temporary files.'

rm -RPf /usr/shew/data/host/root/"backup_$date"

echo '
Finished!'
