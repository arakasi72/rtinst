#!/bin/bash
PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/bin:/sbin
FULLREL=$(cat /etc/issue.net)
SERVERIP=$(ip a s eth0 | awk '/inet / {print$2}' | cut -d/ -f1)
RELNO=0
WEBPASS=''
PASS1=''
PASS2=''
cronline1="@reboot sleep 10; /usr/local/bin/rtcheck irssi rtorrent"
cronline2="*/10 * * * * /usr/local/bin/rtcheck irssi rtorrent"
DLFLAG=1

genpasswd() {
local genln=$1
[ -z "$genln" ] && genln=8
tr -dc A-Za-z0-9 < /dev/urandom | head -c ${genln} | xargs
}

random()
{
    local min=$1
    local max=$2
    local RAND=`od -t uI -N 4 /dev/urandom | awk '{print $2}'`
    RAND=$((RAND%((($max-$min)+1))+$min))
    echo $RAND
}

get_scripts() {
local script_name=$1
local script_dest=$2
local no_err=1
local attempts=0
until [ $no_err = 0 ]
  do
    rm -f $script_name
    wget --no-check-certificate https://raw.githubusercontent.com/arakasi72/rtinst/develop/$script_name
    no_err=$?
    attempts=$(( $attempts + 1 ))
    if [ $attempts = 20 ]
      then
        echo "There is a problem downloading the scripts. Please check your network or there may be an issue with the github website"
        echo "If the Github website is down, you can try again later"
        exit 1
    fi
  done

if ! [ -z "$script_dest" ]
  then
    mv -f $script_name $script_dest
fi
}


# determine system
if [ "$FULLREL" = "Ubuntu 14.04.1 LTS" ] || [ "$FULLREL" = "Ubuntu 14.04 LTS" ]
  then
    RELNO=14
elif [ "$FULLREL" = "Ubuntu 13.10" ]
  then
    RELNO=13
elif [ "$FULLREL" = "Ubuntu 12.04.4 LTS" ]
  then
    RELNO=12
elif [ "$FULLREL" = "Ubuntu 12.04.5 LTS" ]
  then
    RELNO=12
elif [ "$FULLREL" = "Debian GNU/Linux 7" ]
  then
    RELNO=7
else
  echo "Unable to determine OS or OS unsupported"
  exit
fi

# get options
while getopts ":d" optname
  do
    case $optname in
      "d" ) DLFLAG=0 ;;
        * ) echo "incorrect option, only -d allowed" && exit 1 ;;
    esac
  done

shift $(( $OPTIND - 1 ))

# Check if there is more than 0 argument
if [ $# -gt 0 ]
  then
    echo "No arguments allowed $1 is not a valid argument"
    exit 1
fi

# set and prepare user
if test "$SUDO_USER" = "root" || { test -z "$SUDO_USER" &&  test "$LOGNAME" = "root"; }
  then
    echo "Enter the name of the user to install to"
    echo "This will be your primary user"
    echo "It can be an existing user or a new user"
    echo
	
    confirm_name=1
    while [ $confirm_name = 1 ]
      do
        read -p "Enter user name: " answer
        addname=$answer
        check_name=1
        while [ $check_name = 1 ]
          do
            read -p "Is $addname correct? " answer
            case $answer in [Yy]* ) confirm_name=0 && check_name=0  ;;
                            [Nn]* ) confirm_name=1 && check_name=0  ;;
                                * ) echo "Enter y or n";;
            esac
        done
    done
    
    user=$addname
    
    if id -u $user >/dev/null 2>&1
      then
        echo "$user already exists"
      else
        echo "adding $user"
          useradd -m $user
	  passwd $user
    fi

    if [ $(dpkg-query -W -f='${Status}' sudo 2>/dev/null | grep -c "ok installed") -eq 0 ];
      then
        echo "Installing sudo"
        apt-get -y install sudo > /dev/null;
    fi


    if groups $user | grep -q -E ' sudo(\s|$)'
      then
        echo "$user already has sudo privileges"
      else
        adduser $user sudo
    fi

