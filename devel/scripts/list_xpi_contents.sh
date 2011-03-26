#!/bin/sh

# This script will generate lists of directories and files for the makefiles of
# Firefox plugins.

# Arguments:
  archive="$1"

# Execute:

if [ -d /tmp/plugin ]; then
	rm -Rf /tmp/plugin
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
"
