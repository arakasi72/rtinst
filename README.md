###rtinst
**NOTE 8th Nov 2015** - Reorganised repository. For existing installations, you will need to manually download and run rtgetscripts:

	wget --no-check-certificate https://raw.githubusercontent.com/arakasi72/rtinst/master/scripts/rtgetscripts
	sudo bash rtgetscripts
	
======
####0. 30 Second Guide

Download script

	wget --no-check-certificate https://raw.githubusercontent.com/arakasi72/rtinst/master/rtinst.sh

and then to run it:

	bash rtinst.sh

or if you run it from a non-root sudo user:

	sudo bash rtinst.sh

**IMPORTANT: NOTE THE NEW SSH PORT AND MAKE SURE YOU CAN SSH INTO YOUR SERVER BEFORE CLOSING THE EXISTING SESSION**



####1. Introduction
Seedbox installation

It has been tested with clean installs of: 

	Ubuntu 12
	Ubuntu 13
	Ubuntu 14
	Ubuntu 15
	Debian 7
	Debian 8

Services that will be installed and configured are

	1. vsftpd - ftp server
	2. libtorrent/rtorrent
	3. rutorrent
	4. Nginx (webserver)
	5. autodl-irssi
	6. webmin (optional see section 3.7 below)

It takes about 10 minutes to run, depending on your server setup.

After you have run the script and everything is working, I suggest a reboot, the script does not automate this reboot, you need to do it manually using the reboot command.

####[2. Main Script](rtinst.sh)

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

**IMPORTANT: NOTE THE NEW SSH PORT AND MAKE SURE YOU CAN SSH INTO YOUR SERVER BEFORE CLOSING THE EXISTING SESSION**

For security the script assigns ftp to a random port number. You will need to use this port number in your ftp client. It will display the port number at the end of the script, and will also write it to ~/rtinst.info

The script assigns a random rutorrent password, to reset it, logged in as the rutorrent user type into the terminal rtpass

To access that information just use the following command

	cat ~/rtinst.info

####3. Admin Scripts

A number of additional scripts will be installed that carry out a variety of useful functions. These will be installed by the main script. So you don't need to remember all the script names you can run rtadmin which will, present a menu to launch the other scripts listed in this section. 

	sudo rtadmin

If you get an error run the following, you will only need to this once, and subsequently the prior command will work

	wget --no-check-certificate https://raw.githubusercontent.com/arakasi72/rtinst/master/scripts/rtgetscripts
	sudo bash rtgetscripts
	
All the scripts are downloaded to /usr/local/bin

######[3.1 rtgetscripts](scripts/rtgetscripts)

This will install update all the rtinst scripts making sure you have the latest versions:

	sudo rtgetscripts


######[3.2 rtadduser](scripts/rtadduser)

This will add new users. Ensuring there are no conflicts with the existing user ports. You can use it to create brand new users, or reset the config on existing users. If you use it on an existing user, you will NOT lose any torrents, files, of autodl-filters. It will just reset the ports used.
To run this:

	sudo rtadduser
and enter the information asked for.

######[3.3 rtremove](scripts/rtremove)

WARNING: This will completely remove a user wiping all their config and data, and removing them from the system.
To run this:

	sudo rtremove

and enter the user name when asked

######[3.4 rtdload](scripts/rtdload)

This script will enable or disable https download

To run:

	sudo rtdload

It will tell you the current status, and ask if you want to change it.

If enabled you can access at https://SERVER_IP/download/user_name

######[3.5 rtupdate](scripts/rtupdate)

This script can upgrade, (or downgrade), the libtorrent/rtorrent version installed. To run this:

	sudo rtupdate

######[3.6 rutupgrade](scripts/rutupgrade)

This script upgrades Rutorrent. It retains all your config and settings, as well as providing a rollback capability.

To run this:

	sudo rutupgrade

######[3.7 rtwebmin](scripts/rtwebmin)

This will install webmin, (if not already installed), and configure nginx as a reverse proxy allowing you to access webmin using https://SERVER-IP/webmin
To run this:

	sudo rtwebmin

####4. User Scripts

The scripts in this section can be run by any user other than root. They cannot be run by root as they are not applicable to root.

######[4.1 rtpass](scripts/rtpass)

This will allow user to change their rutorrent password.
to run this:

	rtpass

######[4.2 rt](scripts/rt)

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


-------------------------------------------------------------------------

 Copyright (c) 2015 arakasi72 (https://github.com/arakasi72)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 --> Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
