#!/bin/sh

# The OpenJDK home page: http://openjdk.java.net/

# Contents:	darknets_java__download_sun_jdk
#		darknets_java__compile_sun_jdk
#		darknets_java__install_openjdk

# Variable defaults:
  : ${darknets_java__apps_folder='/usr/shew/install/shewstring/libexec/darknets/apps'}
								# The default darknets apps folder.
  : ${darknets_java__sun_jdk_filename="diablo-caffe-freebsd7-${shew__architecture}-1.6.0_07-b02.tar.bz2"}
								# The default filename for Sun's JDK.
  : ${darknets_java__sun_jdk_website='http://www.freebsdfoundation.org/cgi-bin/download?download='}
								# The default website for Sun's JDK.

darknets_java__download_sun_jdk() {
	# This function will scrape the freebsd Foundation page with the license
	# agreement for Sun's jdk, and download the tarball based on those scrapings. I
	# (Shew) don't consider the license important enough to bother the user about.
	# Unfortunately, Sun's jdk is currently required to build openjdk on freebsd
	# (but the Sun jre isn't actually used to run software). If this task has
	# already been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_java__download_sun_jdk ]; then
		echo "darknets_java__download_sun_jdk was called already been run, skipping."
		return 0
	fi

	if [ ! -d "$darknets_java__apps_folder" ]; then
		echo "darknets_java__download_sun_jdk could not find a critical install file. It
should be:
	$darknets_java__apps_folder"
		return 1
	fi

	ports_pkgs_utils__configure_port wget "$darknets_java__apps_folder"
	ports_pkgs_utils__compile_port wget

	license_page_site="`dirname "$darknets_java__sun_jdk_website"`/"
	license_page_name="`basename "$darknets_java__sun_jdk_website"`$darknets_java__sun_jdk_filename"

	misc_utils__fetch "$license_page_name" "$license_page_site"
		# This is actually a HTML file with the license agreement, not the JDK.
	mv /usr/shew/install/fetch/"$license_page_name" /usr/shew/install/fetch/sun_jdk_license_page

	if !
		cat /usr/shew/install/fetch/sun_jdk_license_page \
			| grep clickthroughcode \
			> /dev/null
	then
		echo 'The Sun JDK license page did not contain a valid clickthroughcode.'
		return 1
	fi

	click_code="`
		cat /usr/shew/install/fetch/sun_jdk_license_page \
			| grep clickthroughcode \
			| head -n 1 \
			| sed 's/.*value=\"//' \
			| sed 's/\">//'
	`"
		# This scrapes the page for the clickthroughcode, which is used to 'agree' to the license.

	jid="`jail_maint_utils__return_jail_jid compile`"

	echo 'Using wget for diablo-jdk16. (Log is named wget_diablo-jdk16):'
	misc_utils__condense_output_start /usr/shew/install/log/wget_diablo-jdk16

	jexec "$jid" \
		sh "-$-" -c "
			cd /usr/ports/distfiles
			/usr/local/bin/wget --post-data \
				\"iagree=Submit&clickthroughcode=${click_code}&download=$darknets_java__sun_jdk_filename\" \
				\"${license_page_site}$license_page_name\"
		" \
		>> /usr/shew/install/log/wget_diablo-jdk16 \
		2>> /usr/shew/install/log/wget_diablo-jdk16
	# Submit post data 'agreeing' to the license.

	misc_utils__condense_output_end

	if
		file -b /usr/shew/jails/compile/usr/ports/distfiles/"$license_page_name" \
			| grep 'HTML document text' \
			> /dev/null
	then
		echo 'Wget downloaded an HTML file, instead of a tarball.'
		return 1
	fi

	mv /usr/shew/jails/compile/usr/ports/distfiles/"$license_page_name" \
		/usr/shew/jails/compile/usr/ports/distfiles/"$darknets_java__sun_jdk_filename"

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_java__download_sun_jdk
}

darknets_java__compile_sun_jdk() {
	# This function will compile Sun's jdk once it has been downloaded. If this
	# task has already been done, the function complains and returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_java__compile_sun_jdk ]; then
		echo "darknets_java__compile_sun_jdk was called but it has already been run,
skipping."
		return 0
	fi

	if [ ! -d "$darknets_java__apps_folder" ]; then
		echo "darknets_java__compile_sun_jdk could not find a critical install file. It
should be:
	$darknets_java__apps_folder"
		return 1
	fi

	ports_pkgs_utils__configure_port diablo-jdk16 "$darknets_java__apps_folder"

	rm -f \
		/usr/shew/jails/compile/usr/local/bin/aclocal \
		/usr/shew/jails/compile/usr/local/bin/autoconf \
		/usr/shew/jails/compile/usr/local/bin/autoheader \
		/usr/shew/jails/compile/usr/local/bin/automake \
		/usr/shew/jails/compile/usr/local/bin/autom4te \
		/usr/shew/jails/compile/usr/local/bin/autoreconf \
		/usr/shew/jails/compile/usr/local/bin/autoscan \
		/usr/shew/jails/compile/usr/local/bin/autoupdates \
		/usr/shew/jails/compile/usr/local/bin/ifnames
	# automake-wrapper complains and stops the Sun JDK installation if any of these
	# links exist.

	ports_pkgs_utils__compile_port diablo-jdk16

	for val in \
		aclocal autoconf autoheader automake autom4te autoreconf autoscan autoupdates ifnames
	do
		ln -s automake-wrapper /usr/shew/jails/compile/usr/local/bin/"$val" \
			> /dev/null \
			2> /dev/null \
			|| true
	done

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_java__compile_sun_jdk
}

darknets_java__install_openjdk() {
	# This function will install openjdk. Sun's jdk is needed to build openjdk,
	# unfortunately. If this task has already been done, the function complains and
	# returns true.

	if [ -f /usr/shew/install/done/nat_darknets/darknets_java__install_openjdk ]; then
		echo "darknets_java__install_openjdk was called but it has already been run,
skipping."
		return 0
	fi

	if [ ! -d "$darknets_java__apps_folder" ]; then
		echo "darknets_java__install_openjdk could not find a critical install file. It
should be:
	$darknets_java__apps_folder"
		return 1
	fi

	ports_pkgs_utils__configure_port openjdk7 "$darknets_java__apps_folder"
	ports_pkgs_utils__install_pkg openjdk7 /usr/shew/jails/nat_darknets

	if [ ! -d /usr/shew/install/done/nat_darknets ]; then
		mkdir -p /usr/shew/install/done/nat_darknets
		chmod 0700 /usr/shew/install/done/nat_darknets
	fi

	touch /usr/shew/install/done/nat_darknets/darknets_java__install_openjdk
}
