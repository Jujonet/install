#!/bin/sh
#
# Installation automatique de KnxD / LinKnx / KnxWeb + YANA4ALL
# sur Linux Debian et egalement sur Raspberry Pi - Raspbian
# Credits : Ivan Morgade, Anthony PENHARD
# Script libre: GPLv3
#
# pour rendre le script executable :
#     sudo chmod u+x install-trio.sh
# Syntaxe: # sudo ./install-trio.sh
# sudo sh ./install-trio.sh --with-mysql --login=knx --password=knx --groups=adm
# sudo sh ./install-trio.sh --with-mysql --login=knx --password=knx
#
# wget -q http://www.knxweb.fr/install_trio/install-trio.sh
# sudo chmod 777 install-trio.sh
# sudo ./install-trio.sh
# sudo sh ./install-trio.sh --with-mysql --login=knx --password=knx
# sudo sh ./install-trio.sh --with-mysql --with-webmin
#
version="0.18"; # 03/12/2017 => Php7.0

if [ "$(id -u)" != "0" ]; then
   echo "     Attention!!!"
   echo "     Start script must run as root" 1>&2
   echo "     Start a root shell with"
   echo "     sudo su -"
   exit 1
fi

SCRIPT_PATH=$PWD
#knxd_ipport="192.168.1.2"
knxd_ipport=""
help_message=:
version_message=:
user_login="knx"
password="knx"
groups="";
linknx_xml="/var/www/knxweb";
dir_knxweb="knxweb"; # nom dossier ou est installé knxweb
path_knxweb="/var/www/html/$dir_knxweb/"; # nouvelle version apache /var/www/html/...
PAQUAGES=" ";

#service_Systemd=false
service_Systemd=true

#echo "LC_ALL=C" > /etc/default/locale

datedeb=`date '+%s'`;

# extrait du "configure" de linknx pour faire ce script :
as_nl='
'
export as_nl
# Printing a long string crashes Solaris 7 /usr/bin/printf.
as_echo='\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\'
as_echo=$as_echo$as_echo$as_echo$as_echo$as_echo
as_echo=$as_echo$as_echo$as_echo$as_echo$as_echo$as_echo
# Prefer a ksh shell builtin over an external printf program on Solaris,
# but without wasting forks for bash or zsh.
if test -z "$BASH_VERSION$ZSH_VERSION" \
    && (test "X`print -r -- $as_echo`" = "X$as_echo") 2>/dev/null; then
  as_echo='print -r --'
  as_echo_n='print -rn --'
elif (test "X`printf %s $as_echo`" = "X$as_echo") 2>/dev/null; then
  as_echo='printf %s\n'
  as_echo_n='printf %s'
else
  if test "X`(/usr/ucb/echo -n -n $as_echo) 2>/dev/null`" = "X-n $as_echo"; then
    as_echo_body='eval /usr/ucb/echo -n "$1$as_nl"'
    as_echo_n='/usr/ucb/echo -n'
  else
    as_echo_body='eval expr "X$1" : "X\\(.*\\)"'
    as_echo_n_body='eval
      arg=$1;
      case $arg in #(
      *"$as_nl"*)
 expr "X$arg" : "X\\(.*\\)$as_nl";
 arg=`expr "X$arg" : ".*$as_nl\\(.*\\)"`;;
      esac;
      expr "X$arg" : "X\\(.*\\)" | tr -d "$as_nl"
    '
    export as_echo_n_body
    as_echo_n='sh -c $as_echo_n_body as_echo'
  fi
  export as_echo_body
  as_echo='sh -c $as_echo_body as_echo'
fi


# Avoid depending upon Character Ranges.
as_cr_letters='abcdefghijklmnopqrstuvwxyz'
as_cr_LETTERS='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
as_cr_Letters=$as_cr_letters$as_cr_LETTERS
as_cr_digits='0123456789'
as_cr_alnum=$as_cr_Letters$as_cr_digits

#if test $# = 0
#then
#  help_message=true;
#fi


while test $# != 0
do
  case $1 in
  --*=*)
    ac_option=`expr "X$1" : 'X\([^=]*\)='`
    ac_optarg=`expr "X$1" : 'X[^=]*=\(.*\)'`
    ;;
  -* | --*)
    ac_option=$1
    ac_optarg=yes
    ;;
  *)
    ac_option=$1
    ac_optarg=$2
    ;;
  esac

