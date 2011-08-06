#!/bin/sh

# This script will generate information needed for the makefiles of Firefox plugins.

# Arguments:
  archive="$1"

# Execute:

if [ -d /tmp/plugin ]; then
	rm -Rf /tmp/plugin
fi

if !
	echo "$archive" \
		| grep '^/' \
		> /dev/null
then
	archive="`pwd`/$archive"
fi

mkdir -p /tmp/plugin
cd /tmp/plugin

unzip "$archive" \
	> /dev/null

dirs=''
files=''

for val in \
	`
		find ./ \
			| sed 's|^./||'
	`
do
	if [ -d "$val" ]; then
		dirs="$dirs $val"
	elif [ -f "$val" ]; then
		files="$files $val"
	fi
done

echo "
Directories:
$dirs

Files:
$files

MD5: `md5 -q "$archive"`
SHA256: `sha256 -q "$archive"`
Size: `stat -f %z "$archive"`
"
