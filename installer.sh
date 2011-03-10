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
VERSION='1.1.0~git'                                              #
DATE='Mar 10 2011'                                               #
##################################################################
trap ctrl_c SIGINT
if [ `bash --version | head -n1 | cut -c 19` -gt '3' ]  # Check for bash verion 4+
	then source includes/functions.sh || echo " Error: while loading functions.sh"  # Source in our functions
	else echo "Please install package: bash, version 4.0 or higher" && exit
fi

##[ Check command line switches ]##
while [ "$#" -gt 0 ]; do
  	case "$1" in
		-p|--pass) if [[ "$2" ]]
			then passwdlength="$2" && mkpass; shift
			else error "Specify Length --pass x "; fi ;;
		--rtorrent-prealloc) alloc='y'; shift ;;
		--rutorrent-workaround) rutorrent_workaround='y'; shift ;;
		--save-tmp) RM_TMP='n'; shift ;; 
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
        Ubuntu 9 +                OpenSUSE 11.3 +
        Debian 5 +                   
        ArchLinux

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
		packages install apache2 apache2-mpm-prefork apachetop &&
		packages install $PHP_DEBIAN php5 libapache2-mod-php5 libapache2-mod-suphp suphp-common
		PHPini=/etc/php5/apache2/php.ini
	elif [[ "$DISTRO" = @(SUSE|[Ss]use)* ]]; then
		packages install apache2 apache2-prefork &&
		packages install $PHP_SUSE php5 suphp apache2-mod_php5
		PHPini=/etc/php5/apache2/php.ini
	elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		packages install apache php-apache &&
		packages install $PHP_ARCHLINUX
		echo "/etc/rc.d/httpd start" >> /etc/rc.local
		PHPini=/etc/php/php.ini
	fi
	if_error "Apache2 failed to install"

	if [[ "$DISTRO" = @([Uu]buntu|[dD]ebian|*Mint) ]]; then
		a2enmod auth_digest ssl php5 expires deflate mem_cache  # Enable modules
		a2ensite default-ssl
		sed -i "/<Directory \/var\/www\/>/,/<\/Directory>/ s:AllowOverride .*:AllowOverride All:" /etc/apache2/sites-available/default*
		sed -i "s:ServerSignature On:ServerSignature Off:" /etc/apache2/apache2.conf
		sed -i "s:Timeout 300:Timeout 30:"                 /etc/apache2/apache2.conf
		sed -i "s:KeepAliveTimeout 15:KeepAliveTimeout 5:" /etc/apache2/apache2.conf
		sed -i "s:ServerTokens Full:ServerTokens Prod:"    /etc/apache2/apache2.conf
		echo   "ServerName $HOSTNAME" >>                   /etc/apache2/apache2.conf
	elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		if [[ ! $(grep 'LoadModule php5_module' /etc/httpd/conf/httpd.conf) ]]; then
		 echo "LoadModule php5_module modules/libphp5.so"                 >> /etc/httpd/conf/httpd.conf
		 echo "Include conf/extra/php5_module.conf"                       >> /etc/httpd/conf/httpd.conf
		fi
		sed -i "s:Include conf/extra/httpd-userdir.conf:#Include conf/extra/httpd-userdir.conf:"       /etc/httpd/conf/httpd.conf  # Disable User-Dir
		sed -i "s:#Include conf/extra/httpd-ssl.conf:Include conf/extra/httpd-ssl.conf:"               /etc/httpd/conf/httpd.conf  # Enable SSL
		sed -i "/<Directory \"\/srv\/http\">/,/<\/Directory>/ s:AllowOverride None:AllowOverride All:" /etc/httpd/conf/httpd.conf  # Allow parsing .htaccess files
		sed -i "s:Timeout 300:Timeout 30:"                 /etc/httpd/conf/extra/httpd-default.conf
		sed -i "s:ServerTokens .*:ServerTokens Prod:"      /etc/httpd/conf/extra/httpd-default.conf
		sed -i "s:ServerSignature On:ServerSignature Off:" /etc/httpd/conf/extra/httpd-default.conf
		sed -i "s:;extension=.*:extension=suhosin.so:"     /etc/php/conf.d/suhosin.ini
		sed -i "s:;extension=.*:extension=geoip.so:"       /etc/php/conf.d/geoip.ini
		touch $WEB/index.html
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
	fi
	log "Apache Installation | Completed" ; debug_wait "apache.installed"