#  case $ac_option in
#  *=*) ac_optarg=`expr "X$ac_option" : '[^=]*=\(.*\)'` ;;
#  *) ac_optarg=yes ;;
#  esac

  case $ac_option in
  -help | --help | --hel | --he | -h | --? | -?)
    help_message=true;;
  -version | --version | --versio | --versi | --vers | -V)
    version_message=true;;

  -login* | --login*)
    case $ac_optarg in
    *\'*) ac_optarg=`$as_echo "$ac_optarg" | sed "s/'/'\\\\\\\\''/g"` ;;
    esac
    user_login=$ac_optarg
    ;;
  -password* | --password*)
    case $ac_optarg in
    *\'*) ac_optarg=`$as_echo "$ac_optarg" | sed "s/'/'\\\\\\\\''/g"` ;;
    esac
    password=$ac_optarg
    ;;
  -groups* | --groups*)
    case $ac_optarg in
    *\'*) ac_optarg=`$as_echo "$ac_optarg" | sed "s/'/'\\\\\\\\''/g"` ;;
    esac
    groups=$ac_optarg
    ;;

  --knxd-ipport*)
    knxd_ipport=$ac_optarg
    ;;

  -with-* | --with-*)
    ac_useropt=`expr "x$ac_option" : 'x-*with-\([^=]*\)'`
    # Reject names that are not valid shell variable names.
    expr "x$ac_useropt" : ".*[^-+._$as_cr_alnum]" >/dev/null &&
       "invalid package name: $ac_useropt"
    ac_useropt_orig=$ac_useropt
    ac_useropt=`$as_echo "$ac_useropt" | sed 's/[-+.]/_/g'`
    eval with_$ac_useropt=\$ac_optarg ;;

  -without-* | --without-*)
    ac_useropt=`expr "x$ac_option" : 'x-*without-\(.*\)'`
    # Reject names that are not valid shell variable names.
    expr "x$ac_useropt" : ".*[^-+._$as_cr_alnum]" >/dev/null &&
       "invalid package name: $ac_useropt"
    ac_useropt_orig=$ac_useropt
    ac_useropt=`$as_echo "$ac_useropt" | sed 's/[-+.]/_/g'`
    eval with_$ac_useropt=no ;;

  -linknx_xml | --linknx_xml)
    ac_useropt="linknx_xml"
    eval $ac_useropt=\$ac_optarg ;;

  # This is an error.
  -*) echo "unrecognized option: '$1'
Try '$0 --help' for more information."
      exit ;;

  *) echo "ambiguous option: '$1'
Try '$0 --help' for more information."
     exit ;;

  esac
  shift
done

if test "$help_message" = true; then
  cat << DOCUMENTATIONXX
−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−
  Script d'install de knxd / LinKnx / KnxWeb pour linux Debian
−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−
Distributions Linux compatibles avec ce script Debian, Ubuntu,
Raspbian ( pour Raspberry Pi )

Usage: $0 [OPTION]...

  -h, --help      aide
  -V, --version   info sur la version du script et des composants installe

  --with-webmin   Install Webmin par defaut ne le fait pas

Parametres pour creation du user qui va lancer knxd/linknx + Mysql:
  --login         Login User et Mysql
  --password      Password login User et Mysql
  --groups        Groups du User cree
  --with-mysql    Avec mysql

Parametres pour knxd :
  --knxd-ipport=IP
                  si passerelle Knx de type "IP" ex. 192.168.1.2

Parametres pour LinKnx :
  --linknx_xml=/var/www/knxweb
                  path utiliser pour le fichier linknx.xml il sera dupliquer
                  dans ce dossier et utiliser au demarrage de linknx
                  par defaut vaut : /var/www/knxweb2

Parametres pour KnxWeb :
  Aucun

Exemple :
sudo sh ./install-trio.sh --with-mysql --login=knx --password=knx --with-webmin

DOCUMENTATIONXX
  exit
fi

if test "$version_message" = true; then
  cat << VERSIONXX
Script d'install de knxd / LinKnx / KnxWeb pour linux Debian
−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−
Version de ce script $version

Install de :
 - pthsem  : 2.0.8
 - knxd    : 0.12
 - linknx  : 0.0.1.34
 - knxweb  : 2.1.1

 - WebIOPi : Specifique au Rasbperry Pi gestion des GPIO via page Web
            version 0.7.1
 - webmin  : par defaut non installe ajouter le parametre --with-webmin
            version 1.780

VERSIONXX
  exit
fi

echo "-------------------------------------------------------------------";
echo "Script d'install de knxd / LinKnx / KnxWeb pour linux Debian";
echo "Version de ce script $version";
date
echo "-------------------------------------------------------------------";
echo " ";
# Name of the host.
# hostname on some systems (SVR3.2, Linux) returns a bogus exit status,
# so uname gets run too.
ac_hostname=`(hostname || uname -n) 2>/dev/null | sed 1q`

( grep flags /proc/cpuinfo | grep -q '\<lm\>' ) &&  echo "----==== MACHINE 64 bits hostname : $ac_hostname ====----" || echo "----==== MACHINE 32 bits hostname : $ac_hostname  ====----"

kernel=`uname -mrs`
firmware=`uname -v`