elif ! [ -z "$SUDO_USER" ]
  then
    user=$SUDO_USER
else
  echo "Script must be run using sudo or root"
  exit 1
fi

home="/home/$user"

# download rt scripts and config files
mkdir $home/rtscripts
cd $home/rtscripts

get_scripts rt /usr/local/bin/rt
chmod 755 /usr/local/bin/rt

get_scripts rtcheck /usr/local/bin/rtcheck
chmod 755 /usr/local/bin/rtcheck

get_scripts rtupdate /usr/local/bin/rtupdate
chmod 755 /usr/local/bin/rtupdate

get_scripts edit_su /usr/local/bin/edit_su
chmod 755 /usr/local/bin/edit_su

get_scripts rtpass /usr/local/bin/rtpass
chmod 755 /usr/local/bin/rtpass

get_scripts rtsetpass /usr/local/bin/rtsetpass
chmod 755 /usr/local/bin/rtsetpass

get_scripts rtsetpass /usr/local/bin/rtdload
chmod 755 /usr/local/bin/rtdload

get_scripts .rtorrent.rc
get_scripts ru.config
get_scripts ru.ini
get_scripts nginxsitedl
get_scripts nginxsite

cd $home

# secure ssh
portline=$(grep 'Port 22' /etc/ssh/sshd_config)
if [ "$portline" = "Port 22" ]
then
sshport=$(random 21000 29000)
perl -pi -e "s/Port 22/Port $sshport/g" /etc/ssh/sshd_config
fi

perl -pi -e "s/X11Forwarding yes/X11Forwarding no/g" /etc/ssh/sshd_config
perl -pi -e "s/PermitRootLogin without-password/PermitRootLogin no/g" /etc/ssh/sshd_config
perl -pi -e "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config

usedns=$(grep UseDNS /etc/ssh/sshd_config)
if [ -z "$usedns" ]
  then
    echo "UseDNS no" | tee -a /etc/ssh/sshd_config > /dev/null
  else
   perl -pi -e "s/$usedns/UseDNS no/g" /etc/ssh/sshd_config
fi

allowlist=$(grep AllowUsers /etc/ssh/sshd_config)
if [ -z "$allowlist" ]
  then
    echo "AllowUsers $user" | tee -a /etc/ssh/sshd_config > /dev/null
  else
    if [ "${allowlist#*$user}" = "$allowlist" ]
      then
        perl -pi -e "s/$allowlist/$allowlist $user/g" /etc/ssh/sshd_config
    fi
fi

service ssh restart



# prepare system
cd $home

if [ "$FULLREL" = "Ubuntu 12.04.5 LTS" ]
  then
    wget --no-check-certificate https://help.ubuntu.com/12.04/sample/sources.list
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
    mv sources.list /etc/apt/sources.list
fi

apt-get update && apt-get -y upgrade
apt-get clean && apt-get autoclean

apt-get -y install autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libcloog-ppl-dev libcppunit-dev libcurl3 libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libtool libxml2-dev ncurses-base ncurses-term ntp patch pkg-config php5 php5-cli php5-dev php5-fpm php5-curl php5-geoip php5-mcrypt php5-xmlrpc pkg-config python-scgi screen subversion texinfo unrar-free unzip zlib1g-dev libcurl4-openssl-dev mediainfo

if [ $RELNO = 13 ]
  then
    apt-get -y install php5-json
fi

# install ftp

ftpport=$(random 41005 48995)

if [ $RELNO = 12 ]
  then
    apt-get -y install python-software-properties
    add-apt-repository -y ppa:thefrontiergroup/vsftpd
    apt-get update
fi

if [ $RELNO = 7 ]
  then
    echo "deb http://ftp.cyconet.org/debian wheezy-updates main non-free contrib" | tee -a /etc/apt/sources.list.d/wheezy-updates.cyconet2.list > /dev/null
    aptitude update
    aptitude -o Aptitude::Cmdline::ignore-trust-violations=true -y install -t wheezy-updates debian-cyconet-archive-keyring vsftpd
  else
    apt-get -y install vsftpd
