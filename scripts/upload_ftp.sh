#!/bin/sh

# This script is meant to provide an easy way for users to upload files via
# FTP. It is mainly intended for keeping files on an FTP server up to date,
# such as for a hosted website. Put all files to be uploaded in a directory
# named 'files' which is a subdirectory of the directory containing this
# script. The script will create a file, lastup_${user}@$domain to hold the
# last upload date. Usage should look something like this:
#
# Open a host Terminal.
#
# ls shews_blog
#	files/	lastup_shew@xqz3u5drneuzhaeo.onion	upload_ftp.sh
# sudo cp -af shews_blog /usr/shew/jails/tor_normal/tmp
# sudo chmod -R 0777 /usr/shew/jails/tor_normal/tmp/shews_blog
#
# Open tor_normal's Terminal.
#
# sh /tmp/shews_blog/upload_ftp.sh
#
# Return to the host Terminal.
#
# cp -f /usr/shew/jails/tor_normal/tmp/shews_blog/lastup_shew@xqz3u5drneuzhaeo.onion shews_blog
#

# Arguments:
  directory="${1:-`dirname "$0"`}"

# Execute:

cd "${directory}/files"

websites='xqz3u5drneuzhaeo.onion - Freedom Hosting'

echo '
Which website would you like to upload to?'

lines="`
	echo "$websites" \
		| wc -l
`"

website_number='1'
until [ "$lines" -lt "$website_number" ]; do
	line="`
		echo "$websites" \
			| head -n "$website_number" \
			| tail -n 1
	`"

	echo "  $website_number ) $line"

	website_number="`expr "$website_number" + 1`"
done

read answer

until [ "$answer" -ge 1 -a "$answer" -le "$website_number" ]; do
	echo 'Please enter the number of one of the options above.'
	read answer
done

website_number='1'
until [ "$lines" -lt "$website_number" ]; do
	line="`
		echo "$websites" \
			| head -n "$website_number" \
			| tail -n 1
	`"

	if [ "$answer" -eq "$website_number" ]; then
		upload_website="`
			echo "$line" \
				| sed 's/ .*//'
		`"

		break
	else
		website_number="`expr "$website_number" + 1`"
	fi

	website_number="`expr "$website_number" + 1`"
done

echo '
What is the user you are uploading with?'
read user

until [ "$user" ]; do
	echo 'Please enter a user.'
	read user
done

if [ -f ../"lastup_${user}@$upload_website" ]; then
	lastup="`head -n 1 ../"lastup_${user}@$upload_website"`"

	if ! [ "$lastup" -eq "$lastup" ]; then
		# This is a hack to check to see if it is an integer.

		lastup='0'
	fi
else
	lastup='0'
fi

file_list=''
for val in \
	`
		find ./ \
			| sed 's|^./||'
	`
do
	modification_time="`stat -f %m "$val"`"

	if [ "$modification_time" -le "$lastup" ]; then
		continue
	fi

	if [ "$file_list" ]; then
		file_list="$file_list
$val"
	else
		file_list="$val"
	fi

	if [ -d "$val" ]; then
		if [ "$command_list" ]; then
			command_list="$command_list
mkdir /$val"
		else
			command_list="mkdir /$val"
		fi
	else
		if [ "$command_list" ]; then
			command_list="$command_list
put $val /$val"
		else
			command_list="put $val /$val"
		fi
	fi
done

if [ "$file_list" ]; then
	echo "
Files to upload:
$file_list"
else
	echo '
No files were modified since the last upload.'
	exit 0
fi

echo '
Do you want to continue? y/n'
read answer

until [ "$answer" = y -o "$answer" = n ]; do
	echo 'Please enter y or n.'
	read answer
done

if [ "$answer" = n ]; then
	echo 'The user exited the script.'

	exit 1
fi

echo '
Please enter your password.'

stty -echo
read password
stty echo

until [ "$password" ]; do
	echo 'Please enter a password.'
	read password
done

echo "user $user $password
$command_list
bye" \
	| ftp -n "$upload_website"

echo '
Update last upload time file? y/n'
read answer

until [ "$answer" = y -o "$answer" = n ]; do
	echo 'Please enter y or n.'
	read answer
done

if [ "$answer" = n ]; then
	echo 'The user exited the script.'

	exit 1
fi

current_date="`date -j -f "%a %b %d %T %Z %Y" "\`date\`" "+%s"`"
	# This command is listed in date(8) as a method to express the current date in
	# epoch time.

echo "$current_date" \
	> ../"lastup_${user}@$upload_website"

echo '
Finished!
Remember to preserve your last upload time file.'
