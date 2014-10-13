rtinst
======

seedbox installation
It has been tested with clean installs of Ubuntu 12.04, 12.05, 13.10, and 14.04, and Debian Wheezy (7.6)

Services that will be installed and configured are
1. vsftpd - ftp server
2. libtorrent/rtorrent
3. rutorrent
4. Nginx
5. autodl-irssi

I use nginx with Apache2 as an option. It uses less system resources, and I find it easier to configure. I don't think the difference is huge, given that we will have at most a handful of users, accessing our server, but unless you really want to stick with Apache I would recommend nginx, it is what I am currently using on my live seedbox.

It uses latest versions of all software at time of posting.

After you have run the script and everything is working, I suggest a reboot.


1.1 Log into your server

Log into your server with a terminal client like Putty. Fill in the following details in Putty: 
host name: The IP address or the host name e.g. ksxxxxxx.kimsufi.ovh.com
protocol: SSH (port 22)
username: root
password: use the password your vendor provided

This is not a fork of seed box from scratch.It will install vsftps, rtorrent, rutorrent, autodl-irssi, and nginx, as well as all the configuration, so on completion of the script your seedbox will be ready for use.

This script has been tested on Ubuntu 12.04, 12.05, 13.10, 14.04, and Debian 7.

It takes about 10 minutes to run.

1.1 Main Script
You can run the script with -d option to include implementation of https downloads 

Run the script from root, or if you have a sudo user already set up you can run it from there. If for some reason it is interrupted you can run it again to completion. 

First download the script:
  wget --no-check-certificate https://raw.githubusercontent.com/arakasi72/rtinst/master/rtinst.sh

and then to run it:
  bash rtinst.sh

or if you run it from a non-root sudo user:
  sudo bash rtinst.sh

If you run it with the -d option it will enable https downloads, and provide web access to your home directory for https downloads:
  bash rtinst.sh -d

if you run it with -l option it will create the rtinst.log file with detailed output. 


The script will assign a random ssh port for security purposes. It will display this on the screen when it has finished running and write it to ~/rtinst.info

IMPORTANT: NOTE THE NEW SSH PORT AND MAKE SURE YOU CAN SSH INTO YOUR SERVER BEFORE CLOSING THE EXISTING SESSION

For security the script assigns ftp to a random port number. You will need to use this port number in your ftp client. It will display the port number at the end of the script, and will also write it to ~/rtinst.info

The script assigns a random rutorrent password, to reset it, logged in as the rutorrent user type into the terminal
rtpass

To access that information just use the following command
  cat ~/rtinst.info

1.2 Additional scripts
A number of additional scripts will be installed that carry out a variety of useful functions. These will be installed by the main script but if you want to get the latest versions you can run the following:
  wget --no-check-certificate https://raw.githubusercontent.com/arakasi72/rtinst/master/rtgetscripts
  sudo bash rtgetscripts
  rm rtgetscripts

1.2.1 rtadduser
This will add new users. Ensuring there are no conflicts with the existing user ports. You can use it to create brand new users, or reset the config on existing users. If you use it on an existing user, you will NOT lose any torrents, files, of autodl-filters. It will just reset the ports used.
to run this:
  sudo rtadduser
and enter the information asked for.

1.2.2 rtremove
WARNING: This will completely remove a user wiping all their config and data, and removing them from the system.
to run this:
  sudo rtremove

and enter the user name when asked

1.2.3 rtdload
This script will enable or disable https download
to enable:
  sudo rtdload enable

to disable:
  sudo rtdload disable

The following scripts can be used by any user
1.2.4 rtpass
This will allow user to change their rutorrent password.
to run this:
  rtpass

1.2.5 rt
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
