#!/bin/bash
PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/bin:/sbin
FULLREL=$(cat /etc/issue.net)
SERVERIP=$(ip a s eth0 | awk '/inet / {print$2}' | cut -d/ -f1)
WEBPASS=''
cronline1="@reboot sleep 10; /usr/local/bin/rtcheck irssi rtorrent"
cronline2="*/10 * * * * /usr/local/bin/rtcheck irssi rtorrent"
DLFLAG=1
logfile="/dev/null"
gotip=0
install_rt=0
sshport=''
rudevflag=1
passfile='/etc/nginx/.htpasswd'
package_list="sudo nano autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libcloog-ppl-dev libcppunit-dev libcurl3 libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libtool libxml2-dev ncurses-base ncurses-term ntp patch pkg-config php5-fpm php5 php5-cli php5-dev php5-curl php5-geoip php5-mcrypt php5-xmlrpc python-scgi screen subversion texinfo unrar-free unzip zlib1g-dev libcurl4-openssl-dev mediainfo python-software-properties software-properties-common aptitude php5-json nginx-full apache2-utils git libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libjson-perl libjson-xs-perl libxml-libxslt-perl libjson-rpc-perl libarchive-zip-perl"
install_list=""

#exit on error function
error_exit() {
echo "Error: $1"
echo "This is most likely a network error, if your network is working, then it is likely a temporary issue with the relevant file server"
echo "Run 'bash rtinst.sh -l' for detailed output to rtinst.log"
echo "Once issue is resolved the script can be run again to complete installation"
if ! [ -z "$sshport" ]; then
  echo "SSH Port was set before script was stopped to $sshport"
  echo "make sure you can login before closing this session"
fi
exit 1
}

#function to generate random password
genpasswd() {
local genln=$1
[ -z "$genln" ] && genln=8
tr -dc A-Za-z0-9 < /dev/urandom | head -c ${genln} | xargs
}

#function to determine random number between 2 numbers
random()
{
    local min=$1
    local max=$2
    local RAND=`od -t uI -N 4 /dev/urandom | awk '{print $2}'`
    RAND=$((RAND%((($max-$min)+1))+$min))
    echo $RAND
}

#function to fetch the rtinst scripts and files
get_scripts() {
local script_name=$1
local script_dest=$2
local attempts=0
local script_size=0
local bindest="/usr/local/bin"

while [ $script_size = 0 ]
  do
    rm -f $script_name
    attempts=$(( $attempts + 1 ))
    if [ $attempts = 20 ]; then
      error_exit "Problem downloading scripts from github - https://github.com/"
    fi
    wget --no-check-certificate https://raw.githubusercontent.com/arakasi72/rtinst/master/$script_name >> $logfile 2>&1
    script_size=$(du -b $script_name | cut -f1)
  done

if ! [ -z "$script_dest" ]; then
  mv -f $script_name $script_dest
  if case $script_dest in *"${bindest}"*) true;; *) false;; esac; then
    chmod 755 $script_dest
  fi
fi
}

# function to ask user for y/n response
ask_user(){
while true
  do
    read answer
    case $answer in [Yy]* ) return 0 ;;
                    [Nn]* ) return 1 ;;
                        * ) echo "Enter y or n";;
    esac
  done
}

enter_ip() {
echo "enter your server's name or IP address"
echo "e.g. example.com or 213.0.113.113"
read SERVERIP
echo "Your Server IP/Name is $SERVERIP"
echo -n "Is this correct y/n? "
ask_user
}

# determine system
test "${FULLREL#*Ubuntu 12.04}" != "$FULLREL" && RELNO=12
test "${FULLREL#*Ubuntu 13.10}" != "$FULLREL" && RELNO=13
test "${FULLREL#*Ubuntu 14}" != "$FULLREL" && RELNO=14
test "${FULLREL#*Debian*7}" != "$FULLREL" && RELNO=7
test "${FULLREL#*Debian*jessie}" != "$FULLREL" && RELNO=8
test "${FULLREL#*Debian*8}" != "$FULLREL" && RELNO=8
test -z "$RELNO" && echo "Unable to determine OS or OS unsupported" && exit
echo $FULLREL

