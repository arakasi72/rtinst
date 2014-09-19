#!/bin/bash

# Ubuntu14
# prepare system
# sudo apt-get update && sudo apt-get -y upgrade
# sudo apt-get clean && sudo apt-get autoclean

# sudo apt-get -y install autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libcloog-ppl-dev libcppunit-dev libcurl3 libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libtool libxml2-dev ncurses-base ncurses-term ntp patch pkg-config php5 php5-cli php5-dev php5-fpm php5-curl php5-geoip php5-mcrypt php5-xmlrpc pkg-config python-scgi screen subversion texinfo unrar-free unzip zlib1g-dev libcurl4-openssl-dev mediainfo

# install ftp


# install rtorrent
cd ~
mkdir source
cd source
svn co https://svn.code.sf.net/p/xmlrpc-c/code/stable xmlrpc
curl http://libtorrent.rakshasa.no/downloads/libtorrent-0.13.4.tar.gz | tar xz
curl http://libtorrent.rakshasa.no/downloads/rtorrent-0.9.4.tar.gz | tar xz

cd xmlrpc
./configure --prefix=/usr --enable-libxml2-backend --disable-libwww-client --disable-wininet-client --disable-abyss-server --disable-cgi-server
make
sudo make install

cd ../libtorrent-0.13.4
./autogen.sh
./configure --prefix=/usr
make -j2
sudo make install

cd ../rtorrent-0.9.4
./autogen.sh
./configure --prefix=/usr --with-xmlrpc-c
make -j2
sudo make install
sudo ldconfig

cd ~ && mkdir rtorrent && cd rtorrent
mkdir .session downloads watch

cd ~
wget https://github.com/arakasi72/rtinst/blob/master/.rtorrent.rc
perl -pi -e "s/<user name>/$LOGNAME/g" ~/.rtorrent.rc

# install rutorrent
cd ~
wget https://github.com/arakasi72/rtinst/blob/master/ru.config
wget https://github.com/arakasi72/rtinst/blob/master/ru.ini
sudo mkdir /var/www && cd /var/www

sudo mkdir svn
sudo svn checkout http://rutorrent.googlecode.com/svn/trunk/rutorrent
sudo svn checkout http://rutorrent.googlecode.com/svn/trunk/plugins
sudo rm -r rutorrent/plugins
sudo mv plugins rutorrent

sudo chown www-data:www-data /var/www
sudo chown -R www-data:www-data rutorrent
sudo chmod -R 755 rutorrent

sudo rm rutorrent/conf/config.php
sudo mv ~/ru.config /var/www/rutorrent/conf/config.php

cd rutorrent/plugins
sudo mkdir conf
sudo mv ~/ru.ini conf/plugins.ini

sudo apt-add-repository ppa:jon-severinsson/ffmpeg
sudo apt-get update
sudo apt-get -y install ffmpeg
