##!=======================>> QUESTiONS <<========================!##
while [[ "$skip_ques" = n ]]; do
echo -e "\n ${txtred}-------------->>${bldred} CONFiGURATiON ${txtred}<<---------------${rst}"

read -p "[ HTTP SERVER ]        [apache|lighttp|nginx|none]: " http
[[ "$http" = 'lighttpd' ]] && http='lighttp'
if [[ "$http" != @(none|[Nn]) && "$DEBUG" = 1 ]]; then
read -p "[ Create info.php? ]                         [y|n]: " create_phpinfo ;fi
read -p "[ FTP SERVER  ]        [vsftp|proftp|pureftp|none]: " ftpd
read -p "[ Torrent App ]      [rtorrent|tranny|deluge|none]: " torrent

if [[ "$torrent" = 'rtorrent' ]]; then
read -p "[ compile from svn? ]                        [y|n]: " rtorrent_svn ;fi

read -p "[ ruTorrent WebUi ]                          [y|n]: " webui

if ! is_installed "mktorrent" && ! is_installed "buildtorrent" ;then
read -p "[ MkTorrent or BuildTorrent ]                [m|b]: " buildtorrent
else buildtorrent='n' ;fi

#!=====================>> CONFIRMATION <<=======================!#
echo -e "\n*******************************"
echo -e   "**********${bldred} CONFiRM ${rst}************"
echo -e   "*******************************\n"

##[ Check for HTTP ]##
if [[ $http = 'apache' ]]; then
	[[ "$DISTRO" = @(ARCH|[Aa]rch)* ]] &&
		v1=$(packages version apache) ||
	v1=$(packages version apache2)
	echo -e "${bldblu} Apache: $v1 ${rst}"
elif [[ $http = 'lighttp' ]]; then
	v1=$(packages version lighttpd)
	echo -e "${bldblu} Lighttpd: $v1 ${rst}"
elif [[ $http = 'nginx' ]]; then
	if [[ $NAME = @(karmic|jaunty|hardy) ]]; then
		echo -e "${bldred} UPDATE to Lucid or higher ${rst}"
		http='none'
	else
		v1=$(packages version nginx)
		echo -e "${bldblu} Nginx: $v1 ${rst}" ;fi
elif [[ $http = @(none|no|[Nn]) ]]
	then echo -e "${bldylw} WEB SERVER NOT BEiNG iNSTALLED ${rst}"
	else echo -e "${bldred}--> ERROR iN HTTP iNPUT! ${rst}"; http='none'
fi

##[ Check for FTP ]##
if [[ $ftpd = 'vsftp' ]]; then
	v1=$(packages version vsftpd)
	echo -e "${bldblu} vsFTPd: $v1 ${rst}";
elif [[ $ftpd = 'proftp' ]]; then
	[[ "$DISTRO" = @(ARCH|[Aa]rch)* ]] &&
		v1=$(packages version proftpd) ||
	v1=$(packages version proftpd-basic)
	echo -e "${bldblu} ProFTPd: $v1 ${rst}"
elif [[ $ftpd = 'pureftp' ]]; then
	v1=$(packages version pure-ftpd)
	echo -e "${bldblu} PureFTPd: $v1 ${rst}"
elif [[ $ftpd = @(none|no|[Nn]) ]]
	then echo -e "${bldylw} FTP SERVER NOT BEiNG iNSTALLED ${rst}"
	else echo -e "${bldred}--> ERROR iN FTP iNPUT! ${rst}"; ftpd='none'
fi

##[ Check for Torent Client ]##
if [[ $torrent = 'rtorrent' ]]; then
	if [[ $rtorrent_svn = 'y' ]]
		then echo -e "${bldblu} Package: rTorrent: Version: 0.8.9~svn HEAD ${rst}"
		else echo -e "${bldblu} Package: rTorrent: Version: 0.8.8 ${rst}"; rtorrent_svn='n'
	fi
	if [[ $alloc = 'y' ]]; then
		echo -e "${bldpur} Compiling --with-posix-fallocate ${rst}"
		echo -e "${bldpur} See http://libtorrent.rakshasa.no/ticket/460 for more info and potential dangers. Do not use on ext3 ${rst}"
		read -p "Press ENTER if OK " ENTER
	else alloc='n'
	fi
