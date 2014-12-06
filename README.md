rtinst
======

### Seedbox installation

It has been tested with clean installs of Ubuntu 12.04, 12.10, 13.10, 14.04, and 14.10. Also with Debian Wheezy (7.6) and Debian 8 beta2.

Services that will be installed and configured are:

	1. vsftpd - FTP server
	2. libtorrent/rtorrent
	3. rutorrent
	4. Nginx
	5. autodl-irssi

It will install all the packages above mentioned as well as all the configurations. So, on completion of the script your seedbox will be ready for use. (*note*: This script is **not** a fork of "seedbox from scratch" script.)

I have chosen Nginx as it uses less system resources and I find it easier to configure than Apache2. I don't think the differences are huge, given that we will have at most a handful of users accessing our server. But unless you really want to stick with Apache, I would recommend Nginx, it is what I am currently using on my own live seedbox.

It uses latest versions of all softwars above mentioned at time of posting.

After you have finished running the script and everything is working fine, I suggest a reboot. And then,

### 1.1 Log into your server

Log into your server with a terminal client like Putty (a Windows app). Fill in the following details in Putty (or your client, e.g. `Terminal` on OSX and Linux): 

**host IP**: The IP address as in `XX.XX.XX.XX`, or the **hostname**: `ksxxxxxx.kimsufi.ovh.com`

**protocol**: `SSH`  **port**: `22`

**username**: `root` or the `sudo user` **password**: use the root or your sudo user password.


This script takes about 10 minutes to finish.

### 1.2 Main Script

Run the script as `root`, or if you have a `sudo user` already set up you can run it as that user. If, for some reason, the runnign script is interrupted, you can always run it again to completion. 

First download the script:

	wget --no-check-certificate https://raw.githubusercontent.com/arakasi72/rtinst/master/rtinst.sh

(Before running the script please check the **1.2.1** section to see options to run the script and decide if you want that.)

Then to run it:

	bash rtinst.sh

Or if you run it from a non-root **sudo user**:

	sudo bash rtinst.sh

#### 1.2.1 Options to run the script:

If you run it with the `-d` option it will enable https downloads, and provide web access to your home directory for https downloads:

(Change the `bash rtinst.sh` part to `sudo bash rtinst.sh` if you are running as a `sudo user` as explined above)

	bash rtinst.sh -d

if you run it with `-l` option it will create the `rtinst.log` file with detailed output. 

	bash rtinst.sh -l
	
Running the script with both `-d` and `-l` options set:

	bash rtinst.sh -d -l


The script will assign random `ssh` and `ftp` ports for security reasons. These will display this on the screen when it has finished running and write it to `~/rtinst.info` file.

To access that information from the saved `~/rtinst.info` file, use the following command:

	cat ~/rtinst.info

**IMPORTANT**: Take a note of the new SSH port (also the new `ftp` port) and make sure you can `ssh` into your server before closing the current `ssh` session.

The script assigns a random `rutorrent` password. To reset it, log in as the `rutorrent` user and type into the terminal:

	rtpass

### 1.3 Additional scripts

A number of additional scripts will be installed that carry out a variety of useful tasks. These will be installed by the main script but if you want to get the latest versions f these helper scripts, you can run the following:

	wget --no-check-certificate https://raw.githubusercontent.com/arakasi72/rtinst/master/rtgetscripts
	sudo bash rtgetscripts
	rm rtgetscripts

#### 1.3.1 rtadduser

This will add new users, ensuring there are no conflicts with the existing user ports. You can use it to create brand new users, or reset the configuration of existing users. 

If you use it on an existing user, you will NOT lose any torrents, files, of autodl-filters. It will just reset the ports used.

To run this, type:

	sudo rtadduser
	
and enter the information asked for.

##### 1.3.2 rtremove

**WARNING**: This will completely remove a user **wiping all of user configurations and user data** from the system.

To run this, type:

	sudo rtremove

and enter the username of the user you want to remove, when asked.

#### 1.3.3 rtdload

This script will enable or disable https download:

To enable:

	sudo rtdload enable

To disable:

	sudo rtdload disable

#### 1.3.4 rtpass

This will allow the user to change their rutorrent password.

To run this, type:

	rtpass

#### 1.3.5 rt

This script can stop, start, or restart `rtorrent` or `irssi`.

Use the arguments `stop`, or `start`, or `restart`. If run without arguments, it will return the status whether rtorrent is running or not.

Examples: 

	rt
	rt stop
	rt start
	rt restart

If you use the option `-i` it will switch to `irssi`

 	rt -i
	rt -i stop
	rt -i start
	rt -i restart