fi



perl -pi -e "s/anonymous_enable=YES/anonymous_enable=NO/g" /etc/vsftpd.conf
perl -pi -e "s/#local_enable=YES/local_enable=YES/g" /etc/vsftpd.conf
perl -pi -e "s/#write_enable=YES/write_enable=YES/g" /etc/vsftpd.conf
perl -pi -e "s/#local_umask=022/local_umask=022/g" /etc/vsftpd.conf
perl -pi -e "s/rsa_private_key_file/#rsa_private_key_file/g" /etc/vsftpd.conf
perl -pi -e "s/rsa_cert_file=\/etc\/ssl\/certs\/ssl-cert-snakeoil\.pem/rsa_cert_file=\/etc\/ssl\/private\/vsftpd\.pem/g" /etc/vsftpd.conf

echo "chroot_local_user=YES" | tee -a /etc/vsftpd.conf > /dev/null
echo "allow_writeable_chroot=YES" | tee -a /etc/vsftpd.conf > /dev/null
echo "ssl_enable=YES" | tee -a /etc/vsftpd.conf > /dev/null
echo "allow_anon_ssl=NO" | tee -a /etc/vsftpd.conf > /dev/null
echo "force_local_data_ssl=YES" | tee -a /etc/vsftpd.conf > /dev/null
echo "force_local_logins_ssl=YES" | tee -a /etc/vsftpd.conf > /dev/null
echo "ssl_sslv2=YES" | tee -a /etc/vsftpd.conf > /dev/null
echo "ssl_sslv3=YES" | tee -a /etc/vsftpd.conf > /dev/null
echo "ssl_tlsv1=YES" | tee -a /etc/vsftpd.conf > /dev/null
echo "require_ssl_reuse=NO" | tee -a /etc/vsftpd.conf > /dev/null
echo "listen_port=$ftpport" | tee -a /etc/vsftpd.conf > /dev/null
echo "ssl_ciphers=HIGH" | tee -a /etc/vsftpd.conf > /dev/null

openssl req -x509 -nodes -days 3650 -subj /CN=$SERVERIP -newkey rsa:2048 -keyout /etc/ssl/private/vsftpd.pem -out /etc/ssl/private/vsftpd.pem

service vsftpd restart


# install rtorrent
cd $home
mkdir source
cd source
svn co https://svn.code.sf.net/p/xmlrpc-c/code/stable xmlrpc
curl http://libtorrent.rakshasa.no/downloads/libtorrent-0.13.4.tar.gz | tar xz
curl http://libtorrent.rakshasa.no/downloads/rtorrent-0.9.4.tar.gz | tar xz

cd xmlrpc
./configure --prefix=/usr --enable-libxml2-backend --disable-libwww-client --disable-wininet-client --disable-abyss-server --disable-cgi-server
make
make install

cd ../libtorrent-0.13.4
./autogen.sh
./configure --prefix=/usr
make -j2
make install

cd ../rtorrent-0.9.4
./autogen.sh
./configure --prefix=/usr --with-xmlrpc-c
make -j2
make install
ldconfig

cd $home
mkdir rtorrent
cd rtorrent
mkdir .session downloads watch

cd $home
mv -f $home/rtscripts/.rtorrent.rc $home/.rtorrent.rc
perl -pi -e "s/<user name>/$user/g" $home/.rtorrent.rc

# install rutorrent
cd $home

mkdir /var/www
cd /var/www

svn checkout http://rutorrent.googlecode.com/svn/trunk/rutorrent
svn checkout http://rutorrent.googlecode.com/svn/trunk/plugins
rm -r rutorrent/plugins
mv plugins rutorrent

rm rutorrent/conf/config.php
mv $home/rtscripts/ru.config /var/www/rutorrent/conf/config.php
mkdir /var/www/rutorrent/conf/users/$user
mkdir /var/www/rutorrent/conf/users/$user/plugins