echo "- kernel   : $kernel "
echo "- firmware : $firmware "


# IPs :
INTERFACE=eth0
#IP_machine=`ifconfig $INTERFACE | grep "inet adr" | sed 's/.*adr:\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\).*/\1/'`
#IP_machine=`/sbin/ifconfig $INTERFACE | grep inet | cut -d ":" -f 2 | cut -d " " -f 1`

##!!!! firstip() : Return First IP
firstip() {
	echo $(hostname -I |cut -f1 -d' ')
}
IP_machine=$(firstip)

IP_publique=`wget -q www.monip.org -O -  | iconv -f iso8859-1 -t utf8 | sed -nre 's/^.* (([0-9]{1,3}\.){3}[0-9]{1,3}).*$/\1/p'`

echo "IP local : $IP_machine IP Publique : $IP_publique"

# espace disque :
disk_usep=`df | awk 'NR == 2 { print $5+0; exit }'`
disk_tot=`df | awk 'NR == 2 { print $2+0; exit }'`
disk_use=`df | awk 'NR == 2 { print $3+0; exit }'`
disk_free=`df | awk 'NR == 2 { print $4+0; exit }'`
disk_free=$(( $disk_free / 1024))
echo "Espace disque utilise $disk_usep % soit $disk_free Mo d'espace libre "
echo "-------------------------------------------------------------------"

echo "-------------------------------------------------------------------"
echo "----======  User pour lancer knxd et Linknx + Mysql  ======----"
# recuperation des login, password et groups si non presents en parametres
if test "x$user_login" = x:; then
  echo "-------------------------------------------------------------------"
  echo "-                                                                 -"
  echo "-                                                                 -"
  echo "Entrez le nom du compte User (lance knxd) et Mysql a creer :  /[knx]"
  read user_login;
  if test "x$user_login" = x; then
    user_login="knx";
  fi
fi

if test "x$password" = x:; then
  echo "-                                                                 -"
  echo "Entrez son mot de passe : "
  read password;
fi

if test "x$groups" = x; then
  #groups="www-data";
  groups="adm";
fi

#echo "login *$user_login* password *$password* groups *$groups*"
# creation du user (le programme s'arrête par securite si le user existe deja )
if test "x$user_login" != x; then
  echo "Creation de l'utilisateur '$user_login' "
#  # /usr/sbin/useradd $user_login -p `perl -e "print crypt('$password',pwet)"` -g vhosts -d /home/$user_login -m -s /bin/bash
  /usr/sbin/useradd ${user_login} -p $(perl -e'print crypt("$password", "linknx")') -G $groups,daemon,dialout,root,www-data -d /home/${user_login} -m -s /bin/bash
#
  if [ $? -ne 0 ];
  then
    echo "L'utilisateur ${user_login} existe deja ou probleme a la création"
  else
    echo "--== Utilisateur ${user_login} cree ==--"
  fi
else
  echo "Pas de user a creer"
fi
echo "-------------------------------------------------------------------"
echo "-------------------------------------------------------------------"
echo "----======  LinKnx  ======----"

# "which" donne le path complet de lancement de linknx ex. /usr/local/bin/linknx
LINKNX_PATH=`which linknx`
_install_linknx=yes
if test x$LINKNX_PATH = x; then :
  echo "n'est PAS installe"
  _install_linknx=yes
else
  LINKNX_VERSION=`$LINKNX_PATH --version  | grep linknx | cut -d " " -f 2`
  echo "deja installe version $LINKNX_VERSION "
  # ex LINKNX_VERSION = 0.0.1.32 => 0 * 10000 + 0 * 1000 + 1 * 100 + 32 => 132
  version_courrente=$(( $(( $(echo $LINKNX_VERSION | cut -d "." -f1) *10000 )) + $(( $(echo $LINKNX_VERSION | cut -d "." -f2) *1000 )) + $(( $(echo $LINKNX_VERSION | cut -d "." -f3) *100 )) + $(echo $LINKNX_VERSION | cut -d "." -f4) ))
  if [ "$version_courrente" -ge 133 ]
  then
    echo "Et est a jour "
    _install_linknx=no
  else
    echo "Mais n'est pas a jour"
    _install_linknx=yes
  fi
fi
echo "-------------------------------------------------------------------"



echo "-------------------------------------------------------------------"
echo "----======  Web Serveur  ======----"

APACHE2_PATH=`which apache2`
LIGHTTPD_PATH=`which lighttpd`
NGINX_PATH=`which nginx`
_install_apache2=no
if test x$APACHE2_PATH != x; then :
  echo "APACHE2 is install";
else
  if test x$LIGHTTPD_PATH != x; then :
    echo "LIGHTTPD is install";
  else
    if test x$NGINX_PATH != x; then :
      echo "NGINX is install";
    else
      echo "Not install we install APACHE2";
      _install_apache2=yes
    fi
  fi
