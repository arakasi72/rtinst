## rtinst

#### 30 Second Guide

Ubuntu and Debian Seedbox Installation

Download script

	wget --no-check-certificate https://raw.githubusercontent.com/arakasi72/rtinst/master/rtinst.sh

and then to run it:

	sudo bash rtinst.sh

It takes about 10 minutes to run, depending on your server setup. After you have run the script and everything is working, I suggest a reboot, the script does not automate this reboot, you need to do it manually using the reboot command.

For a detailed installation guide go to: [Guide](https://github.com/arakasi72/rtinst/wiki/Guide)

**IMPORTANT: NOTE THE NEW SSH PORT AND MAKE SURE YOU CAN SSH INTO YOUR SERVER BEFORE CLOSING THE EXISTING SESSION**


It has been tested with clean installs of: 

	Ubuntu 12
	Ubuntu 13
	Ubuntu 14
	Ubuntu 15
	Ubuntu 16
	Debian 7
	Debian 8

Services that will be installed and configured are

	1. vsftpd - ftp server
	2. libtorrent/rtorrent
	3. rutorrent
	4. Nginx (webserver)
	5. autodl-irssi
	6. webmin (optional see section 3.7 in main guide)


For a detailed installation guide, and additional information on all the features, go to: [Guide](https://github.com/arakasi72/rtinst/wiki/Guide)

To see latest updates to the script go to [Change Log](https://github.com/arakasi72/rtinst/wiki/Change-Log)

-------------------------------------------------------------------------

 Copyright (c) 2015 arakasi72 (https://github.com/arakasi72)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 --> Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
