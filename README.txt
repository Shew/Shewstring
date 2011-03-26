
Shewstring is a collection of Bourne Shell functions and scripts for building
installers of secure and anonymous FreeBSD distros. It is primarily intended
for developers of anonymity systems, administrators of anonymous services
(such as Tor hidden services), security experts, etc., but ordinary users that
have some skill in the art of security and anonymity may find it very useful
too. One use of it might be to build an installer for easy to set up inproxies
and outproxies for the darknets; another might be to host a service across all
major darknets; or the user of the software might just want a secure desktop
with cryptography tools and access to all major darknets. Shewstring abstracts
away most of the complexities of building secure systems, so an installer can
consist of simple function calls and script executions. Only customization or
use of darknet features that dont have functions yet would need custom
shellcode. Developers who are interested in developing installers should look
in docs/ for documentation, devel/ for the current state of Shewstring
development, and installers/ for examples of pre-built installers. People
wishing to use pre-built Shewstring installers should look in installers/ for
their choice of systems (especially read description.txt for each one).

Currently Shewstring ships with the following pre-built installers:
Shewstring_Desktop

# Pre-install instructions:

Make sure you have the following resources available:
 * Writable DVD for the FreeBSD install DVD.
 * Removable medium to hold install files (USB thumb drive recommended).
 * A second removable medium of at least 200 MiB to hold the boot files
   (if you are using a removable boot device, which is recommended. USB
   thumb drive recommended.).
 * Computer with at least:
	20 GiB space for Shewstring_Desktop
   (NOTE: disk space requirements are high because most system files are
   duplicated for each jail, sorry!)

Download the FreeBSD install DVD image from:
  http://www.freebsd.org/where.html

and verify it (the md5 and sha256 commands can be used on BSD, or md5sum and
sha256sum on GNU/Linux):

MD5 of FreeBSD-8.1-RELEASE-amd64-dvd1.iso = 
  3dc2f3131c390f3d8312349cd945aa24
SHA256 of FreeBSD-8.1-RELEASE-amd64-dvd1.iso =
  5a7f23188bc20c8fbcc3a8d0eb630f2aa445c72d5bf1483c6bc83b17e590b397

MD5 of FreeBSD-8.1-RELEASE-i386-dvd1.iso) =
  75eb10e7586de1adf793e897ae344eb1
SHA256 of FreeBSD-8.1-RELEASE-i386-dvd1.iso) =
  e273a66c370c519fe83711ee20b9a07165c2c3acd24dc3105efd6609ecb0b24f

  (NOTE: If you are using I2P or Freenet, then you can only use amd64 or i386
  because the diablo-jdk packages are only compiled for those architectures.
  Hopefully, this will be fixed in the future.)
  (Also NOTE: The DVD install 'dvd1' is currently the only recommended FreeBSD
  installer. 'bootonly' and 'disk1' will not work. 'livefs' may be supported in
  the future, but does not yet work. 'memstick' may work but is untested.)

Download the ports tarball (ports.tar.gz) either (for the latest tarball) from:
  ftp://ftp.freebsd.org/pub/FreeBSD/ports/ports/ports.tar.gz
or as shipped with the latest Shewstring version (for a tested tarball):
  http://xqz3u5drneuzhaeo.onion/users/shew/shewstring/index.html
Unfortunately there is no way to authenticate the former; the latter can be
authenticated by GnuPG with Shew's public key.

Place the ports tarball with Shewstring on your install files removable
medium. When copying the ports tarball, place it in the folder that the
Shewstring folder is in (e.g. 'ls' should show something like 'ports.tar.gz
shewstringv1.0.0').

# Install instructions:

If you are not using a boot files medium, then you need to partition the hard
drive first. Set aside 200M for the boot files, and the rest for the
installation. You may also need to install a boot manager. This is currently
untested, unfortunately, so more detailed instructions cannot be given.

Boot the computer you wish install on with the FreeBSD installer.

On the sysinstall Main Menu, navigate to 'Fixit' and then 'CDROM/DVD'.

If you are using a boot files medium seperate from the computer hard drive,
then connect this to the computer FIRST (it is important that you connect it
before the install files medium!).

Connect the install files medium to the computer.

Mount the install files medium. If you connected two USB devices for the
media, with a FAT filesystem for the install files medium, then the command to
mount the install files medium will be 'mount_msdosfs /dev/da1s1 /mnt'. If you
are using some other kind of filesystem, then see the FreeBSD manual for
'mount':
  http://www.freebsd.org/cgi/man.cgi?query=mount

Run install.sh in Shewstring's install directory. If you mounted the install
medium at /mnt then you can probably use '/mnt/shewstringv*/install.sh'.

Shewstring should ask you about the options for your installation, and then
start installing.

Once this part of the install is completed, type 'exit' to exit fixit.
Navigate to 'Cancel' and then 'Exit Install' and your computer should reboot.

When it shuts down completely, remove your install files medium. You will no
longer need it.

During the boot process, you will get a password prompt for the password you
entered for hard drive encryption. NOTE: this usually gets covered up by other
boot messages (a known bug in GELI), so if your computer hangs during the boot
process it is probably because you need to enter your password.

Once booted, you will be asked for a login name. Type 'root' and you will be
logged in (there is no password yet). Type
'/usr/shew/install/shewstring/install.sh' to resume the installation.
Shewstring may ask you a couple of questions about passwords.

Once the second part of the install is completed, you can use the command
'shutdown -r now' to reboot and start using your install! NOTE: The graphical
login screen you will get on booting currently will say that the session is
insecure. This is expected. Ironically, telling FreeBSD that the session is
insecure makes it more secure (which is why it says this).

# Useful commands:

Mount a DVD:
  sudo mount /media/dvd
Mount a USB medium:
  sudo mount /media/usb

# Special ports to use in jails:

NOTE: Currently sending traffic to 127.0.0.1 does not work, so send it to
127.0.0.2 instead.

Accessing the website '127.0.0.1:8888' will give you Freenet's FProxy in the
tor_normal jail.

Pointing a Pidgin IRC account at '127.0.0.1:6668' in the tor_pseudonym_2 jail
will give you the I2P IRC chat.

Pointing Sylpheed POP3 at '127.0.0.1:7654' and SMTP at '127.0.0.1:7659' in the
tor_pseudonym_2 jail will give you the Postman mail system.