# get options
while getopts ":dlr" optname
  do
    case $optname in
      "d" ) DLFLAG=0 ;;
      "l" ) logfile="$HOME/rtinst.log" ;;
      "r" ) rudevflag=0 ;;
        * ) echo "incorrect option, only -d, -l, and -r allowed" && exit 1 ;;
    esac
  done

shift $(( $OPTIND - 1 ))

# Check if there is more than 0 argument
if [ $# -gt 0 ]; then
  echo "No arguments allowed $1 is not a valid argument"
  exit 1
fi

# check IP Address
case $SERVERIP in
    127* ) gotip=1 ;;
  local* ) gotip=1 ;;
      "" ) gotip=1 ;;
esac

if [ $gotip = 1 ]; then
  echo "Unable to determine your IP address"
  gotip=enter_ip
else
  echo "Your Server IP/Name is $SERVERIP"
  echo -n "Is this correct y/n? "
  gotip=ask_user
fi

until $gotip
    do
      gotip=enter_ip
    done

echo "Your server's IP/Name is set to $SERVERIP"

#check rtorrent installation
if which rtorrent; then
  echo "It appears that rtorrent has been installed."
  echo -n "Do you wish to skip rtorrent compilation? "
  if ask_user; then
    install_rt=1
    echo "rtorrent installation will be skipped."
  else
    skip_rt=0
    echo "rtorrent will be re-installed"
  fi
fi

# set and prepare user
if test "$SUDO_USER" = "root" || { test -z "$SUDO_USER" &&  test "$LOGNAME" = "root"; }; then
  echo "Enter the name of the user to install to"
  echo "This will be your primary user"
  echo "It can be an existing user or a new user"
  echo

  confirm_name=1
  while [ $confirm_name = 1 ]
    do
      read -p "Enter user name: " answer
      addname=$answer
      echo -n "Confirm that user name is $answer y/n? "
      if ask_user; then
        confirm_name=0
      fi
    done

  user=$addname

  if id -u $user >/dev/null 2>&1; then
    echo "$user already exists"
  else
    adduser --gecos "" $user
  fi

elif ! [ -z "$SUDO_USER" ]; then
  user=$SUDO_USER
else
  echo "Script must be run using sudo or root"
  exit 1
fi

home="/home/$user"

#update amd upgrade system
if [ "$FULLREL" = "Ubuntu 12.04.5 LTS" ]; then
  wget --no-check-certificate https://help.ubuntu.com/12.04/sample/sources.list >> $logfile 2>&1 || error_exit "Unable to download sources file from https://help.ubuntu.com/12.04/sample/sources.list"
  cp /etc/apt/sources.list /etc/apt/sources.list.bak
  mv sources.list /etc/apt/sources.list
fi

echo "Updating package lists" | tee $logfile
apt-get update >> $logfile 2>&1
if ! [ $? = 0 ]; then
  error_exit "Problem updating packages."
fi

echo "Upgrading packages" | tee -a $logfile
apt-get -y upgrade >> $logfile 2>&1
if ! [ $? = 0 ]; then
  error_exit "Problem upgrading packages."
fi

apt-get clean && apt-get autoclean >> $logfile 2>&1