elif [[ $torrent = 'tranny' ]]; then
	if [[ $NAME = 'lenny' ]]; then
		echo -e "${bldred} TODO! ${rst}"
		torrent='none'
	elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		v1=$(packages version transmission-cli)
	else
		v1=$(packages version transmission-daemon)
	fi
	echo -e "${bldblu} Transmission: $v1 ${rst}"
elif [[ $torrent = 'deluge' ]]; then
	if [[ $NAME = 'lenny' ]]; then
		echo -e "${bldred} TODO! ${rst}"
		torrent='none'
	else
		v1=$(packages version deluge)
		echo -e "${bldblu} Deluge: $v1 ${rst}"
	fi
elif [[ $torrent = @(none|no|[Nn]) ]]
	then echo -e "${bldylw} TORRENT CLiENT NOT BEiNG iNSTALLED ${rst}"
	else echo -e "${bldred}--> ERROR iN TORRENT CLiENT iNPUT! ${rst}"; torrent='none'
fi

if [[ $torrent != @(none|no|[Nn]) ]]; then
	if [[ ${buildtorrent} = 'b' ]]
		then echo -e "${bldblu} Package: Buildtorrent: Version: 0.9~git ${rst}"
	elif [[ ${buildtorrent} = 'm' ]]
		then echo -e "${bldblu} Package: Mktorrent: Version: 1.0~git ${rst}"
	fi
fi

##[ Check for ruTorrent ]##
if [[ $webui = 'y' ]]
	then echo -e "${bldblu} Package: ruTorrent: Version: 3.1~svn ${rst}"
elif [[ $webui = @(none|no|[Nn]) ]]
	then echo -e "${bldylw} WEBUi NOT BEiNG iNSTALLED ${rst}"
	else echo -e "${bldred}--> ERROR iN WEBUi iNPUT! ${rst}"; webui='n'
fi

if [[ $enable_extras = y ]]; then
##[ Check for PHP Cache] ]##
if [[ $cache = @(xcache|x) ]]; then
	cacheV=$(packages version php5-xcache)
	echo -e "${bldblu} XCache: $cacheV ${rst}"
elif [[ $cache = 'apc' ]]; then
	cacheV=$(packages version php-apc)
	echo -e "${bldblu} APCache: $cacheV ${rst}"
elif [[ $cache = @(none|no|[Nn]) ]]
	then echo -e "${bldylw} PHP CACHE NOT BEiNG iNSTALLED ${rst}"
	else echo -e "${bldred}--> ERROR iN PHP CACHE iNPUT! ${rst}"; cache='none'
fi

##[ Check for SQL ]##
if [[ $sql = 'mysql' ]]; then
	[[ "$DISTRO" = @(ARCH|[Aa]rch)* ]] &&
		v1=$(packages version mysql) ||
	v1=$(packages version mysql-server)
	echo -e "${bldblu} MySQL: $v1 ${rst}"
elif [[ $sql = 'sqlite' ]]; then
	v1=$(packages version sqlite3)
	echo -e "${bldblu} SQLite: $v1 ${rst}"
elif [[ $sql = @(postgre|postgresql) ]]; then
	v1=$(packages version postgresql)
	echo -e "${bldblu} PostgreSQL: $v1 ${rst}"
elif [[ $sql = @(none|no|[Nn]) ]]
	then echo -e "${bldylw} SQL SERVER NOT BEiNG iNSTALLED ${rst}"
	else echo -e "${bldred}--> ERROR iN SQL iNPUT! ${rst}"; sql='none'
fi

##[ Check for BNC ]##
if [[ $bnc = 'znc' ]]
	then echo -e "${bldblu} Package: ZNC: Version: 0.094 ${rst}"
elif [[ $bnc = 'psybnc' ]]
	then echo -e "${bldblu} Package: psyBNC: Version: 2.3.2-9 ${rst}"