##[ LiGHTTPd ]##
elif [[ $http = 'lighttp' ]]; then
	notice "iNSTALLiNG LiGHTTP"
	if [[ "$DISTRO" = @([Uu]buntu|[dD]ebian|*Mint) ]]; then
		packages install lighttpd php5-cgi &&
		packages install $PHP_DEBIAN
		cat < modules/lighttp/auth.conf >> /etc/lighttpd/conf-available/05-auth.conf  # Apend contents of our auth.conf into lighttp's auth.conf
		sed -i "s:url.access-deny .*:url.access-deny = (\"~\", \".inc\", \".htaccess\") :" /etc/lighttpd/lighttpd.conf  # Deny listing of .htaccess files
		lighty-enable-mod fastcgi fastcgi-php auth access accesslog compress ssl      # Enable modules
		PHPini=/etc/php5/cgi/php.ini
	elif [[ "$DISTRO" = @(SUSE|[Ss]use)* ]]; then
		packages install $PHP_SUSE lighttpd
		PHPini=/etc/php5/fastcgi/php.ini
	elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		packages install apache-tools lighttpd &&
		packages install $PHP_ARCHLINUX fcgi php-cgi 
		cp modules/lighttp/lighttpd.conf.arch /etc/lighttpd/lighttpd.conf
		echo "/etc/rc.d/lighttpd start" >> /etc/rc.local
		PHPini=/etc/php/php.ini
	fi
	if_error "Lighttpd failed to install"  # I wonder when the fam and gamin api will be compatible (this generates an error coce 100 so we are forced to ignore it)

	if [[ ! -f /etc/lighttpd/server.pem ]]; then  # Create an SSL cert if one isnt found
		mksslcert "/etc/lighttpd/server.pem"
		log "Lighttpd SSL Key created"
	fi
	log "Lighttp Installation | Completed" ; debug_wait "lighttpd.installed"
	
##[ NGiNX ]##
elif [[ $http = 'nginx' ]]; then  # TODO
	notice "iNSTALLiNG NGiNX"
	if [[ "$DISTRO" = @([Uu]buntu|[dD]ebian|*Mint) ]]; then
		packages install nginx nginx-common nginx-full php5-fpm &&
		packages install $PHP_COMMON php5-cli
		cp modules/nginx/nginx.conf.ubuntu /etc/nginx/nginx.conf
		cp modules/nginx/default.ubuntu /etc/nginx/sites-available/default
		sed -i "s:worker_processes .*:worker_processes  $(($CORES+2));:"         /etc/nginx/nginx.conf
		sed -i "s:listen.allowed_clients .*:listen.allowed_clients = 127.0.0.1:" /etc/php5/fpm/php5-fpm.conf
		if [[ ! -f /etc/nginx/cert.pem ]]; then
			mksslcert "/etc/nginx/cert.pem" "/etc/nginx/cert.key"
			log "Nginx SSL Key created"
		fi
		/etc/init.d/nginx restart && /etc/init.d/php5-fpm start
		PHPini=/etc/php5/fpm/php.ini
	elif [[ "$DISTRO" = @(SUSE|[Ss]use)* ]]; then
		echo "TODO"
		#packages install nginx-0.8 &&
		#packages install $PHP_SUSE
	elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		packages install  apache-tools nginx &&
		packages install $PHP_ARCHLINUX php-fpm
		cp modules/nginx/nginx.conf.arch /etc/nginx/conf/nginx.conf
		sed -i "s:worker_processes .*:worker_processes  $(($CORES+2));:"         /etc/nginx/conf/nginx.conf
		sed -i "s:listen.allowed_clients .*:listen.allowed_clients = 127.0.0.1:" /etc/php/php-fpm.conf
		if [[ ! -f /etc/nginx/conf/cert.pem ]]; then
			mksslcert "/etc/nginx/conf/cert.pem" "/etc/nginx/conf/cert.key"
			log "Nginx SSL Key created"
		fi
		/etc/rc.d/nginx start && /etc/rc.d/php-fpm start
		echo -e "/etc/rc.d/nginx start\n/etc/rc.d/php-fpm start" >> /etc/rc.local
		PHPini=/etc/php/php.ini
	fi
	if_error "Nginx failed to install"
	log "Nginx Installation | Completed" ; debug_wait "nginx.installed"