echo "<?php" | tee /var/www/rutorrent/conf/users/$user/config.php > /dev/null
echo | tee -a /var/www/rutorrent/conf/users/$user/config.php > /dev/null
echo "\$scgi_port = 5000;" | tee -a /var/www/rutorrent/conf/users/$user/config.php > /dev/null
echo "\$XMLRPCMountPoint = \"/RPC2\";" | tee -a /var/www/rutorrent/conf/users/$user/config.php > /dev/null
echo | tee -a /var/www/rutorrent/conf/users/$user/config.php > /dev/null
echo "?>" | tee -a /var/www/rutorrent/conf/users/$user/config.php > /dev/null

cd rutorrent/plugins
mkdir conf
mv $home/rtscripts/ru.ini conf/plugins.ini

if [ $RELNO = 14 ]
  then
    apt-add-repository -y ppa:jon-severinsson/ffmpeg
    apt-get update
fi
apt-get -y install ffmpeg

# install nginx
apt-get -y install nginx-full apache2-utils
WEBPASS=$(genpasswd)
htpasswd -c -b /var/www/rutorrent/.htpasswd $user $WEBPASS

openssl req -x509 -nodes -days 3650 -subj /CN=$SERVERIP -newkey rsa:2048 -keyout /etc/ssl/ruweb.key -out /etc/ssl/ruweb.crt

perl -pi -e "s/user www-data;/user www-data www-data;/g" /etc/nginx/nginx.conf
perl -pi -e "s/worker_processes 4;/worker_processes 1;/g" /etc/nginx/nginx.conf
perl -pi -e "s/pid \/run\/nginx\.pid;/pid \/var\/run\/nginx\.pid;/g" /etc/nginx/nginx.conf
perl -pi -e "s/# server_tokens off;/server_tokens off;/g" /etc/nginx/nginx.conf
perl -pi -e "s/access_log \/var\/log\/nginx\/access\.log;/access_log off;/g" /etc/nginx/nginx.conf
perl -pi -e "s/error\.log;/error\.log crit;/g" /etc/nginx/nginx.conf


