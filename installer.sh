#!/usr/bin/env bash

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (see the file COPYING); if not, write to the
# Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

##################################################################
VERSION='1.0.0~git'                                              #
DATE='Feb 05 2011'                                               #
##################################################################
trap ctrl_c SIGINT
source includes/functions.sh || error "while loading functions.sh"  # Source in our functions

##[ Check command line switches ]##
while [ "$#" -gt 0 ]; do
  	case "$1" in
		-p|--pass) if [[ "$2" ]]
			then passwdlength="$2" && mkpass; shift
			else error "Specify Length --pass x "; fi ;;
		--save-tmp) DONT_RM_TMP=1; shift ;; 
		-t|--threads) if [[ "$2" ]]
			then declare -i OVERWRITE_THREAD_COUNT="$2"; shift 
			else error "Specify num of threads --threads x "; fi ;;
		-v|--version) echo -e "\n v$VERSION  $DATE \n"; exit ;;
		-h|--help) usage ;;
	esac
	shift
done
runchecks
init

#!=======================>> DiSCLAiMER <<=======================!#
if [[ ! -f "$LOG" ]]; then  # only show for first run
echo -e "${bldgrn}
                      ______
                   .-\"      \"-.
                  /      ${bldpur}®${bldgrn}     \\
                 |              |
                 |,  .-.  .-.  ,|
                 | )(__/  \__)( |
                 |/     /\     \|
${bldylw}       (@_${bldgrn}       (_     ^^     _)
${bldylw}  _     )_\\ ${bldgrn}______\__|IIIIII|__/__________________________
${bldylw} (_)@8@8{}<${bldgrn}________|-\\IIIIII/-|___________________________>
${bldylw}        )_/${bldgrn}        \          /
${bldylw}       (@${bldgrn}           '--------'

  WARNING:

  The installation is quite stable and functional when run on a freshly
  installed supported Operating System. Systems that have already had
  these programs installed and/or removed could run into problems, but
  not likely. If you do run into problems, please let us know so we can
  fix it.

      Supported:                InProgress:
        Ubuntu                    OpenSUSE
        Debian                    ArchLinux

  If your OS is not listed, this script will most likey explode.${rst}"
echo -e " ${undred}___________________________________________${rst}"
echo -e "  Distro:${bldylw} $DISTRO $RELEASE ${rst}"
echo -e "  Kernel:${bldylw} $KERNEL${rst}-${bldylw}$ARCH ${rst}"

echo -en "\n Continue? [y/n]: "
	if ! yes ;then
		cleanup ; clear ; exit  # Cleanup and die if no
	fi
	mksslcert 'generate-default-snakeoil'
fi  # end `if ! $LOG`
log "\n*** SCRiPT STARTiNG | $(date) ***"

if [[ ! -f $BASE/.repos.installed ]]; then  # Add repositories if not already present
	source $BASE/includes/repositories.sh || error "while loading repositories.sh"
else log "Repositories Already Present, skipping"
fi

clear
source $BASE/includes/questionnaire.sh || error "while loading questionnaire.sh"  # Load questionnaire

#!=====================>> iNSTALLATiON <<=======================!#
echo -e "\n********************************"
echo -e   "****${bldred} BEGiNiNG iNSTALLATiON ${rst}*****"
echo -e   "********************************\n"

base_configure
base_install

cd "$BASE"
##[ APACHE ]##
if [[ $http = 'apache' ]]; then
	notice "iNSTALLiNG APACHE"
	if [[ "$DISTRO" = @([Uu]buntu|[dD]ebian|*Mint) ]]; then
		packages install apache2 apache2-mpm-prefork libapache2-mod-python apachetop &&
		packages install $PHP_DEBIAN php5 libapache2-mod-php5 libapache2-mod-suphp suphp-common
	elif [[ "$DISTRO" = @(SUSE|[Ss]use)* ]]; then
		packages install apache2 apache2-prefork &&
		packages install $PHP_SUSE php5 suphp apache2-mod_php5
	elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		packages install apache php-apache &&
		packages install $PHP_ARCHLINUX
		echo "/etc/rc.d/httpd start" >> /etc/rc.local
	fi
	if_error "Apache2 failed to install"

	if [[ "$DISTRO" = @([Uu]buntu|[dD]ebian|*Mint) ]]; then
		a2enmod auth_digest ssl php5 expires deflate mem_cache  # Enable modules
		a2ensite default-ssl
		#cp modules/apache/scgi.conf /etc/apache2/mods-available/scgi.conf  # Add mountpoint (disabled in favor of rpc plugin)
		sed -i "/<Directory \/var\/www\/>/,/<\/Directory>/ s:AllowOverride .*:AllowOverride All:" /etc/apache2/sites-available/default*
		sed -i "s:ServerSignature On:ServerSignature Off:" /etc/apache2/apache2.conf
		sed -i "s:Timeout 300:Timeout 30:"                 /etc/apache2/apache2.conf
		sed -i "s:KeepAliveTimeout 15:KeepAliveTimeout 5:" /etc/apache2/apache2.conf
		sed -i "s:ServerTokens Full:ServerTokens Prod:"    /etc/apache2/apache2.conf
		echo   "ServerName $HOSTNAME" >>                   /etc/apache2/apache2.conf
		PHPini=/etc/php5/apache/php.ini
	elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		#echo "SCGIMount /rutorrent/master 127.0.0.1:5000" >> /etc/httpd/conf/httpd.conf  # Add mountpoint
		echo "LoadModule php5_module modules/libphp5.so"  >> /etc/httpd/conf/httpd.conf
		echo "Include conf/extra/php5_module.conf"        >> /etc/httpd/conf/httpd.conf
		sed -i "s:Include conf/extra/httpd-userdir.conf:#Include conf/extra/httpd-userdir.conf:" /etc/httpd/conf/httpd.conf  # Disable User-Dir
		sed -i "s:#Include conf/extra/httpd-ssl.conf:Include conf/extra/httpd-ssl.conf:"         /etc/httpd/conf/httpd.conf  # Enable SSL
		sed -i "s:Timeout 300:Timeout 30:"                 /etc/httpd/conf/extra/httpd-default.conf
		sed -i "s:ServerTokens .*:ServerTokens Prod:"      /etc/httpd/conf/extra/httpd-default.conf
		sed -i "s:ServerSignature On:ServerSignature Off:" /etc/httpd/conf/extra/httpd-default.conf
		touch $WEB/index.html
		PHPini=/etc/php/php.ini
		sed -i "s:;extension=curl.so:extension=curl.so:"                $PHPini
		sed -i "s:;extension=json.so:extension=json.so:"                $PHPini
		sed -i "s:;extension=sockets.so:extension=sockets.so:"          $PHPini
		sed -i "s:;extension=xmlrpc.so:extension=xmlrpc.so:"            $PHPini
		sed -i "s:;date.timezone .*:date.timezone = Europe/Luxembourg:" $PHPini
		sed -i "s|[;]*open_basedir = .*|open_basedir = /srv/http/:/home/:/tmp/:/usr/share/pear/:/usr/bin/:/usr/local/bin/|" $PHPini
		if [[ ! -f /etc/httpd/conf/server.key ]]; then
			mksslcert "/etc/httpd/conf/server.crt" "/etc/httpd/conf/server.key"
			log "Lighttpd SSL Key created"
		fi
	elif [[ "$DISTRO" = @(SUSE|[Ss]use)* ]]; then
		a2enmod auth_digest ssl php5 expires deflate mem_cache
		a2enflag SSL
		sed -i "/<Directory \"\/srv\/www\/htdocs\">/,/<\/Directory>/ s:AllowOverride .*:AllowOverride All:" /etc/apache2/default-server.conf
		sed -i "s:APACHE_SERVERSIGNATURE=\"on\":APACHE_SERVERSIGNATURE=\"off\":" /etc/sysconfig/apache2
		sed -i "s:APACHE_SERVERTOKENS=.*:APACHE_SERVERTOKENS=\"ProductOnly\":"   /etc/sysconfig/apache2
		sed -i "s:KeepAliveTimeout 15:KeepAliveTimeout 5:"                       /etc/apache2/server-tuning.conf
		PHPini=/etc/php5/apache/php.ini
	fi
	log "Apache Installation | Completed" ; debug_wait "apache.installed"

##[ LiGHTTPd ]##
elif [[ $http = 'lighttp' ]]; then
	notice "iNSTALLiNG LiGHTTP"
	if [[ "$DISTRO" = @([Uu]buntu|[dD]ebian|*Mint) ]]; then
		packages install lighttpd php5-cgi &&
		packages install $PHP_DEBIAN
	elif [[ "$DISTRO" = @(SUSE|[Ss]use)* ]]; then
		packages install $PHP_SUSE lighttpd
	elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		packages install $PHP_ARCHLINUX lighttpd fcgi php-cgi
		echo "/etc/rc.d/lighttpd start" >> /etc/rc.local
	fi
	if_error "Lighttpd failed to install"  # I wonder when the fam and gamin api will be compatible (this generates an error coce 100 so we are forced to ignore it)

	if [[ ! -f /etc/lighttpd/server.pem ]]; then  # Create an SSL cert if one isnt found
		mksslcert "/etc/lighttpd/server.pem"
		log "Lighttpd SSL Key created"
	fi

	#cp modules/lighttp/scgi.conf /etc/lighttpd/conf-available/20-scgi.conf       # Add mountpoint and secure it with auth (disabled in favor of rpc plugin)
	cat < modules/lighttp/auth.conf >> /etc/lighttpd/conf-available/05-auth.conf  # Apend contents of our auth.conf into lighttp's auth.conf
	sed -i "s:url.access-deny .*:url.access-deny = (\"~\", \".inc\", \".htaccess\") :" /etc/lighttpd/lighttpd.conf  # Deny listing of .htaccess files
	lighty-enable-mod fastcgi fastcgi-php auth access accesslog compress ssl      # Enable modules	

	PHPini=/etc/php5/cgi/php.ini
	#PHPini=/etc/php5/fastcgi/php.ini  # opensuse
	log "Lighttp Installation | Completed" ; debug_wait "lighttpd.installed"

##[ Cherokee ]##
elif [[ $http = 'cherokee' ]]; then
	notice "iNSTALLiNG CHEROKEE"
	#if [[ $NAME = 'lenny' ]]; then
	#	packages install cherokee spawn-fcgi
	#fi
	if [[ "$DISTRO" = @([Uu]buntu|[dD]ebian|*Mint) ]]; then
		packages install cherokee libcherokee-mod-libssl libcherokee-mod-rrd libcherokee-mod-admin spawn-fcgi &&
		packages install $PHP_DEBIAN
	elif [[ "$DISTRO" = @(SUSE|[Ss]use)* ]]; then
		packages install cherokee &&
		packages install $PHP_SUSE
	elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		packages install cherokee &&
		packages install $PHP_ARCHLINUX php-cgi
		echo "/etc/rc.d/cherokee start" >> /etc/rc.local
	fi
	if_error "Cherokee failed to install"

	PHPini=/etc/php5/cgi/php.ini
	log "Cherokee Installation | Completed" ; debug_wait "cherokee.installed"

##[ PHP ]##
elif [[ $http != @(none|no|[Nn]) ]]; then  # Edit php config
	sed -i 's:memory_limit .*:memory_limit = 128M:'                                    $PHPini
	sed -i 's:error_reporting .*:error_reporting = E_ALL & ~E_DEPRECATED & ~E_NOTICE:' $PHPini
	sed -i 's:expose_php = On:expose_php = Off:'                                       $PHPini
	sed -i 's:display_errors = On:display_errors = Off:'                               $PHPini
	sed -i 's:log_errors = Off:log_errors = On:'                                       $PHPini
	sed -i 's:;error_log .*:error_log = /var/log/php-error.log:'                       $PHPini
	touch $WEB/favicon.ico
	[[ $create_phpinfo = 'y' ]] && echo "<?php phpinfo(); ?>" > $WEB/info.php  # Create phpinfo file
fi

##[ vsFTP ]##
if [[ $ftpd = 'vsftp' ]]; then
	notice "iNSTALLiNG vsFTPd"
	packages install vsftpd
	[[ $DISTRO = @(ARCH|[Aa]rch)* ]] && echo "/etc/rc.d/vsftpd start" >> /etc/rc.local
	if_error "vsFTPd failed to install"
	sed -i 's:anonymous_enable.*:anonymous_enable=NO:'           /etc/vsftpd.conf
	sed -i 's:#local_enable.*:local_enable=YES:'                 /etc/vsftpd.conf
	sed -i 's:#write_enable.*:write_enable=YES:'                 /etc/vsftpd.conf
	sed -i 's:#local_umask.*:local_umask=022:'                   /etc/vsftpd.conf
	sed -i 's:#idle_session_timeout.*:idle_session_timeout=600:' /etc/vsftpd.conf
	sed -i 's:#nopriv_user.*:nopriv_user=ftp:'                   /etc/vsftpd.conf
	sed -i 's:#chroot_local_user.*:chroot_local_user=YES:'       /etc/vsftpd.conf
	
	if [[ ! -f /etc/ssl/private/vsftpd.pem ]]; then
		mksslcert "/etc/ssl/private/vsftpd.pem"
		if [[ ! $(grep 'rsa_cert_file' /etc/vsftpd.conf) ]]
			then echo "rsa_cert_file=/etc/ssl/private/vsftpd.pem"                   >> /etc/vsftpd.conf
			else sed -i ":rsa_cert_file=.*:rsa_cert_file=/etc/ssl/private/vsftpd.pem:" /etc/vsftpd.conf
		fi
	fi

	if [[ ! $(grep '# added by autoscript' /etc/vsftpd.conf) ]]; then  # Check if this has already been done
		echo "# added by autoscript"     >> /etc/vsftpd.conf
		echo "force_local_logins_ssl=NO" >> /etc/vsftpd.conf
		echo "force_local_data_ssl=NO"   >> /etc/vsftpd.conf
		echo "ssl_enable=YES" >> /etc/vsftpd.conf
		echo "ssl_tlsv1=YES"  >> /etc/vsftpd.conf
		echo "ssl_sslv2=NO"   >> /etc/vsftpd.conf
		echo "ssl_sslv3=YES"  >> /etc/vsftpd.conf
	else log "vsftpd config already edited, skipping"
	fi

	echo -en "\n Force SSL? [y/n]: "
	if yes; then  # allow toggling of forcing ssl
		sed -i 's:force_local_logins_ssl.*:force_local_logins_ssl=YES:' /etc/vsftpd.conf
		sed -i 's:force_local_data_ssl.*:force_local_data_ssl=YES:'     /etc/vsftpd.conf
	else
		sed -i 's:force_local_logins_ssl.*:force_local_logins_ssl=NO:'  /etc/vsftpd.conf
		sed -i 's:force_local_data_ssl.*:force_local_data_ssl=NO:'      /etc/vsftpd.conf
	fi

	echo -en "\n Allow FXP? [y/n]: "
	if yes; then  # enable pasv_promiscuous
		sed -i 's:[#]*pasv_enable.*:pasv_enable=YES:'           /etc/vsftpd.conf
		sed -i 's:[#]*pasv_promiscuous.*:pasv_promiscuous=YES:' /etc/vsftpd.conf
	fi
	log "vsFTP Installation | Completed" ; debug_wait "vsftpd.installed"

##[ proFTP ]##
elif [[ $ftpd = 'proftp' ]]; then
	notice "iNSTALLiNG proFTPd"
	if [[ "$DISTRO" = @([Uu]buntu|[dD]ebian|*Mint) ]]; then
		packages install proftpd-basic
	elif [[ "$DISTRO" = @(SUSE|[Ss]use)* ]]; then
		packages install proftpd
	elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		packages install proftpd
		echo "/etc/rc.d/proftpd start" >> /etc/rc.local
	fi
	if_error "ProFTPd failed to install"

	if [[ ! -f /etc/proftpd/ssl/proftpd.cert.pem ]]; then  # Create SSL cert and conf
		mkdir -p /etc/proftpd/ssl
		mksslcert "/etc/proftpd/ssl/proftpd.cert" "/etc/proftpd/ssl/proftpd.key" &&
		log "PureFTP SSL Key created"
		cat >> /etc/proftpd/proftpd.conf << "EOF"
<IfModule mod_tls.c>
TLSEngine                  on
TLSLog                     /var/log/proftpd/tls.log
TLSProtocol                SSLv23
TLSOptions                 NoCertRequest
TLSRSACertificateFile      /etc/proftpd/ssl/proftpd.cert
TLSRSACertificateKeyFile   /etc/proftpd/ssl/proftpd.key
TLSVerifyClient            off
TLSRequired                off
</IfModule>
EOF
	fi
	sed -i 's:#DefaultRoot .*:DefaultRoot ~:'      /etc/proftpd/proftpd.conf
	sed -i 's:UseIPv6 .*:UseIPv6 off:'             /etc/proftpd/proftpd.conf
	sed -i 's:IdentLookups .*:IdentLookups off:'   /etc/proftpd/proftpd.conf
	sed -i 's:ServerIdent .*:ServerIdent on "FTP Server ready.":' /etc/proftpd/proftpd.conf

	echo -en "\n Force SSL? [y/n]: "
	if yes  # allow toggling of forcing ssl
		then sed -i 's:TLSRequired .*:TLSRequired on:'  /etc/proftpd/proftpd.conf
		else sed -i 's:TLSRequired .*:TLSRequired off:' /etc/proftpd/proftpd.conf
	fi
	log "ProFTP Installation | Completed" ; debug_wait "proftpd.installed"

##[ pureFTP ]##
elif [[ $ftpd = 'pureftp' ]]; then
	notice "iNSTALLiNG Pure-FTPd"
	packages install pure-ftpd
	[[ $DISTRO = @(ARCH|[Aa]rch)* ]] && echo "/etc/rc.d/pure-ftpd start" >> /etc/rc.local
	if_error "PureFTP failed to install"
	
	if [[ ! -f /etc/ssl/private/pure-ftpd.pem ]]; then  # Create SSL Certificate
		mkdir -p /etc/ssl/private
		mksslcert "/etc/ssl/private/pure-ftpd.pem" &&
		log "PureFTP SSL Key created"
	fi
	[[ -f /etc/default/pure-ftpd-common ]] && sed -i 's:STANDALONE_OR_INETD=.*:STANDALONE_OR_INETD=standalone:' /etc/default/pure-ftpd-common

	echo -en "\n Force SSL? [y/n]: "
	if yes  # allow toggling of forcing ssl
		then echo 2 > /etc/pure-ftpd/conf/TLS  # Force TLS
		else echo 1 > /etc/pure-ftpd/conf/TLS  # Allow TLS+FTP
	fi
	log "PureFTP Installation | Completed" ; debug_wait "pureftp.installed"
fi

cd ${BASE}/tmp
if [[ $buildtorrent = 'b' ]]; then
#-->##[ BuildTorrent ]##
	notice "iNSTALLiNG BuildTorrent"
	if [[ ! -d buildtorrent ]]; then  # Checkout latest BuildTorrent source
		git clone -q git://gitorious.org/buildtorrent/buildtorrent.git ; E_=$?
		if_error "BuildTorrent Download Failed" ; log "BuildTorrent | Downloaded"
	fi

	cd buildtorrent
	aclocal
	autoconf
	autoheader
	automake -a -c
	sh configure
	make install

	E=$? ; if_error "BuildTorrent Build Failed"
	log "BuildTorrent Installation | Completed" ; debug_wait "buildtorrent.installed"

elif [[ $buildtorrent != 'n' ]]; then
#-->##[ mkTorrent ]##
if [[ ! -f /usr/local/bin/mktorrent || $buildtorrent = 'm' ]]; then
	notice "iNSTALLiNG MkTorrent"
	if [[ ! -d mktorrent ]]; then  # Checkout latest mktorrent source
		git clone -q git://github.com/esmil/mktorrent.git
		E_=$? ; if_error "MkTorrent Download Failed"
		log "MkTorrent | Downloaded"
	fi
	cd mktorrent
	make install

	E_=$? ; if_error "MkTorrent Build Failed"
	log "MkTorrent Installation | Completed" ; debug_wait "mktorrent.installed"
fi
fi  # end `if $buildtorrent`

cd "$BASE"
##[ Torrent Clients ]##
if   [[ $torrent = 'rtorrent' ]]; then source modules/rtorrent/install.sh
elif [[ $torrent = 'tranny'   ]]; then source modules/transmission/install.sh
elif [[ $torrent = 'deluge'   ]]; then source modules/deluge/install.sh
fi

##[ ruTorrent ]##
[[ $webui = 'y' ]] && source modules/rutorrent/install.sh

##[ Extras ]##
[[ $extras = 'y' ]] && source modules/extras.sh

##[ PostProcess ]##
source $BASE/includes/postprocess.sh || error "while loading postprocess.sh"
echo -e "\n*******************************"
echo -e   "******${bldred} SCRiPT COMPLETED! ${rst}******"
echo -e   "****${bldred} FiNiSHED iN ${bldylw}$SECONDS ${bldred}SECONDS ${rst}*"
echo -e   "*******************************\n"
log "*** SCRiPT COMPLETED | $(date) ***\n<---------------------------------> \n"
exit
