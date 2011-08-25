#!/bin/sh

# This script will run devel/shewstring_app_files.sh and print a diff of the
# new app files and the app files from the currently installed version.

# Arguments:
  folder="${1:-/tmp/apps}"

  if
	dirname "$0" \
		| grep '^/' \
		> /dev/null
  then
	directory="${2:-`dirname "$0"`/../..}"
  else
	directory="${2:-`pwd`/`dirname "$0"`/../..}"
  fi

# Execute:
if [ ! -d /usr/shew/jails/compile ]; then
	echo 'This script cannot be run before the compile jail is created.'
	exit 1
fi

mkdir -p /tmp/old_apps
cp -f \
	"$directory"/lib/apps/* \
	"$directory"/libexec/*/apps/* \
	/tmp/old_apps

if [ ! -d /tmp/apps ]; then
	sh "-$-" "$directory"/devel/scripts/shewstring_app_files.sh
fi

mkdir -p /tmp/new_apps
cp -f \
	/tmp/apps/*/*/* \
	/tmp/new_apps

diff \
	-r --unified=0 \
	--ignore-space-change --ignore-blank-lines --suppress-common-lines --minimal \
	/tmp/old_apps /tmp/new_apps \
	| grep -e '^+++' -e '^---' -e '^[+-]#' \
	| grep --invert-match '^[+-]# ===>' \
	| less

rm -Rf /tmp/old_apps /tmp/new_apps