elif [[ $bnc = 'sbnc' ]]
	then echo -e "${bldblu} Package: ShroudBNC: Version: 1.3~git ${rst}"
elif [[ $bnc = @(none|no|[Nn]) ]]
	then echo -e "${bldylw} BOUNCER NOT BEiNG iNSTALLED ${rst}"
	else echo -e "${bldred}--> ERROR iN iRC BOUNCER iNPUT! ${rst}"; bnc='none'
fi

##[ Check for phpSysInfo ]##
if [[ $phpsysinfo = 'y' ]]
	then echo -e "${bldblu} Package: phpSysInfo: Version: 3.1~svn ${rst}"
elif [[ $phpsysinfo = @(none|no|[Nn]) ]]
	then echo -e "${bldylw} phpSysInfo NOT BEiNG iNSTALLED ${rst}"
	else echo -e "${bldred}--> ERROR iN phpSysInfo iNPUT! ${rst}"; phpsysinfo='n'
fi

##[ Check for WEBMiN ]##
if [[ $webmin = 'y' ]]; then
	v1=$(packages version webmin)
	echo -e "${bldblu} Webmin: $v1 ${rst}"
elif [[ $webmin = @(none|no|[Nn]) ]]
	then echo -e "${bldylw} WEBMiN NOT BEiNG iNSTALLED ${rst}"
	else echo -e "${bldred}--> ERROR iN WEBMiN iNPUT! ${rst}"; webmin='n'
fi

##[ Check for VnStat ]##
if [[ $vnstat = 'jsvnstat' ]]
	then echo -e "${bldblu} Package: jsvnstat: Version: 1.9 ${rst}"
elif [[ $vnstat = 'vnstatphp' ]]
	then echo -e "${bldblu} Package: vnstat-php: Version: 1.5.1~git ${rst}"
elif [[ $vnstat = @(none|no|[Nn]) ]]
	then echo -e "${bldylw} VNSTAT NOT BEiNG iNSTALLED ${rst}"
	else echo -e "${bldred}--> ERROR iN VNSTAT iNPUT! ${rst}"; vnstat='none'
fi

##[ Check for SABnzbd ]##
if [[ $sabnzbd = 'y' ]]; then
	if [[ $DISTRO != @([uU]buntu|[dD]ebian) ]]
		then echo -e "Only packaged for Ubuntu.\nSee  http://sabnzbd.org/download  for installing it manually."; sabnzbd = 'n'
	else
		v1=$(packages version sabnzbdplus)
		echo -e "${bldblu} SabNZBd: $v1 ${rst}"
	fi
elif [[ $sabnzbd = @(none|no|[Nn]) ]]
	then echo -e "${bldylw} SABnzbd NOT BEiNG iNSTALLED ${rst}"
	else echo -e "${bldred}---> ERROR iN SABnzbd iNPUT! ${rst}"; sabnzbd='n'
fi

##[ Check for iPBLOCK ]##
if [[ $ipblock = 'y' ]]; then
	v1=$(packages version iplist)
	echo -e "${bldblu} IPList: $v1 ${rst}"
elif [[ $ipblock = @(none|no|[Nn]) ]]
	then echo -e "${bldylw} iPBLOCK NOT BEiNG iNSTALLED ${rst}"
	else echo -e "${bldred}---> ERROR iN iPBLOCK iNPUT! ${rst}"; ipblock='n'
fi

##[ Check for ZSH ]##
if [[ $zshell = 'y' ]]; then
	v1=$(packages version zsh)
	echo -e "${bldblu} ZSH: $v1 ${rst}"
elif [[ $zshell = @(none|no|[Nn]) ]]
	then echo -e "${bldylw} ZSHELL NOT BEiNG iNSTALLED ${rst}"
	else echo -e "${bldred}---> ERROR iN ZSHELL iNPUT! ${rst}"; zshell='n'
fi ; fi  # end `if $extras`

##[ CONFiRMATiON ]##
echo -en "\n Is this correct? [y/n]: "
	if yes
		then skip_ques=y ; break
	fi
done  # Answer was no, so we loop back and do it again
log "Questionaire | Completed"
