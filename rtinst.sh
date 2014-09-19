#!/bin/bash

FULLREL=$(cat /etc/issue.net)
SERVERIP=$(ip a s eth0 | awk '/inet / {print$2}' | cut -d/ -f1)
RELNO=0
WEBPASS=''
PASS1=''
PASS2=''

while [ -z "$WEBPASS" ]
  do
   read -p "Please enter password for rutorrent " PASS1
   read -p "Please re-enter password " PASS2
   if [ "$PASS1" = "$PASS2" ]
     then
       WEBPASS="$PASS1"
   fi
  done


  
if [ "$FULLREL" = "Ubuntu 14.04.1 LTS" ]
  then
    RELNO=14
fi

# echo "$FULLREL"
# echo "$RELNO"
# echo "$SERVERIP"

# prepare system
sudo apt-get update && sudo apt-get -y upgrade
sudo apt-get clean && sudo apt-get autoclean

sudo apt-get -y install autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libcloog-ppl-dev libcppunit-dev libcurl3 libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libtool libxml2-dev ncurses-base ncurses-term ntp patch pkg-config php5 php5-cli php5-dev php5-fpm php5-curl php5-geoip php5-mcrypt php5-xmlrpc pkg-config python-scgi screen subversion texinfo unrar-free unzip zlib1g-dev libcurl4-openssl-dev mediainfo

# install ftp
sudo apt-get -y install vsftpd
if [ $RELNO = 14 ]
  then
    sudo perl -pi -e "s/#write_enable=YES/write_enable=YES/g" /etc/vsftpd.conf
    sudo perl -pi -e "s/#local_umask=022/local_umask=022/g" /etc/vsftpd.conf
    sudo perl -pi -e "s/rsa_cert_file/#rsa_cert_file/g" /etc/vsftpd.conf
    sudo perl -pi -e "s/rsa_private_key_file=\/etc\/ssl\/private\/ssl-cert-snakeoil\.key/rsa_cert_file=\/etc\/ssl\/private\/vsftpd\.pem/g" /etc/vsftpd.conf
fi
echo "chroot_local_user=YES" | sudo tee -a /etc/vsftpd.conf > /dev/null
echo "allow_writeable_chroot=YES" | sudo tee -a /etc/vsftpd.conf > /dev/null
echo "ssl_enable=YES" | sudo tee -a /etc/vsftpd.conf > /dev/null
echo "allow_anon_ssl=NO" | sudo tee -a /etc/vsftpd.conf > /dev/null
echo "force_local_data_ssl=YES" | sudo tee -a /etc/vsftpd.conf > /dev/null
echo "force_local_logins_ssl=YES" | sudo tee -a /etc/vsftpd.conf > /dev/null
echo "ssl_sslv2=YES" | sudo tee -a /etc/vsftpd.conf > /dev/null
echo "ssl_sslv3=YES" | sudo tee -a /etc/vsftpd.conf > /dev/null
echo "ssl_tlsv1=YES" | sudo tee -a /etc/vsftpd.conf > /dev/null
echo "require_ssl_reuse=NO" | sudo tee -a /etc/vsftpd.conf > /dev/null
echo "listen_port=43421" | sudo tee -a /etc/vsftpd.conf > /dev/null
echo "ssl_ciphers=HIGH" | sudo tee -a /etc/vsftpd.conf > /dev/null

sudo openssl req -x509 -nodes -days 365 -subj /CN=$SERVERIP -newkey rsa:2048 -keyout /etc/ssl/private/vsftpd.pem -out /etc/ssl/private/vsftpd.pem

sudo service vsftpd restart


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
wget https://raw.githubusercontent.com/arakasi72/rtinst/master/.rtorrent.rc
perl -pi -e "s/<user name>/$LOGNAME/g" ~/.rtorrent.rc

# install rutorrent
cd ~
wget https://raw.githubusercontent.com/arakasi72/rtinst/master/ru.config
wget https://raw.githubusercontent.com/arakasi72/rtinst/master/ru.ini
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

if [ $RELNO = 14 ]
  then
    sudo apt-add-repository -y ppa:jon-severinsson/ffmpeg
    sudo apt-get update
fi
sudo apt-get -y install ffmpeg

# install nginx
sudo apt-get -y install nginx-full apache2-utils
sudo htpasswd -c -b /var/www/rutorrent/.htpasswd $LOGNAME $WEBPASS

sudo openssl req -x509 -nodes -days 365 -subj /CN=$SERVERIP -newkey rsa:2048 -keyout /etc/ssl/ruweb.key -out /etc/ssl/ruweb.crt

if [ $RELNO = 14 ]
  then
    sudo cp /usr/share/nginx/html/* /var/www
fi

sudo mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.old
cd ~
wget https://raw.githubusercontent.com/arakasi72/rtinst/master/nginxsite
sudo mv ~/nginxsite /etc/nginx/sites-available/default
sudo perl -pi -e "s/<Server IP>/$SERVERIP/g" /etc/nginx/sites-available/default
sudo service nginx restart && sudo service php5-fpm restart

# install rtorrent and irssi start, stop, restart script
cd ~
wget https://raw.githubusercontent.com/arakasi72/rtinst/master/rt
sudo mv rt /usr/local/bin/rt
sudo chmod 755 /usr/local/bin/rt

/usr/local/bin/rt start