##[ Cherokee ]##
elif [[ $http = 'cherokee' ]]; then
	notice "iNSTALLiNG CHEROKEE"
	if [[ "$DISTRO" = @([Uu]buntu|[dD]ebian|*Mint) ]]; then
		packages install cherokee libcherokee-mod-libssl libcherokee-mod-rrd libcherokee-mod-admin spawn-fcgi &&
		packages install $PHP_DEBIAN
		PHPini=/etc/php5/cgi/php.ini
	elif [[ "$DISTRO" = @(SUSE|[Ss]use)* ]]; then
		packages install cherokee &&
		packages install $PHP_SUSE
		PHPini=/etc/php5/fastcgi/php.ini
	elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		packages install apache-tools cherokee apache-tools &&
		packages install $PHP_ARCHLINUX php-cgi
		echo "/etc/rc.d/cherokee start" >> /etc/rc.local
		PHPini=/etc/php/php.ini
	fi
	if_error "Cherokee failed to install"
	log "Cherokee Installation | Completed" ; debug_wait "cherokee.installed"
fi

##[ PHP ]##
if [[ $http != @(none|no|[Nn]) ]]; then  # Edit php config
	sed -i 's:memory_limit .*:memory_limit = 128M:'                                        $PHPini
	sed -i 's:error_reporting = .*:error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_NOTICE:' $PHPini
	sed -i 's:expose_php = On:expose_php = Off:'                                           $PHPini
	sed -i 's:display_errors = On:display_errors = Off:'                                   $PHPini
	sed -i 's:log_errors = Off:log_errors = On:'                                           $PHPini
	sed -i 's:;error_log .*:error_log = /var/log/php-error.log:'                           $PHPini
	sed -i "s:;extension=curl.so:extension=curl.so:"                                       $PHPini
	sed -i "s:;extension=json.so:extension=json.so:"                                       $PHPini
	sed -i "s:;extension=sockets.so:extension=sockets.so:"                                 $PHPini
	sed -i "s:;extension=xmlrpc.so:extension=xmlrpc.so:"                                   $PHPini
	sed -i "s:;date.timezone .*:date.timezone = Europe/Luxembourg:"                        $PHPini
	sed -i "s|[;]*open_basedir = /srv.*|open_basedir = /srv/http/:/home/:/tmp/:/usr/share/pear/:/bin:/usr/bin/:/usr/local/bin/|" $PHPini
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
	proftpd_conf=/etc/proftpd/proftpd.conf
	if [[ "$DISTRO" = @([Uu]buntu|[dD]ebian|*Mint) ]]; then
		packages install proftpd-basic
	elif [[ "$DISTRO" = @(SUSE|[Ss]use)* ]]; then
		packages install proftpd
	elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		packages install proftpd
		echo "/etc/rc.d/proftpd start" >> /etc/rc.local
		proftpd_conf=/etc/proftpd.conf
	fi
	if_error "ProFTPd failed to install"

	if [[ ! -f /etc/ssl/private/proftpd.cert || ! -f /etc/ssl/private/proftpd.key ]]; then  # Create SSL cert and conf
		mksslcert "/etc/ssl/private/proftpd.cert" "/etc/ssl/private/proftpd.key" &&
		log "PureFTP SSL Key created"
		cat >> $proftpd_conf << "EOF"
<IfModule mod_tls.c>
TLSEngine                  on
TLSLog                     /var/log/proftpd/tls.log
TLSProtocol                SSLv23
TLSOptions                 NoCertRequest
TLSRSACertificateFile      /etc/ssl/private/proftpd.cert
TLSRSACertificateKeyFile   /etc/ssl/private/proftpd.key
TLSVerifyClient            off
TLSRequired                off
</IfModule>
EOF
	fi
	sed -i 's:#DefaultRoot .*:DefaultRoot ~:'                     $proftpd_conf
	sed -i 's:UseIPv6 .*:UseIPv6 off:'                            $proftpd_conf
	sed -i 's:IdentLookups .*:IdentLookups off:'                  $proftpd_conf
	sed -i 's:ServerIdent .*:ServerIdent on "FTP Server ready.":' $proftpd_conf

	echo -en "\n Force SSL? [y/n]: "
	if yes  # allow toggling of forcing ssl
		then sed -i 's:TLSRequired .*:TLSRequired on:'  $proftpd_conf
		else sed -i 's:TLSRequired .*:TLSRequired off:' $proftpd_conf
	fi
	log "ProFTP Installation | Completed" ; debug_wait "proftpd.installed"

