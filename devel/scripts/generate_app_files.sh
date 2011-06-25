#!/bin/sh

# This script will generate template app files for a list of programs and their
# dependencies that have options you can set, and also add a comment listing
# all the valid options and their meanings for each program.

# Arguments:
  folder="$1"
  shift 1
  programs="$@"

# Execute:

if !
	jls \
		| grep '/usr/shew/jails/compile' \
		> /dev/null
then
	/etc/rc.d/jail start compile
fi

mkdir -p "$folder"

for val in $programs; do
	mkdir -p "$folder"/"$val"

	category="`
		echo /usr/shew/jails/compile/usr/ports/*/"$val" \
			| head -n 1 \
			| sed 's|.*/usr/ports/||' \
			| sed "s|/${val}||"
	`"

	for val2 in /usr/ports/"$category"/"$val" \
		`
			chroot /usr/shew/jails/compile \
				make -C /usr/ports/"$category"/"$val" all-depends-list
		`
	do
		port="`basename "$val2"`"

		chroot /usr/shew/jails/compile \
			make -C "$val2" showconfig \
			| while read line; do
				if
					echo "$line" \
						| grep "Use 'make config'" \
						> /dev/null
				then
					continue
				fi

				echo "# $line" \
					>> "$folder"/"$val"/"$port"
				# Output showconfig to the file, but commented.
			done

		if [ -f "$folder"/"$val"/"$port" ]; then
			echo '
with=""
without=""
' >> "$folder"/"$val"/"$port"
		fi
	done
done
