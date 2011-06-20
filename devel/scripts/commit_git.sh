#!/bin/sh

# Arguments:
  commit_message="$1"
  date_override="${2-}"
	# date_override should be in Unix time.

# Execute:
if
	dirname "$0" \
		| grep '^/' \
		> /dev/null
then
	directory="`dirname "$0"`/../.."
else
	directory="`pwd`/`dirname "$0"`/../.."
fi

if [ -f "$directory"/.git/shew_commit_git.conf ]; then
	. "$directory"/.git/shew_commit_git.conf
else
	echo 'Please enter your username.'
	read user
	echo 'Please enter your email.'
	read email

	echo "user='${user}'
email='${email}'
" > "$directory"/.git/shew_commit_git.conf
fi

git config --global user.name "$user"
git config --global user.email "$email"

if [ "$date_override" ]; then
	current_date="`date -ju -f '%s' "$date_override" +'%a, %d %b %Y 00:00:00 +0000'`"
else
	current_date="`date -ju +'%a, %d %b %Y 00:00:00 +0000'`"
fi

export \
	GIT_AUTHOR_NAME="$user" \
	GIT_AUTHOR_EMAIL="$email" \
	GIT_AUTHOR_DATE="$current_date" \
	GIT_COMMITTER_NAME="$user" \
	GIT_COMMITTER_EMAIL="$email" \
	GIT_COMMITTER_DATE="$current_date" \
	EMAIL="$email"

find ./ \
	| while read line; do
		modify_date="`
			stat -f %m "$line"
		`"

		if [ "$date_override" ]; then
			if [ "$modify_date" -gt "$date_override" ]; then
				modify_date="`
					date -ju -f '%s' "$date_override" +'%Y%m%d0000.00'
				`"
			else
				modify_date="`
					date -ju -f '%s' "$modify_date" +'%Y%m%d0000.00'
				`"
			fi
		fi

		touch -acfhm -t "$modify_date" "$line"
	done

find ./ \
	| while read line; do
		if [ -d "$line" ]; then
			chmod 0755 "$line"
		elif [ "$line" = './install.sh' ]; then
			chmod 0755 "$line"
		else
			chmod 0644 "$line"
		fi
	done

git add ./
git commit -a --date="$current_date" -m "$commit_message"