fi
echo "-------------------------------------------------------------------"


if [ -d "/var/www/html/" ]; then
  path_knxweb="/var/www/html/$dir_knxweb/";
fi

# chercher un fichier dans un repertoire pour verifier presence de knxweb
#if [ -d "$path_knxweb" ]; then
if [ -f "$path_knxweb/version" ]; then
  KNXWEBSETUP=`find $path_knxweb | grep setup.php`
  KNXWEBversion=`cat "$path_knxweb"version`
fi


echo "-------------------------------------------------------------------"
echo "----======  KnxWeb  ======----"
_install_knxweb=yes
#if [ ! -d "$path_knxweb" ]; then
if [ ! -f "$path_knxweb/version" ]; then
  echo "n'est PAS installe"
  _install_knxweb=yes
else
  KNXWEBversion=${KNXWEBversion}
  echo "deja installe en version $KNXWEBversion";
  # ex KNXWEBversion = 0.9.2 => 0 * 100 + 9 * 10 + 2 => 92
  version_courrente=$(( $(( $(echo $KNXWEBversion | cut -d "." -f1) *100 )) + $(( $(echo $KNXWEBversion | cut -d "." -f2) *10 )) + $(echo $KNXWEBversion | cut -d "." -f3) ))

  if [ "$version_courrente" -ge 211 ]
  then
    echo "Et est a jour "
    _install_knxweb=no
  else
    echo "Mais n'est pas a jour "
    _install_knxweb=yes
  fi
fi
echo "-------------------------------------------------------------------";

# mysql
echo "-------------------------------------------------------------------";
echo "----======  MYSQL  ======----"
MYSQL_PATH=`which mysql`
if test x$MYSQL_PATH != x; then :
  echo "Est deja installe"
  _mysql_with=no
else
  # Check whether --with-mysql was given.
  if test "${with_mysql+set}" = set; then
    echo "Installera MYSQL";
    _mysql_with=yes
  else
    echo "PAS de configuration de MYSQL";
    _mysql_with=no
  fi
fi
echo "-------------------------------------------------------------------";
echo "                                                                   ";
echo "           PAUSE ";
echo " Appuyez sur une touche pour lancer l'installation";
echo " Sinon Ctrl+C pour quitter ";
echo "-------------------------------------------------------------------";
read choix;
datedeb=`date '+%s'`;

update_paquets ()
{
  echo "-------------------------------------------------------------------";
  echo "Updates et Upgrades paquets            ";
  echo "-------------------------------------------------------------------";
  #apt-get update --yes -y -qq
  apt-get update --yes -y -qq && apt-get upgrade --yes -y -qq
}