#install the packsges needed
echo "Installing required packages" | tee -a $logfile
for package_name in $package_list
  do
    if [ $(dpkg-query -W -f='${Status}' $package_name 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
      install_list="$install_list $package_name"
    fi
  done

test -z "$install_list" || apt-get -y install $install_list >> $logfile 2>&1

if [ $RELNO = 14 ] && [ $(dpkg-query -W -f='${Status}' "ffmpeg-real" 2>/dev/null | grep -c "ok installed") = 0 ]; then
  apt-add-repository -y ppa:samrog131/ppa >> $logfile 2>&1 || error_exit "Problem adding to repository from - https://launchpad.net/~samrog131/+archive/ubuntu/ppa"
  apt-get update >> $logfile 2>&1 || error_exit "problem updating package lists"
  apt-get -y install ffmpeg-real >> $logfile 2>&1
  ln -sf /opt/ffmpeg/bin/ffmpeg /usr/bin/ffmpeg
elif [ $RELNO = 8 ] && [ $(dpkg-query -W -f='${Status}' "ffmpeg" 2>/dev/null | grep -c "ok installed") = 0 ]; then
  grep "deb http://www.deb-multimedia.org jessie main" /etc/apt/sources.list >> /dev/null || echo "deb http://www.deb-multimedia.org jessie main" >> /etc/apt/sources.list
  apt-get update >> $logfile 2>&1 || error_exit "problem updating package lists"
  apt-get -y --force-yes install deb-multimedia-keyring >> $logfile 2>&1
  apt-get -y --force-yes install ffmpeg >> $logfile 2>&1
elif [ $(dpkg-query -W -f='${Status}' "ffmpeg" 2>/dev/null | grep -c "ok installed") = 0 ]; then
  apt-get -y install ffmpeg >> $logfile 2>&1
fi
echo "Completed installation of required packages        "

#add user to sudo group if not already
if groups $user | grep -q -E ' sudo(\s|$)'; then
  echo "$user already has sudo privileges"
else
  adduser $user sudo
fi

# download rt scripts and config files
echo "Fetching rtinst scripts" | tee -a $logfile
mkdir -p $home/rtscripts
cd $home/rtscripts

get_scripts rt /usr/local/bin/rt
get_scripts rtcheck /usr/local/bin/rtcheck
get_scripts rtupdate /usr/local/bin/rtupdate
get_scripts edit_su /usr/local/bin/edit_su
get_scripts rtpass /usr/local/bin/rtpass
get_scripts rtsetpass /usr/local/bin/rtsetpass
get_scripts rtdload /usr/local/bin/rtdload
get_scripts rtadduser /usr/local/bin/rtadduser
get_scripts rtremove /usr/local/bin/rtremove

get_scripts .rtorrent.rc
get_scripts ru.config
get_scripts ru.ini
get_scripts nginxsitedl
get_scripts nginxsite

cd $home

#raise file limits
sed -i '/# End of file/ i\* hard nofile 32768\n* soft nofile 16384\n' /etc/security/limits.conf

# secure ssh
echo "Securing SSH" | tee -a $logfile

portline=$(grep 'Port ' /etc/ssh/sshd_config)
if [ "$portline" = "Port 22" ]; then
  sshport=$(random 21000 29000)
  sed -i "s/Port 22/Port $sshport/g" /etc/ssh/sshd_config
fi

sed -i "s/X11Forwarding yes/X11Forwarding no/g" /etc/ssh/sshd_config
sed -i '/^PermitRootLogin/ c\PermitRootLogin no' /etc/ssh/sshd_config

usedns=$(grep UseDNS /etc/ssh/sshd_config)
if [ -z "$usedns" ]; then
  echo "UseDNS no" >> /etc/ssh/sshd_config
else
 sed -i "s/$usedns/UseDNS no/g" /etc/ssh/sshd_config
fi

if [ -z "$(grep sshuser /etc/group)" ]; then
groupadd sshuser
fi

allowlist=$(grep AllowUsers /etc/ssh/sshd_config)
if ! [ -z "$allowlist" ]; then
  for ssh_user in $allowlist
    do
      if  ! [ "$ssh_user" = "AllowUsers" -o "$(groups $ssh_user 2> /dev/null | grep -E ' sudo(\s|$)')" != "" ]; then
        adduser $ssh_user sshuser
      fi
    done
  sed -i "s/$allowlist//g" /etc/ssh/sshd_config
fi
grep "AllowGroups sudo sshuser" /etc/ssh/sshd_config > /dev/null || echo "AllowGroups sudo sshuser" >> /etc/ssh/sshd_config

service ssh restart
sshport=$(grep 'Port ' /etc/ssh/sshd_config | sed 's/[^0-9]*//g')
echo "SSH secured. Port set to $sshport"

# install ftp

ftpport=$(random 41005 48995)

if [ $(dpkg-query -W -f='${Status}' "vsftpd" 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  echo "Installing vsftpd" | tee -a $logfile

  if [ $RELNO = 12 ]; then
    add-apt-repository -y ppa:thefrontiergroup/vsftpd >> $logfile 2>&1
    apt-get update >> $logfile 2>&1
    apt-get -y install vsftpd >> $logfile 2>&1
  elif [ $RELNO = 7 ]; then
    echo "deb http://ftp.cyconet.org/debian wheezy-updates main non-free contrib" >> /etc/apt/sources.list.d/wheezy-updates.cyconet2.list
    aptitude update  >> $logfile 2>&1 || error_exit "problem updating package lists"
    aptitude -o Aptitude::Cmdline::ignore-trust-violations=true -y install -t wheezy-updates debian-cyconet-archive-keyring vsftpd  >> $logfile 2>&1 || error_exit "Unable to download vsftpd"
  else
    apt-get -y install vsftpd >> $logfile 2>&1
  fi

fi
echo "Configuring vsftpd" | tee -a $logfile

sed -i '/^#\?anonymous_enable/ c\anonymous_enable=NO' /etc/vsftpd.conf
sed -i '/^#\?local_enable/ c\local_enable=YES' /etc/vsftpd.conf
sed -i '/^#\?write_enable/ c\write_enable=YES' /etc/vsftpd.conf
sed -i '/^#\?local_umask/ c\local_umask=022' /etc/vsftpd.conf
sed -i '/^#\?listen=/ c\listen=YES' /etc/vsftpd.conf
sed -i 's/^listen_ipv6/#listen_ipv6/g' /etc/vsftpd.conf
sed -i 's/^rsa_private_key_file/#rsa_private_key_file/g' /etc/vsftpd.conf
sed -i '/^rsa_cert_file/ c\rsa_cert_file=\/etc\/ssl\/private\/vsftpd\.pem' /etc/vsftpd.conf

grep ^listen_port /etc/vsftpd.conf > /dev/null || echo "listen_port=$ftpport" >> /etc/vsftpd.conf

if [ -z "$(grep ^ssl_enable /etc/vsftpd.conf)" ]; then
  echo "ssl_enable=YES" >> /etc/vsftpd.conf
else
  sed -i '/^ssl_enable/ c\ssl_enable=YES' /etc/vsftpd.conf
fi

if [ -z "$(grep ^chroot_local_user /etc/vsftpd.conf)" ];then
  echo "chroot_local_user=YES" >> /etc/vsftpd.conf
else
 sed -i '/^chroot_local_user/ c\chroot_local_user=YES' /etc/vsftpd.conf
fi

if [ -z "$(grep ^allow_writeable_chroot /etc/vsftpd.conf)" ]; then
   echo "allow_writeable_chroot=YES" >> /etc/vsftpd.conf
else
  sed -i '/^allow_writeable_chroot/ c\allow_writeable_chroot=YES' /etc/vsftpd.conf
fi

if [ -z "$(grep ^allow_anon_ssl /etc/vsftpd.conf)" ];then
  echo "allow_anon_ssl=NO" >> /etc/vsftpd.conf
else
   sed -i '/^allow_anon_ssl/ c\allow_anon_ssl=NO' /etc/vsftpd.conf
fi

if [ -z "$(grep ^force_local_data_ssl /etc/vsftpd.conf)" ];then
  echo "force_local_data_ssl=YES" >> /etc/vsftpd.conf
else
  sed -i '/^force_local_data_ssl/ c\force_local_data_ssl=YES' /etc/vsftpd.conf
fi

if [ -z "$(grep ^force_local_logins_ssl /etc/vsftpd.conf)" ];then
  echo "force_local_logins_ssl=YES" >> /etc/vsftpd.conf
else
  sed -i '/^force_local_logins_ssl/ c\force_local_logins_ssl=YES' /etc/vsftpd.conf
fi

if [ -z "$(grep ^ssl_sslv2 /etc/vsftpd.conf)" ];then
  echo "ssl_sslv2=YES" >> /etc/vsftpd.conf
else
  sed -i '/^ssl_sslv2/ c\ssl_sslv2=YES' /etc/vsftpd.conf
fi

if [ -z "$(grep ^ssl_sslv3 /etc/vsftpd.conf)" ];then
  echo "ssl_sslv3=YES" >> /etc/vsftpd.conf
else
  sed -i '/^ssl_sslv3/ c\ssl_sslv3=YES' /etc/vsftpd.conf
fi

if [ -z "$(grep ^ssl_tlsv1 /etc/vsftpd.conf)" ];then
  echo "ssl_tlsv1=YES" >> /etc/vsftpd.conf
else
  sed -i '/^ssl_tlsv1/ c\ssl_tlsv1=YES' /etc/vsftpd.conf
fi

if [ -z "$(grep ^require_ssl_reuse /etc/vsftpd.conf)" ];then
  echo "require_ssl_reuse=NO" >> /etc/vsftpd.conf
else
  sed -i '/^require_ssl_reuse/ c\require_ssl_reuse=NO' /etc/vsftpd.conf
fi

if [ -z "$(grep ^ssl_ciphers /etc/vsftpd.conf)" ];then
  echo "ssl_ciphers=HIGH" >> /etc/vsftpd.conf
else
  sed -i '/^ssl_ciphers/ c\ssl_ciphers=HIGH' /etc/vsftpd.conf
fi

openssl req -x509 -nodes -days 3650 -subj /CN=$SERVERIP -newkey rsa:2048 -keyout /etc/ssl/private/vsftpd.pem -out /etc/ssl/private/vsftpd.pem >> $logfile 2>&1

service vsftpd restart

ftpport=$(grep 'listen_port=' /etc/vsftpd.conf | sed 's/[^0-9]*//g')
echo "FTP port set to $ftpport"

# install rtorrent
if [ $install_rt = 0 ]; then
  cd $home
  mkdir -p source
  cd source
  echo "Downloading rtorrent source files" | tee -a $logfile

  svn co https://svn.code.sf.net/p/xmlrpc-c/code/stable xmlrpc  >> $logfile 2>&1 || error_exit "Unable to download xmlrpc source files from https://svn.code.sf.net/p/xmlrpc-c/code/stable"
  curl -# http://libtorrent.rakshasa.no/downloads/libtorrent-0.13.4.tar.gz | tar xz  >> $logfile 2>&1 || error_exit "Unable to download libtorrent source files from http://libtorrent.rakshasa.no/downloads"
  curl -# http://libtorrent.rakshasa.no/downloads/rtorrent-0.9.4.tar.gz | tar xz  >> $logfile 2>&1 || error_exit "Unable to download rtorrent source files from http://libtorrent.rakshasa.no/downloads"

  cd xmlrpc
  echo "Installing xmlrpc" | tee -a $logfile
  ./configure --prefix=/usr --enable-libxml2-backend --disable-libwww-client --disable-wininet-client --disable-abyss-server --disable-cgi-server >> $logfile 2>&1
  make >> $logfile 2>&1
  make install >> $logfile 2>&1

  cd ../libtorrent-0.13.4
  echo "Installing libtorrent" | tee -a $logfile
  ./autogen.sh >> $logfile 2>&1
  ./configure --prefix=/usr >> $logfile 2>&1
  make -j2 >> $logfile 2>&1
  make install >> $logfile 2>&1

  cd ../rtorrent-0.9.4
  echo "Installing rtorrent" | tee -a $logfile
  ./autogen.sh >> $logfile 2>&1
  ./configure --prefix=/usr --with-xmlrpc-c >> $logfile 2>&1
  make -j2 >> $logfile 2>&1
  make install >> $logfile 2>&1
  ldconfig >> $logfile 2>&1
else
 echo "skiping rtorrent installation" | tee -a $logfile
fi

echo "Configuring rtorrent" | tee -a $logfile
cd $home

mkdir -p rtorrent/.session
mkdir -p rtorrent/downloads
mkdir -p rtorrent/watch


mv -f $home/rtscripts/.rtorrent.rc $home/.rtorrent.rc
sed -i "s/<user name>/$user/g" $home/.rtorrent.rc

# install rutorrent


mkdir -p /var/www
cd /var/www

if [ -d "/var/www/rutorrent" ]; then
  rm -r /var/www/rutorrent
fi

if [ $rudevflag = 1 ]; then
  echo "Installing Rutorrent (stable)" | tee -a $logfile
  svn checkout https://bintray.com/artifact/download/novik65/generic/rutorrent-3.6.tar.gz >> $logfile 2>&1 || error_exit "Unable to download rutorrent files from http://rutorrent.googlecode.com/svn/trunk/rutorrent"
  svn checkout https://bintray.com/artifact/download/novik65/generic/plugins-3.6.tar.gz >> $logfile 2>&1 || error_exit "Unable to download rutorrent plugin files from http://rutorrent.googlecode.com/svn/trunk/plugins"
  rm -r rutorrent/plugins
  mv plugins rutorrent
else
  echo "Installing Rutorrent (development)" | tee -a $logfile
  git clone https://github.com/Novik/ruTorrent.git
  mv ruTorrent rutorrent
fi

echo "Configuring Rutorrent" | tee -a $logfile
rm rutorrent/conf/config.php
mv $home/rtscripts/ru.config /var/www/rutorrent/conf/config.php
mkdir -p /var/www/rutorrent/conf/users/$user/plugins

echo "<?php" > /var/www/rutorrent/conf/users/$user/config.php
echo >> /var/www/rutorrent/conf/users/$user/config.php
echo "\$topDirectory = '$home';" >> /var/www/rutorrent/conf/users/$user/config.php
echo "\$scgi_port = 5000;" >> /var/www/rutorrent/conf/users/$user/config.php
echo "\$XMLRPCMountPoint = \"/RPC2\";" >> /var/www/rutorrent/conf/users/$user/config.php
echo >> /var/www/rutorrent/conf/users/$user/config.php
echo "?>" >> /var/www/rutorrent/conf/users/$user/config.php

mv $home/rtscripts/ru.ini /var/www/rutorrent/conf/plugins.ini

# install nginx
cd $home

if [ -f "/etc/apache2/ports.conf" ]; then
  echo "Detected apache2. Changing apache2 port to 81 in /etc/apache2/ports.conf" | tee -a $logfile
  sed -i "s/Listen 80/Listen 81/g" /etc/apache2/ports.conf
  service apache2 stop >> $logfile 2>&1
fi

echo "Installing nginx" | tee -a $logfile
WEBPASS=$(genpasswd)
htpasswd -c -b $passfile $user $WEBPASS >> $logfile 2>&1
chown www-data:www-data $passfile
chmod 640 $passfile

openssl req -x509 -nodes -days 3650 -subj /CN=$SERVERIP -newkey rsa:2048 -keyout /etc/ssl/ruweb.key -out /etc/ssl/ruweb.crt >> $logfile 2>&1

sed -i "s/user www-data;/user www-data www-data;/g" /etc/nginx/nginx.conf
sed -i "s/worker_processes 4;/worker_processes 1;/g" /etc/nginx/nginx.conf
sed -i "s/pid \/run\/nginx\.pid;/pid \/var\/run\/nginx\.pid;/g" /etc/nginx/nginx.conf
sed -i "s/# server_tokens off;/server_tokens off;/g" /etc/nginx/nginx.conf
sed -i "s/access_log \/var\/log\/nginx\/access\.log;/access_log off;/g" /etc/nginx/nginx.conf
sed -i "s/error\.log;/error\.log crit;/g" /etc/nginx/nginx.conf
grep client_max_body_size /etc/nginx/nginx.conf > /dev/null 2>&1 || sed -i "/server_tokens off;/ a\        client_max_body_size 40m;\n" /etc/nginx/nginx.conf
sed -i "/upload_max_filesize/ c\upload_max_filesize = 40M" /etc/php5/fpm/php.ini
sed -i '/^;\?listen.owner/ c\listen.owner = www-data' /etc/php5/fpm/pool.d/www.conf
sed -i '/^;\?listen.group/ c\listen.group = www-data' /etc/php5/fpm/pool.d/www.conf
sed -i '/^;\?listen.mode/ c\listen.mode = 0660' /etc/php5/fpm/pool.d/www.conf

if [ $RELNO = 12 ] || [ $RELNO = 7 ]; then
  cp /usr/share/nginx/www/* /var/www
else
  cp /usr/share/nginx/html/* /var/www
fi

mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.old

mv $home/rtscripts/nginxsite /etc/nginx/sites-available/default
mv $home/rtscripts/nginxsitedl /etc/nginx/conf.d/rtdload

echo "location ~ \.php$ {" > /etc/nginx/conf.d/php
echo "          fastcgi_split_path_info ^(.+\.php)(/.+)$;" >> /etc/nginx/conf.d/php
if [ $RELNO = 12 ]; then
  echo "          fastcgi_pass 127.0.0.1:9000;" >> /etc/nginx/conf.d/php
else
  echo "          fastcgi_pass unix:/var/run/php5-fpm.sock;" >> /etc/nginx/conf.d/php
fi
echo "          fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;" >> /etc/nginx/conf.d/php
echo "          fastcgi_index index.php;" >> /etc/nginx/conf.d/php
echo "          include fastcgi_params;" >> /etc/nginx/conf.d/php
echo "}" >> /etc/nginx/conf.d/php

echo "location ~* \.(jpg|jpeg|gif|css|png|js|woff|ttf|svg|eot)$ {" > /etc/nginx/conf.d/cache
echo "        expires 30d;" >> /etc/nginx/conf.d/cache
echo "}" >> /etc/nginx/conf.d/cache

if [ $DLFLAG = 0 ]; then
  sed -i "s/#include \/etc\/nginx\/conf\.d\/rtdload;/include \/etc\/nginx\/conf\.d\/rtdload;/g" /etc/nginx/sites-available/default
fi

sed -i "s/<Server IP>/$SERVERIP/g" /etc/nginx/sites-available/default

service nginx restart && service php5-fpm restart

# install autodl-irssi
echo "Installing autodl-irssi" | tee -a $logfile
adlport=$(random 36001 36100)
adlpass=$(genpasswd $(random 12 16))

mkdir -p $home/.irssi/scripts/autorun
cd $home/.irssi/scripts
wget --no-check-certificate -O autodl-irssi.zip http://update.autodl-community.com/autodl-irssi-community.zip >> $logfile 2>&1 || error_exit "Unable to download autodl scripts from http://update.autodl-community.com/"
unzip -o autodl-irssi.zip >> $logfile 2>&1
rm autodl-irssi.zip
cp autodl-irssi.pl autorun/
mkdir -p $home/.autodl
touch $home/.autodl/autodl.cfg && touch $home/.autodl/autodl2.cfg

cd /var/www/rutorrent/plugins
git clone https://github.com/autodl-community/autodl-rutorrent.git autodl-irssi >> $logfile 2>&1 || error_exit "Unable to download autodl plugin files from https://github.com/autodl-community/autodl-irssi"

mkdir /var/www/rutorrent/conf/users/$user/plugins/autodl-irssi

touch /var/www/rutorrent/conf/users/$user/plugins/autodl-irssi/conf.php

echo "<?php" > /var/www/rutorrent/conf/users/$user/plugins/autodl-irssi/conf.php
echo >> /var/www/rutorrent/conf/users/$user/plugins/autodl-irssi/conf.php
echo "\$autodlPort = $adlport;" >> /var/www/rutorrent/conf/users/$user/plugins/autodl-irssi/conf.php
echo "\$autodlPassword = \"$adlpass\";" >> /var/www/rutorrent/conf/users/$user/plugins/autodl-irssi/conf.php
echo >> /var/www/rutorrent/conf/users/$user/plugins/autodl-irssi/conf.php
echo "?>" >> /var/www/rutorrent/conf/users/$user/plugins/autodl-irssi/conf.php

cd $home/.autodl
echo "[options]" > autodl2.cfg
echo "gui-server-port = $adlport" >> autodl2.cfg
echo "gui-server-password = $adlpass" >> autodl2.cfg

sed -i "s/if (\\$\.browser\.msie)/if (navigator\.appName == \'Microsoft Internet Explorer\' \&\& navigator\.userAgent\.match(\/msie 6\/i))/g" /var/www/rutorrent/plugins/autodl-irssi/AutodlFilesDownloader.js

# set permissions
echo "Setting permissions, Starting services" | tee -a $logfile
chown -R www-data:www-data /var/www
chmod -R 755 /var/www/rutorrent
chown -R $user:$user $home

cd $home

edit_su
rm /usr/local/bin/edit_su

rm -r $home/rtscripts

su $user -c '/usr/local/bin/rt restart'
su $user -c '/usr/local/bin/rt -i restart'

sleep 2
sudo -u $user screen -S irssi -p 0 -X stuff "/WINDOW LOG ON $home/ir.log$(printf \\r)"
sudo -u $user screen -S irssi -p 0 -X stuff "/autodl update$(printf \\r)"
echo -n "updating autodl-irssi"
sleep 3
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

if [ -z "$(crontab -u $user -l | grep "$cronline1")" ]; then
    (crontab -u $user -l; echo "$cronline1" ) | crontab -u $user - >> $logfile 2>&1
fi

if [ -z  "$(crontab -u $user -l | grep "\*/10 \* \* \* \* /usr/local/bin/rtcheck irssi rtorrent")" ]; then
    (crontab -u $user -l; echo "$cronline2" ) | crontab -u $user - >> $logfile 2>&1
fi

echo
echo "crontab entries made. rtorrent and irssi will start on boot for $user"
echo
echo "ftp client should be set to explicit ftp over tls using port $ftpport" | tee $home/rtinst.info
echo
if [ $DLFLAG = 0 ]; then
  find $home -type d -print0 | xargs -0 chmod 755
  echo "Access https downloads at https://$SERVERIP/download/$user" | tee -a $home/rtinst.info
  echo
fi
echo "rutorrent can be accessed at https://$SERVERIP/rutorrent" | tee -a $home/rtinst.info
echo "rutorrent password set to $WEBPASS" | tee -a $home/rtinst.info
echo "to change rutorrent password enter: rtpass" | tee -a $home/rtinst.info
echo
echo "IMPORTANT: SSH Port set to $sshport - Ensure you can login before closing this session"
echo "ssh port changed to $sshport" | tee -a $home/rtinst.info > /dev/null
echo
echo "The above information is stored in rtinst.info in your home directory."
echo "To see contents enter: cat $home/rtinst.info"
echo "PLEASE REBOOT YOUR SYSTEM ONCE YOU HAVE NOTED THE ABOVE INFORMATION"
chown $user rtinst.info