##[ pureFTP ]##
elif [[ $ftpd = 'pureftp' ]]; then
	notice "iNSTALLiNG Pure-FTPd"
	if [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		build_from_aur "pure-ftpd" "pure-ftpd"
		echo "/etc/rc.d/pure-ftpd start" >> /etc/rc.local
		sed -i 's:NoAnonymous.*:NoAnonymous yes:' /etc/pure-ftpd.conf
		sed -i 's:# UnixAuthentication.*:UnixAuthentication yes:' /etc/pure-ftpd.conf
	else
		packages install pure-ftpd
		[[ -f /etc/default/pure-ftpd-common ]] && sed -i 's:STANDALONE_OR_INETD=.*:STANDALONE_OR_INETD=standalone:' /etc/default/pure-ftpd-common
	fi
	if_error "PureFTP failed to install"
	
	if [[ ! -f /etc/ssl/private/pure-ftpd.pem ]]; then  # Create SSL Certificate
		mkdir -p /etc/ssl/private
		mksslcert "/etc/ssl/private/pure-ftpd.pem" &&
		log "PureFTP SSL Key created"
	fi

	echo -en "\n Force SSL? [y/n]: "
	if yes ;then  # Force TLS
		if [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]
			then sed -i 's:# TLS.*:TLS 2:' /etc/pure-ftpd.conf
			else echo 2 > /etc/pure-ftpd/conf/TLS
		fi
	else  # Allow TLS+FTP
		if [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]
			then sed -i 's:# TLS.*:TLS 1' /etc/pure-ftpd.conf
			else echo 1 > /etc/pure-ftpd/conf/TLS
		fi
	fi
	echo -en "\n Allow FXP? [y/n]: "
	if yes ;then  # Allow FXP
		if [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]
			then sed -i 's:AllowUserFXP.*:AllowUserFXP yes:' /etc/pure-ftpd.conf
			#else TODO
		fi
	else  # Forbid FXP
		if [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]
			then sed -i 's:AllowUserFXP .* yes:AllowUserFXP no:' /etc/pure-ftpd.conf
			#else TODO
		fi
	fi
	log "PureFTP Installation | Completed" ; debug_wait "pureftp.installed"
fi

cd $SOURCE_DIR
if [[ $buildtorrent = 'b' ]]; then
#-->##[ BuildTorrent ]##
if ! is_installed "buildtorrent" ;then
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
	rm -r buildtorrent
	log "BuildTorrent Installation | Completed" ; debug_wait "buildtorrent.installed"
fi
elif [[ $buildtorrent != 'n' ]]; then
#-->##[ mkTorrent ]##
if ! is_installed "mktorrent" || [[ $buildtorrent = 'm' ]]; then
	notice "iNSTALLiNG MkTorrent"
	if [[ ! -d mktorrent ]]; then  # Checkout latest mktorrent source
		git clone -q git://github.com/esmil/mktorrent.git
		E_=$? ; if_error "MkTorrent Download Failed"
		log "MkTorrent | Downloaded"
	fi
	cd mktorrent
	make install

	E_=$? ; if_error "MkTorrent Build Failed"
	rm -r mktorrent
	log "MkTorrent Installation | Completed" ; debug_wait "mktorrent.installed"
fi
fi  # end `if $buildtorrent`

cd $BASE
##[ Torrent Clients ]##
if   [[ $torrent = 'rtorrent' ]]; then source modules/rtorrent/install.sh
elif [[ $torrent = 'tranny'   ]]; then source modules/transmission/install.sh
elif [[ $torrent = 'deluge'   ]]; then source modules/deluge/install.sh
fi

##[ ruTorrent ]##
[[ $webui = 'y' ]] && source modules/rutorrent/install.sh

##[ Extras ]##
[[ $enable_extras = 'y' ]] && source modules/extras.sh

##[ PostProcess ]##
source $BASE/includes/postprocess.sh || error "while loading postprocess.sh"
echo -e "\n*******************************"
echo -e   "******${bldred} SCRiPT COMPLETED! ${rst}******"
echo -e   "****${bldred} FiNiSHED iN ${bldylw}$SECONDS ${bldred}SECONDS ${rst}*"
echo -e   "*******************************\n"
log "*** SCRiPT COMPLETED | $(date) ***\n<---------------------------------> \n"
exit