install_dependances ()
{
  echo "-------------------------------------------------------------------"
  echo "Installation des dependances                    "
  echo "-------------------------------------------------------------------"
  #apt-get install gcc g++ make locales --yes -y -qq

  apt-get update --yes -y -qq && apt-get upgrade --yes -y -qq


  PAQUAGES=${PAQUAGES}" gcc g++ make"
  echo "-------------------------------------------------------------------"
  echo "Liste des paquets installés 1/6 : "
  echo ${PAQUAGES}
  echo "-------------------------------------------------------------------"
  apt-get install ${PAQUAGES} --yes -y -qq
  PAQUAGES=" ";

  PAQUAGES=${PAQUAGES}" liblog4cpp5-dev libesmtp-dev liblua5.1-0-dev libxml2 dpkg"
  echo "-------------------------------------------------------------------"
  echo "Liste des paquets installés 2/6 : "
  echo ${PAQUAGES}
  echo "-------------------------------------------------------------------"
  apt-get install ${PAQUAGES} --yes -y -qq
  PAQUAGES=" ";
  if test $_mysql_with = yes; then
    #PAQUAGES=${PAQUAGES}" mysql-client mysql-common mysql-server mysql-server-core-5.5 libmysqlclient-dev"
    PAQUAGES=${PAQUAGES}" mysql-client mysql-common mysql-server"
    echo "-------------------------------------------------------------------"
    echo "Liste des paquets installés 3/6 : "
    echo ${PAQUAGES}
    echo "-------------------------------------------------------------------"
    apt-get install ${PAQUAGES} --yes -y -qq
    PAQUAGES=" ";
    echo " ---===***===---"
    echo " "
    echo "Quel mot de passe venez vous de taper (mot de passe root de MySql) ?"
    echo " :"
    while true
    do
            read MySQL_root < /dev/tty
            echo "Confirmez vous que le mot de passe est : "${MySQL_root}
            while true
            do
                echo -n "oui/non: "
                read ANSWER < /dev/tty
                case $ANSWER in
    			oui)
    				break
    				;;
    			non)
    				break
    				;;
                esac
                echo "Répondez oui ou non"
            done
            if [ "${ANSWER}" = "oui" ]; then
                break
            fi
    done
  fi
  PAQUAGES=${PAQUAGES}" libcurl4-openssl-dev openssl libssl-dev build-essential file autoconf dh-make debhelper devscripts fakeroot gnupg"
  echo "-------------------------------------------------------------------"
  echo "Liste des paquets installés 4/6 : "
  echo ${PAQUAGES}
  echo "-------------------------------------------------------------------"
  apt-get install ${PAQUAGES} --yes -y -qq
  PAQUAGES=" ";

  echo "-------------------------------------------------------------------"

  if test "$_install_apache2" = yes;
  then
    echo "Installation du serveur apache2 + Php7.0                  "
    PAQUAGES=${PAQUAGES}" apache2 php7.0 libapache2-mod-php7.0 php7.0-common php7.0-cgi php7.0-fpm php7.0-cli php7.0-curl php7.0-gd php7.0-idn php-pear php7.0-imagick php7.0-imap php7.0-mcrypt php7.0-memcache php7.0-mhash php7.0-ming php7.0-ps php7.0-pspell php7.0-recode php7.0-snmp php7.0-tidy php7.0-xmlrpc php7.0-xsl php7.0-json"
    if test $_mysql_with = yes; then
      PAQUAGES=${PAQUAGES}" php7.0-mysql"
    fi
    echo "-------------------------------------------------------------------"
    echo "Liste des paquets installés 5/6 : "
    echo ${PAQUAGES}
    echo "-------------------------------------------------------------------"
    apt-get install ${PAQUAGES} --yes -y -qq
    PAQUAGES=" ";
    chmod 777 -R /var/www
    chown www-data:www-data -R /var/www
  else
    echo " Apache2 deja installé "
    PHP_PATH=`which php`
    if test x$PHP_PATH = x; then :
      PAQUAGES=${PAQUAGES}" php7.0 php7.0-common php7.0-cgi php7.0-cli php7.0-curl php7.0-gd php7.0-idn php-pear php7.0-imagick php7.0-imap php7.0-mcrypt php7.0-memcache php7.0-mhash php7.0-ming php7.0-ps php7.0-pspell php7.0-recode php7.0-snmp php7.0-tidy php7.0-xmlrpc php7.0-xsl php7.0-json"
    else
      echo "-------------------------------------------------------------------"
      echo "  PHP7.0 est installé "
    fi
    if test $_mysql_with = yes; then
      PAQUAGES=${PAQUAGES}" php7.0-mysql"
    fi
    echo "-------------------------------------------------------------------"
    echo "Liste des paquets installés 6/6 : "
    echo ${PAQUAGES}
    echo "-------------------------------------------------------------------"
    apt-get install ${PAQUAGES} --yes -y -qq
    PAQUAGES=" ";
  fi
  echo "-------------------------------------------------------------------"
  echo " Fin de l'install des paquets nécessaires : "
  echo "-------------------------------------------------------------------"
  apt-get install -f -y -qq --yes
  PAQUAGES=" ";
}
install_knxd ()
{
echo "-------------------------------------------------------------------"
echo "----======  knxd  ======----"
KNXD_PATH=`which knxd`
if test x$KNXD_PATH = x; then :
  echo "Installation de knxd                     "

  echo " " > /var/log/knxd.log
  chmod 777 /var/log/knxd.log

  apt-get install git-core build-essential debhelper cdbs autoconf automake libtool libusb-1.0-0-dev libsystemd-dev dh-systemd libev-dev --yes -y -qq
  git clone https://github.com/knxd/knxd.git

  cd knxd
  git checkout stable #v0.12  # utilisation de la version stable v0.12
  dpkg-buildpackage -b -uc
  cd ..
  dpkg -i knxd_*.deb knxd-tools_*.deb

  usermod -a -G dialout knxd

  # … and if you'd like to update knxd:
  #rm knxd*.deb
  #cd knxd
  #git pull
  #dpkg-buildpackage -b -uc
  #cd ..
  #sudo dpkg -i knxd_*.deb knxd-tools_*.deb



# nano /etc/knxd.conf
# KNXD_OPTS=="-u /tmp/eib -u /var/run/knx -i -b ipt:192.168.188.XX"
# KNXD_OPTS=="-u /tmp/eib -u /var/run/knx -i -b ipt:$knxd_ipport"
#
# KNXD_OPTS="-e 1.1.255 -c -D -T -R -S -b ipt:192.168.1.10"
# KNXD_OPTS=" -c -D -T -R -S -b ipt:192.168.1.10"
#
# nano /etc/default/knxd
# START_KNXD=YES

  # KNXD_OPTS="-u /tmp/eib -b ip:"
  # try KNXnet/IP Routing with default Multicast 224.0.23.12
  echo "\t *** Autodetection de l'interface IP/KNX."
  EIBNETTMP=`mktemp`
  eibnetsearch - > $EIBNETTMP
  # Take only first :
  EIBD_NET_MCAST=`grep Multicast $EIBNETTMP | cut -d' ' -f2 | sed -n '1p'`
  # Take only first :
  EIBD_NET_HOST=`grep Answer $EIBNETTMP | cut -d' ' -f3 | sed -n '1p'`
  EIBD_NET_PORT=`grep Answer $EIBNETTMP | cut -d' ' -f6 | sed -n '1p'`
  # Take only first :
  EIBD_NET_NAME=`grep Name $EIBNETTMP | cut -d' ' -f2 | sed -n '1p'`

  EIBD_MY_IP=`ifconfig eth0 | grep 'inet addr' | sed -e 's/:/ /' | awk '{print $3}'`
  rm $EIBNETTMP
  if [ "$EIBD_NET_MCAST" != "" -a "$EIBD_NET_HOST" != "$EIBD_MY_IP" ]; then
    echo "A trouvé une interface KNXnet/IP Router $EIBD_NET_NAME sur $EIBD_NET_HOST avec $EIBD_NET_MCAST"
    echo "KNXD_OPTS=\"-e 0.0.1 -E 0.0.2:8 -u /tmp/eib -c -D -T -R -b ipt:$EIBD_NET_HOST\"" >> /etc/knxd.conf
  #else
    #echo "KNXD_OPTS=\"-e 0.0.1 -E 0.0.2:8 -t1023 -f9 -u /tmp/eib -c -D -T -R -S -b ipt:$knxd_ipport\"" >> /etc/knxd.conf
    #echo "KNXD_OPTS=\"-e 0.0.1 -E 0.0.2:8 -u /tmp/eib -c -D -T -R -b ipt:$knxd_ipport\"" >> /etc/knxd.conf
  fi

  # The 'groupswrite' etc. aliases are no longer installed by default. To workaround,
  # you can either add /usr/lib/knxd to your $PATH, or use knxtool groupswrite.
  #echo "export PATH=\"$PATH:/usr/lib/knxd\"" >> /etc/knxd.conf

else
  KNXD_VERSION=`$KNXD_PATH -V`
  echo "KNXD deja installe : $KNXD_VERSION "
fi
echo "-------------------------------------------------------------------"
}
install_linknx ()
{

echo "-------------------------------------------------------------------"
if test "$_install_linknx" = yes;
then
  wget https://www.auto.tuwien.ac.at/~mkoegler/pth/pthsem_2.0.8.tar.gz
  tar xzf pthsem_2.0.8.tar.gz
  cd pthsem-2.0.8
  dpkg-buildpackage -b -uc
  cd ..
  dpkg -i libpthsem*.deb

  echo "Installation de pthsem terminée "
  echo " "

  echo "Installation de linknx_0.0.1.34                   "
  #wget http://downloads.sourceforge.net/project/linknx/linknx/linknx-0.0.1.32/linknx-0.0.1.32.tar.gz
  wget https://github.com/linknx/linknx/archive/0.0.1.34.tar.gz
  tar -xzf 0.0.1.34.tar.gz
  cd linknx-0.0.1.34

  if test $_mysql_with = yes;
  then
    ./configure --without-pth-test --enable-smtp --with-log4cpp --with-lua --with-mysql=/usr/bin/mysql_config
  else
    ./configure --without-pth-test --enable-smtp --with-log4cpp --with-lua --without-mysql
  fi
  #TODO essayer de gérer les erreurs de configure make ou autre pour alerter ...
  make
  make install
  cd ..

  if [ -d "/var/www/html/" ]; then
    linknx_xml="/var/www/html/knxweb";
    if [ ! -d "/var/www/html/knxweb" ]; then
      mkdir "/var/www/html/knxweb";
    fi
  fi
  if [ ! -d "$linknx_xml" ]
  then
    mkdir -p $linknx_xml
  fi
  if [ ! -f $SCRIPT_PATH/linknx.xml ]
  then
    wget -O $SCRIPT_PATH/linknx.xml http://linknx.cvs.sourceforge.net/viewvc/linknx/linknx/linknx/conf/linknx.xml
  fi
  cp $SCRIPT_PATH/linknx.xml $linknx_xml/linknx.xml
  chmod 777 $linknx_xml/linknx.xml

  if test $service_Systemd = true; then
    # /lib/systemd/system/knxd.service
    echo "[Unit]" > /etc/systemd/system/linknx.service
    echo "Description=Linknx Server" >> /etc/systemd/system/linknx.service
    #echo "Requires=knxd.service" >> /etc/systemd/system/linknx.service
    echo "After=knxd.service" >> /etc/systemd/system/linknx.service
    echo "[Service]" >> /etc/systemd/system/linknx.service
    echo "ExecStart=/usr/local/bin/linknx --daemon=/var/log/linknx.log --config=$linknx_xml/linknx.xml --pid-file=/var/run/linknx.pid -w" >> /etc/systemd/system/linknx.service
    echo "PIDFile=/var/run/linknx.pid" >> /etc/systemd/system/linknx.service
    echo "Type=forking" >> /etc/systemd/system/linknx.service
    echo "Restart=always" >> /etc/systemd/system/linknx.service
    #Restart=on-failure
    #RestartSec=10
    #echo "User=knx" >> /etc/systemd/system/linknx.service
    echo "[Install]" >> /etc/systemd/system/linknx.service
    echo "WantedBy=multi-user.target" >> /etc/systemd/system/linknx.service

    chmod a+x /etc/systemd/system/linknx.service
    echo " " > /var/log/linknx.log
    chmod 777 /var/log/linknx.log

    systemctl --system daemon-reload
    systemctl enable linknx.service
    systemctl daemon-reload
    systemctl start linknx.service

  else
    if [ ! -f $SCRIPT_PATH/linknx.sh ]
    then
      wget -O $SCRIPT_PATH/linknx.sh http://www.knxweb.fr/install_trio/linknx.sh
    fi

    cp $SCRIPT_PATH/linknx.sh /etc/init.d/linknx
    sed -i 's%# Required-Start:    $local_fs $remote_fs $syslog eibd"%# Required-Start:    $local_fs $remote_fs $syslog knxd%g' /etc/init.d/linknx
    sed -i 's%# Required-Start:    $local_fs $remote_fs $syslog eibd mysql"%# Required-Start:    $local_fs $remote_fs $syslog knxd mysql%g' /etc/init.d/linknx
    if [ ! -f /etc/init.d/mysql ] ; then
      sed -i 's%# Required-Start:    $local_fs $remote_fs $syslog knxd mysql"%# Required-Start:    $local_fs $remote_fs $syslog knxd%g' /etc/init.d/linknx
    fi
    chmod 755 /etc/init.d/linknx
    chmod +x /etc/init.d/linknx

    # Fichier Parametrage demarrage automatique Linknx
    # PATH_LINKNX_XML=/var/lib/linknx
    echo "# Configuration demarrage /etc/init.d/linknx " > /etc/default/linknx
    echo "PATH_LINKNX_XML=$linknx_xml" >> /etc/default/linknx
    echo "DAEMON_ARGS=\"--config=$linknx_xml/linknx.xml -p/var/run/linknx.pid -d/var/log/linknx.log -w\""  >> /etc/default/linknx

    update-rc.d linknx defaults
    echo " " > /var/log/linknx.log
    chmod 777 /var/log/linknx.log
    /etc/init.d/linknx start
  fi
else
  echo "---=== LINKNX n'est pas a installer ===---"
fi
echo "-------------------------------------------------------------------"
}
install_knxweb ()
{
echo "-------------------------------------------------------------------"
if test "$_install_knxweb" = yes;
then
  echo "Installation de KnxWeb2                     "
  cd /var/www/
  if [ -d "/var/www/html/" ]; then
    cd html
    path_knxweb="/var/www/html/$dir_knxweb/";
  fi

  # wget http://downloads.sourceforge.net/project/linknx/knxweb/knxweb-dev-v2.1.0.tar.gz

  wget https://github.com/linknx/knxweb/archive/v2.1.1.tar.gz
  tar -xzf v2.1.1.tar.gz --overwrite

  rm v2.1.1.tar.gz
  echo " " > knxweb-2.1.1/dev
  chmod -R 777 knxweb-2.1.1/

  #mv knxweb-2.1.1/ knxweb/
  if [ ! -f $path_knxweb/setup.php ]; then
    cd knxweb-2.1.1/
    dir_knxweb="knxweb-2.1.1";
  else
    mv knxweb-2.1.1/ knxweb/;
    cd knxweb
    dir_knxweb="knxweb";
  fi

  versionknxweb=`cat version`

  echo "  Version de KnxWeb : '$versionknxweb'"

  # TODO faire un lien symbolique vers /tmp/ par exemple suivant le systeme
  # si gere sur carte SD ou Cle USB par exemple pour monter en memoire ce dossier
  cd template
  mkdir template_c
  chown www-data:www-data template_c

  chmod 777 -R /var/www
  chown www-data:www-data -R /var/www
#  chown -R www-data:www-data pictures
#  chown -R www-data:www-data design
#  chown -R www-data:www-data include
#  chown -R www-data:www-data widgets

  #echo " executer VIet ajouter: www-data ALL=(ALL) NOPASSWD: ALL "
  echo "www-data ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

  echo "  Acces via http://$IP_machine/$dir_knxweb/ "
else
  echo "---=== KnxWeb n'est pas a installer ===---"
fi
echo "-------------------------------------------------------------------"
}
install_webmin ()
{
  cd $SCRIPT_PATH/
  echo "-------------------------------------------------------------------"
  echo "Installation de Webmin "
  echo "-------------------------------------------------------------------"
  echo "Liste des paquets installé : "
  echo " perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python "
  echo "-------------------------------------------------------------------"
  apt-get install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python --yes -y -qq
  wget  http://webmin.com/download/deb/webmin-current.deb
  dpkg -i webmin-current.deb

}
bdd_mysql ()
{

# mysql
echo "-------------------------------------------------------------------"
echo "----======  MYSQL  ======----"
MYSQL_PATH=`which mysql`
if test x$MYSQL_PATH != x;
then :
  echo "Est bien installee "

  echo "Faut-il creer la base de donnee mySQL pour LinKnx ? (o/[N]) "
  read ans < /dev/tty
  if [ $ans = o -o $ans = O ]
  then
    BTICK='`'
    base='linknx'
    table='persist'
    logtable='log'

    if test x$MySQL_root = x;
    then
      echo "-------------------------------------------------------------------"
      echo "-                                                                 -"
      echo "-                                                                 -"
      echo "- Entrez le password root mysql :"
      read MySQL_root < /dev/tty
    fi
    # creation de la base     ${MySQL_root}
    /usr/bin/mysqladmin --user=root --password=${MySQL_root} create ${user_login}
    echo "User MySQL \"${user_login}\" cree\n"


    # creation du compte + db + droits
    #/usr/bin/mysql -u root --password=${MySQL_root} mysql <<END_COMMANDS
    /usr/bin/mysql --user=root --password=${MySQL_root} mysql <<END_COMMANDS
CREATE DATABASE IF NOT EXISTS ${BTICK}$base${BTICK};
GRANT ALL ON ${BTICK}$base${BTICK}.* TO '${user_login}'@'localhost' IDENTIFIED BY '$password';
FLUSH PRIVILEGES;
USE ${BTICK}$base${BTICK};
CREATE TABLE IF NOT EXISTS ${BTICK}$logtable${BTICK} (
  ${BTICK}ts${BTICK} timestamp NOT NULL default CURRENT_TIMESTAMP,
  ${BTICK}object${BTICK} varchar(256) NOT NULL,
  ${BTICK}value${BTICK} varchar(256) NOT NULL,
  KEY ${BTICK}object${BTICK} (${BTICK}object${BTICK}),
  INDEX ${BTICK}object_ts${BTICK} (${BTICK}object${BTICK},${BTICK}ts${BTICK})
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS ${BTICK}$table${BTICK} (
  ${BTICK}object${BTICK} varchar(256) NOT NULL,
  ${BTICK}value${BTICK} varchar(256) NOT NULL,
  ${BTICK}ts${BTICK} timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (${BTICK}object${BTICK})
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
END_COMMANDS
# credit Petitpunch : Ajout index sur la table de log  pour améliorer la performance de lecture surtout de certains widgets dans knxweb


    echo "Base MySQL \"$base\" creee ainsi que les tables \"$table\" et \"$logtable\"\n"
    echo "Redemarrage de MySQL \n"

    # redemarrage de la base
    /usr/bin/mysqladmin --user=root --password=${MySQL_root} reload

  else
    echo " ---= Pas de creation de Base Mysql =---"
  fi

fi
echo "-------------------------------------------------------------------"
}


case $choix in
  0 )
    exit
    ;;
  1 )
    update_paquets
    install_dependances
    ;;
  2 )
    install_knxd
    install_linknx
    install_knxweb
    if test "${with_webmin+set}" = set;
    then
      install_webmin
    fi
    bdd_mysql
    ;;
  3 )
    install_knxd
    install_linknx
    install_knxweb
    ;;
  *)
    #update_paquets
    install_dependances
    install_knxd
    install_linknx
    install_knxweb
    if test "${with_webmin+set}" = set;
    then
      install_webmin
    fi
    bdd_mysql
    ;;
esac

datefin=`date '+%s'`;
tpstrt=$(( $datefin - $datedeb));
tpstrtMin=$(($tpstrt /60));

echo "\n-------------------------------------------------------------------"
echo "     -----==          Installation terminee         ==-----"
echo "     -----==  temps d'installation : $tpstrt s      ==-----"
echo "     -----==      soit ~ $tpstrtMin minutes         ==-----"
echo "     -----==                ;-)                     ==-----"
echo " "
echo "             -----==  Acceder a KnxWeb par  ==-----"
echo "     -----==  http://$ac_hostname/$dir_knxweb/setup.php  ==-----"
echo "                      -----==  OU  ==-----"
echo "     -----==  http://$IP_machine/$dir_knxweb/setup.php   ==-----"
echo "-------------------------------------------------------------------"
exit 0