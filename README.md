###rtinst
======

NOTE: Please feel free to use any of the code or scripts here, in part or in full, in your own projects. A mention would be appreciated if you use a significant chunk.

####1. Introduction
Seedbox installation

It has been tested with clean installs of Ubuntu 12, 13, 14 and 15, and Debian 7 and 8

Services that will be installed and configured are

	1. vsftpd - ftp server
	2. libtorrent/rtorrent
	3. rutorrent
	4. Nginx
	5. autodl-irssi

I use nginx, it uses less system resources, and I find it easier to configure than apache2.

It uses latest versions of all software at time of posting.

It takes about 10 minutes to run, depending on your server setup.

After you have run the script and everything is working, I suggest a reboot, the script does not automate this reboot, you need to do it manually using the reboot command.

####2. Log into your server

Log into your server with a terminal client like Putty. Fill in the following details in Putty: 

	host name: The IP address or the host name
	protocol: SSH (port 22)
	username: root
	password: use the password your vendor provided

####3. Main Script

Run the script from root, or if you have a sudo user already set up you can run it from there. If for some reason it is interrupted you can run it again to completion. Running the script multiple times will not cause any problems.

First download the script:

	wget --no-check-certificate https://raw.githubusercontent.com/arakasi72/rtinst/master/rtinst.sh

and then to run it:

	bash rtinst.sh

or if you run it from a non-root sudo user:

	sudo bash rtinst.sh

If you run it with the -d option it will enable https downloads, and provide web access to your home directory for https downloads:

	bash rtinst.sh -d

if you run it with -l option it will create the rtinst.log file with detailed output. 

	bash rtinst.sh -l


The script will assign a random ssh port for security purposes. It will display this on the screen when it has finished running and write it to ~/rtinst.info

IMPORTANT: NOTE THE NEW SSH PORT AND MAKE SURE YOU CAN SSH INTO YOUR SERVER BEFORE CLOSING THE EXISTING SESSION

For security the script assigns ftp to a random port number. You will need to use this port number in your ftp client. It will display the port number at the end of the script, and will also write it to ~/rtinst.info

The script assigns a random rutorrent password, to reset it, logged in as the rutorrent user type into the terminal rtpass

To access that information just use the following command

	cat ~/rtinst.info

####4. Additional scripts

A number of additional scripts will be installed that carry out a variety of useful functions. These will be installed by the main script but if you want to get the latest versions you can run the following:

	wget --no-check-certificate https://raw.githubusercontent.com/arakasi72/rtinst/master/rtgetscripts
	sudo bash rtgetscripts
	rm rtgetscripts

######4.1 rtadduser

This will add new users. Ensuring there are no conflicts with the existing user ports. You can use it to create brand new users, or reset the config on existing users. If you use it on an existing user, you will NOT lose any torrents, files, of autodl-filters. It will just reset the ports used.
to run this:

	sudo rtadduser
and enter the information asked for.

######4.2 rtremove

WARNING: This will completely remove a user wiping all their config and data, and removing them from the system.
to run this:

	sudo rtremove

and enter the user name when asked

######4.3 rtupdate

This script can upgrade, (or downgrade), the libtorrent/rtorrent version installed. To run this:

	sudo rtupdate


######4.4 rtdload

This script will enable or disable https download

to enable:

	sudo rtdload enable

to disable:

	sudo rtdload disable

The following scripts can be used by any user

######4.5 rtpass

This will allow user to change their rutorrent password.
to run this:

	rtpass

######4.6 rt

This script can stop, start, or restart rtorrent or irssi. Use the arguments stop start or restart, with no arguments it will tell tell you if rtorrent is running or not

examples: 

	rt
	rt stop
	rt start
	rt restart

If you use the option -i it will switch to irssi

 	rt -i
	rt -i stop
	rt -i start
	rt -i restart