if [ $RELNO = 14 ] | [ $RELNO = 13 ]
  then
    cp /usr/share/nginx/html/* /var/www
fi

if [ $RELNO = 12 ] | [ $RELNO = 7 ]
  then
    cp /usr/share/nginx/www/* /var/www
fi

mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.old
cd $home

mv $home/rtscripts/nginxsite /etc/nginx/sites-available/default
mv $home/rtscripts/nginxsitedl /etc/nginx/conf.d/rtdload

if [ $DLFLAG = 0 ]
  then
    perl -pi -e "s/#include \/etc\/nginx\/conf\.d\/rtdload;/include \/etc\/nginx\/conf\.d\/rtdload;/g" /etc/nginx/sites-available/default
fi

perl -pi -e "s/<Server IP>/$SERVERIP/g" /etc/nginx/sites-available/default

if [ $RELNO = 12 ]
  then
    perl -pi -e "s/fastcgi_pass unix\:\/var\/run\/php5-fpm\.sock/fastcgi_pass 127\.0\.0\.1\:9000/g" /etc/nginx/sites-available/default
fi

service nginx restart && service php5-fpm restart

# install autodl-irssi

adlport=$(random 36001 36100)
adlpass=$(genpasswd $(random 12 16))

apt-get -y install git libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libjson-perl libjson-xs-perl libxml-libxslt-perl libxml-libxml-perl libjson-rpc-perl libarchive-zip-perl
mkdir -p $home/.irssi/scripts/autorun
cd $home/.irssi/scripts
wget --no-check-certificate -O autodl-irssi.zip http://update.autodl-community.com/autodl-irssi-community.zip
unzip -o autodl-irssi.zip
rm autodl-irssi.zip
cp autodl-irssi.pl autorun/
mkdir -p $home/.autodl
touch $home/.autodl/autodl.cfg && touch $home/.autodl/autodl2.cfg

cd /var/www/rutorrent/plugins
git clone https://github.com/autodl-community/autodl-rutorrent.git autodl-irssi

mkdir /var/www/rutorrent/conf/users/$user/plugins/autodl-irssi

touch /var/www/rutorrent/conf/users/$user/plugins/autodl-irssi/conf.php

echo "<?php" | tee /var/www/rutorrent/conf/users/$user/plugins/autodl-irssi/conf.php > /dev/null
echo | tee -a /var/www/rutorrent/conf/users/$user/plugins/autodl-irssi/conf.php > /dev/null
echo "\$autodlPort = $adlport;" | tee -a /var/www/rutorrent/conf/users/$user/plugins/autodl-irssi/conf.php > /dev/null
echo "\$autodlPassword = \"$adlpass\";" | tee -a /var/www/rutorrent/conf/users/$user/plugins/autodl-irssi/conf.php > /dev/null
echo | tee -a /var/www/rutorrent/conf/users/$user/plugins/autodl-irssi/conf.php > /dev/null
echo "?>" | tee -a /var/www/rutorrent/conf/users/$user/plugins/autodl-irssi/conf.php > /dev/null

cd $home/.autodl
echo "[options]" | tee autodl2.cfg > /dev/null
echo "gui-server-port = $adlport" | tee -a autodl2.cfg > /dev/null
echo "gui-server-password = $adlpass" | tee -a autodl2.cfg > /dev/null

perl -pi -e "s/if \(\\$\.browser\.msie\)/if \(navigator\.appName \=\= \'Microsoft Internet Explorer\' \&\& navigator\.userAgent\.match\(\/msie 6\/i\)\)/g" /var/www/rutorrent/plugins/autodl-irssi/AutodlFilesDownloader.js

# set permissions
chown -R www-data:www-data /var/www
chmod -R 755 /var/www/rutorrent
chown -R $user:$user $home

cd $home

edit_su
rm /usr/local/bin/edit_su

rm -r $home/rtscripts

su $user -c '/usr/local/bin/rt start'
su $user -c '/usr/local/bin/rt -i start'

sleep 2
sudo -u $user screen -S irssi -p 0 -X stuff "/WINDOW LOG ON $home/ir.log$(printf \\r)"
sudo -u $user screen -S irssi -p 0 -X stuff "/autodl update$(printf \\r)"
echo -n "updating autodl-irssi"
while ! ((tail -n1 $home/ir.log | grep -c -q "You are using the latest autodl-trackers") || (tail -n1 $home/ir.log | grep -c -q "Successfully loaded tracker files"))
do
sleep 1
echo -n " ."
done
echo
sudo -u $user screen -S irssi -p 0 -X stuff "/WINDOW LOG OFF$(printf \\r)"
sleep 1
sudo -u $user screen -S irssi -p 0 -X quit
sleep 2
su $user -c '/usr/local/bin/rt -i start > /dev/null'
rm $home/ir.log
echo "autodl-irssi update complete"

(crontab -u $user -l; echo "$cronline1" ) | crontab -u $user -
(crontab -u $user -l; echo "$cronline2" ) | crontab -u $user -
echo
echo "crontab entries made. rtorrent and irssi will start on boot for $user"
echo
echo "ftp client should be set to explicit ftp over tls using port $ftpport" | tee -a $home/rtinst.info
echo
if [ $DLFLAG = 0 ]
  then
    find $home -type d -print0 | xargs -0 chmod 755 
    echo "Access https downloads at https://$SERVERIP/download/$user" | tee -a $home/rtinst.info
    echo
fi
echo "rutorrent can be accessed at https://$SERVERIP/rutorrent" | tee -a $home/rtinst.info
echo "rutorrent password set to $WEBPASS" | tee -a $home/rtinst.info
echo "to change rutorrent password enter: rtpass" | tee -a $home/rtinst.info
echo
if ! [ -z "$sshport" ]
  then
    echo "IMPORTANT: SSH Port set to $sshport - Ensure you can login before closing this session"
	echo "ssh port changed to $sshport" | tee -a $home/rtinst.info > /dev/null
fi
echo
echo "The above information is stored in rtinst.info in your home directory."
echo "To see contents enter: cat $home/rtinst.info"
chown $user rtinst.info
