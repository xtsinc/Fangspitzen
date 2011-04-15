##[ XCache ]##
if [[ $cache = 'xcache' ]]; then
	notice "iNSTALLiNG X-CACHE"
	packages install php5-xcache
	if_error "X-Cache failed to install"

	echo -e "\n${bldylw} Generate a User Name and Password for XCache-Admin."
	echo -e " You can use http://trilug.org/~jeremy/md5.php to generate the password. ${rst}\n"
	read -p "   Login Name: " xUser  # Get UserName and Password
	read -p " MD5 Password: " xPass  # For XCache-Admin

	PATH_xcache="/etc/php5/conf.d/xcache.ini"
	sed -i "s:; xcache.admin.user .*:xcache.admin.user = $xUser:" $PATH_xcache
	sed -i "s:; xcache.admin.pass .*:xcache.admin.pass = $xPass:" $PATH_xcache
	sed -i 's:xcache.size  .*:xcache.size  = 48M:'                $PATH_xcache  # Increase cache size
	sed -i "s:xcache.count .*:xcache.count = $CORES:" 	          $PATH_xcache  # Specify CPU Core count
	sed -i 's:xcache.var_size  .*:xcache.var_size  = 8M:'         $PATH_xcache
	sed -i 's:xcache.optimizer .*:xcache.optimizer = On:'         $PATH_xcache
	cp -a /usr/share/xcache/admin "$WEB"/xcache-admin/  # Copy Admin folder to webroot

	log "XCache Installation | Completed" ; debug_wait "xcache.installed"

##[ APC ]##
elif [[ $cache = 'apc' ]]; then
	notice "iNSTALLiNG APC"
	if [[ $DISTRO = @(Ubuntu|[dD]ebian|*Mint|ARCH*|[Aa]rch*) ]]; then
		packages install php-apc
	elif [[ $DISTRO = @(SUSE|[Ss]use)* ]]; then
		packages install php5-APC
	fi
	if_error "PHP-APC failed to install"
	log "APC Installation | Completed" ; debug_wait "apc.installed"
fi

##[ mySQL ]##
if [[ $sql = 'mysql' ]]; then
	notice "iNSTALLiNG MySQL"
	if [[ $DISTRO = 'Ubuntu' && $NAME != 'hardy' ]]; then
		packages install libmysqlclient16-dev mysql-client mysql-server mytop
	elif [[ $DISTRO = [Dd]ebian || $NAME = 'hardy' ]]; then
		packages install libmysqlclient15-dev mysql-client mysql-server mytop
	elif [[ $DISTRO = @(SUSE|[Ss]use)* ]]; then
		packages install libmysqlclient-devel mysql-community-server mytop
		chkconfig --add mysql
		/etc/init.d/mysql start
		mysql_secure_installation
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		packages install mysql
		echo "/etc/rc.d/mysqld start" >> /etc/rc.local
		sed -i "s:;extension=mysql.so:extension=mysql.so:"   $PHPini
		sed -i "s:;extension=mysqli.so:extension=mysqli.so:" $PHPini
	fi
	if_error "MySQL failed to install"
	sed -ie 's:query_cache_limit .*:query_cache_limit = 2M\nquery_cache_type = 1:' /etc/mysql/my.cnf
	log "MySQL Installation | Completed" ; debug_wait "mysql.installed"

##[ SQLiTE ]##
elif [[ $sql = 'sqlite' ]]; then
	notice "iNSTALLiNG SQLite"
	packages install sqlite3 php5-sqlite
	if_error "SQLite failed to install"
	[[ $DISTRO = @(ARCH|[Aa]rch)* ]] && sed -i "s:;extension=sqlite3.so:extension=sqlite3.so:" $PHPini
	log "SQLite Installation | Completed" ; debug_wait "sqlite.installed"

##[ PostGreSQL ]##
elif [[ $sql = 'postgre' ]]; then
	notice "iNSTALLiNG PostgreSQL"
	if [[ $DISTRO = @(Ubuntu|[dD]ebian|*Mint) ]]; then
		packages install postgresql php5-pgsql
	elif [[ $DISTRO = @(SUSE|[Ss]use)* ]]; then
		packages install postgresql postgresql-server php5-pgsql
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		packages install postgresql php-pgsql
		echo "/etc/rc.d/postgresql start" >> /etc/rc.local
		sed -i "s:;extension=pgsql.so:extension=pgsql.so:"         $PHPini
		sed -i "s:;extension=pdo.so:extension=pdo.so:"             $PHPini
		sed -i "s:;extension=pdo_pgsql.so:extension=pdo_pgsql.so:" $PHPini
		/etc/rc.d/postgresql start
	fi
	if_error "PostgreSQL failed to install"
	log "PostgreSQL Installation | Completed" ; debug_wait "postgresql.installed"
fi

##[ Bouncers ]##
if [[ $bnc != @(none|no|[Nn]) ]]; then
	if [[ $DISTRO = @(Ubuntu|[dD]ebian|*Mint) ]]; then
		packages install libc-ares-dev tcl tcl-dev
	elif [[ $DISTRO = @(SUSE|[Ss]use)* ]]; then
		packages install libcares-devel tcl tcl-devel
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		packages install c-ares tcl
	fi
	if_error "Required packages failed to install"
fi

##[ ZNC ]##
if [[ $bnc = @(znc|znc dev) ]]; then
cd $HOME
	notice "iNSTALLiNG ZNC"
	if [[ $bnc = 'znc' ]]; then
		download http://people.znc.in/~psychon/znc//releases/znc-latest.tar.gz
			if_error "ZNC Download Failed"
		extract znc-latest.tar.gz && rm znc-latest.tar.gz
		cd znc-*  # seriously?
	elif [[ $bnc = 'znc dev' ]]; then
		git clone git://github.com/znc/znc.git znc-git ;E=$?
			if_error "ZNC Download Failed"
		cd znc-git
		sh autogen.sh
	fi
	log "ZNC | Downloaded + Unpacked"
	notice "Be aware that compiling znc is a cpu intensive task and may take up to 10 min to complete"
	sleep 3
	sh configure --enable-extra --enable-run-from-source
	compile
		if_error "ZNC Build Failed"
		log "ZNC Compile | Completed in $compile_time seconds"
		debug_wait "znc.compiled"
		log "ZNC Installation | Completed"
	notice "Starting znc for first time ${rst}"
	sudo -u $USER ./znc --makeconf

##[ sBNC ]##
elif [[ $bnc = 'sbnc' ]]; then
cd $SOURCE_DIR
	notice "iNSTALLiNG ShroudBNC"
	packages install swig
	git clone -q http://github.com/gunnarbeutner/shroudbnc.git
	git clone -q http://github.com/gunnarbeutner/sBNC-Webinterface.git
	chown -R $USER:$USER shroudbnc sBNC-Webinterface
		log "ShroudBNC | Downloaded"
	cd shroudbnc
	sudo -u $USER sh autogen.sh
	sudo -u $USER sh configure
	sudo -u $USER make -j$CORES
		if_error "ShroudBNC Build Failed"
		log "ShroudBNC Compile | Completed in $compile_time seconds"
	sudo -u $USER make install

	notice "Starting sbnc for first time... ${rst}"
	cd $HOME/sbnc
	sh sbnc
	log "ShroudBNC Installation | Completed"

##[ psyBNC ]##
elif [[ $bnc = 'psybnc' ]]; then
	cd $HOME
	notice "iNSTALLiNG PsyBNC"
	download http://psybnc.org.uk/psyBNC-2.3.2-10.tar.gz
		if_error "PsyBNC Download Failed"
	extract psyBNC-2.3.2-10.tar.gz
	chown -R $USER:$USER psybnc
		log "PsyBNC | Downloaded + Unpacked"

	cd psybnc
	sudo -u $USER make menuconfig
	sudo -u $USER make -j$CORES
		if_error "PsyBNC Build Failed"
		log "PsyBNC Compile | Completed in $compile_time seconds"
	log "PsyBNC Installation | Completed"
	notice "Installed to ~/psybnc"
fi

##[ Configure Fail2Ban ]##
if [[ $fail2ban = 'y' ]]; then
	notice "iNSTALLiNG Fail2Ban"
	packages install fail2ban ; if_error "Fail2ban failed to install"
	[[ $DISTRO = @(ARCH|[Aa]rch)* ]] && echo "/etc/rc.d/fail2ban start" >> /etc/rc.local

	f2b_jail=/etc/fail2ban/jail.conf
	if [[ ! $(grep '# added by autoscript' $f2b_jail) ]]; then  # Check if this has already been done
		sed -i 's:bantime .*:bantime = 86400:' $f2b_jail  # 24 hours
		sed -i '/[ssh]/,/port	= ssh/ s:enabled .*:enabled = true:' $f2b_jail
		if [[ $ftp = 'vsftp' ]]; then
			sed -i '/[vsftpd]/,/filter   = vsftpd/ s:enabled .*:enabled = true:' $f2b_jail
		elif [[ $ftp = 'proftp' ]]; then
			sed -i '/[proftpd]/,/filter   = proftpd/ s:enabled .*:enabled = true:' $f2b_jail
		elif [[ $ftp = 'pureftp' ]]; then
			sed -i 's:[wuftpd]:[pure-ftpd]:' $f2b_jail
			sed -i 's:filter   = wuftpd:filter   = pure-ftpd:'                                            $f2b_jail
			sed -i '/[pure-ftpd]/,/filter   = pure-ftpd/ s:enabled .*:enabled = true:'                    $f2b_jail
			sed -i '/filter   = pure-ftpd/,/maxretry = 6/ s:logpath .*:logpath  = /var/log/pureftpd.log:' $f2b_jail
		fi
		if [[ $http = 'apache' ]]; then
			sed -i '/[apache]/,/port	= http,https/ s:enabled .*:enabled = true:'           $f2b_jail
			sed -i '/[apache-noscript]/,/port    = http,https/ s:enabled .*:enabled = true:'  $f2b_jail
			sed -i '/[apache-overflows]/,/port    = http,https/ s:enabled .*:enabled = true:' $f2b_jail
			cat >> $f2b_jail << "EOF"
[apache-badbots]
enabled = true
port    = http,https
filter  = apache-badbots
logpath = /var/log/apache*/*error.log
maxretry = 3
EOF
		fi
		if [[ $webmin = 'y' ]]; then
			cat >> $f2b_jail << "EOF"
[webmin-auth]
enabled = true
port	= 10000
filter	= webmin-auth
logpath = /var/log/auth.log
maxretry = 5
EOF
		fi
		echo "# added by autoscript" >> $f2b_jail
	fi  # end `if $?`
	log "Fail2ban Installation | Completed" ; debug_wait "fail2ban.installed"
fi

##[ phpSysInfo ]##
if [[ $phpsysinfo = @(y|dev) ]]; then
cd $SOURCE_DIR
	notice "iNSTALLiNG phpSysInfo"
	[[ $phpsysinfo = 'dev' ]] &&
		checkout https://phpsysinfo.svn.sourceforge.net/svnroot/phpsysinfo/trunk phpsysinfo
	[[ $phpsysinfo = 'y' ]] &&
		download http://downloads.sourceforge.net/project/phpsysinfo/phpsysinfo/3.0.10/phpsysinfo-3.0.10.tar.gz &&
		extract phpsysinfo-3.0.10.tar.gz
	cd phpsysinfo
	rm ChangeLog COPYING README README_PLUGIN ChangeLog
	cp config.php.new config.php

	sed -i "s:define('PSI_PLUGINS'.*:define('PSI_PLUGINS', 'PS,PSStatus,Quotas,SMART');:"     config.php
	sed -i "s:define('PSI_TEMP_FORMAT'.*:define('PSI_TEMP_FORMAT', 'c-f');:"                  config.php
	sed -i "s:define('PSI_DEFAULT_TEMPLATE',.*);:define('PSI_DEFAULT_TEMPLATE', 'nextgen');:" config.php
	sed -e "/open_basedir = /s|$|:/proc:/usr/sbin/lspci:/usr/sbin/lsusb|"            -i /etc/php/php.ini

	cd ..
	mv phpsysinfo $WEB 
	log "phpSysInfo Installation | Completed" ; debug_wait "phpsysinfo.installed"
fi

##[ WebMiN ]##
cd $BASE
if [[ $webmin = 'y' ]]; then
	notice "iNSTALLiNG WEBMiN"
	if [[ $DISTRO = @(Ubuntu|[dD]ebian|*Mint) ]]; then
		packages install webmin libauthen-pam-perl libio-pty-perl libnet-ssleay-perl libpam-runtime
	elif [[ $DISTRO = @(SUSE|[Ss]use)* ]]; then
		packages install webmin perl-Net-SSLeay
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		packages install webmin
		echo "/etc/rc.d/webmin start" >> /etc/rc.local
	fi
	if_error "Webmin failed to install"
	log "WebMin Installation | Completed" ; debug_wait "webmin.installed"
fi

##[ vnStat ]##
if [[ $vnstat = @(jsvnstat|vnstatphp) ]]; then
cd $SOURCE_DIR
	notice "iNSTALLiNG VNSTAT"
	if [[ $DISTRO = @(Ubuntu|[dD]ebian|*Mint) ]]; then
		packages install libgd2-xpm-dev
	elif [[ $DISTRO = @(SUSE|[Ss]use)* ]]; then
		packages install gd gd-devel
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		packages install gd
	fi
	if_error "vnStat deps failed to install"
	
	download http://humdi.net/vnstat/vnstat-1.10.tar.gz # Download VnStat
	extract vnstat-1.10.tar.gz && cd vnstat-1.10        # Unpack

	compile all
		if_error "VnStat Build Failed"
		log "VnStat Compile | Completed in $compile_time seconds"
	make install
	cd ..
		log "VnStat Installation | Completed"
		debug_wait "vnstat.compiled"

	if [[ $DISTRO = @(ARCH|[Aa]rch)* && ! -f /etc/rc.d/vnstat ]]; then
		install -m 755 vnstat-1.10/examples/init.d/arch/vnstat /etc/rc.d/  # Copy init script if one doesnt exist
		echo "/etc/rc.d/vnstat start" >> /etc/rc.local                     # Start at boot
		log "VnStat | Created RC Script"
	elif [[ ! -f /etc/init.d/vnstat ]]; then
		install -m 755 vnstat-1.10/examples/init.d/debian/vnstat /etc/init.d/  # Copy init script if one doesnt exist
		update-rc.d vnstat defaults                                            # Start at boot
		log "VnStat | Created Init Script"
	else log "VnStat | Previous Init Script Found, skipping..."
	fi

	sed -i "s:UnitMode 0:UnitMode 1:"               /etc/vnstat.conf  # Use MB not MiB
	sed -i "s:RateUnit 1:RateUnit 0:"               /etc/vnstat.conf  # Use bytes not bits
	sed -i "s:UpdateInterval 30:UpdateInterval 60:" /etc/vnstat.conf  # Increase daemon checks
	sed -i "s:PollInterval 5:PollInterval 10:"      /etc/vnstat.conf  # ^^^^^^^^ ^^^^^^ ^^^^^^
	sed -i "s:SaveInterval 5:SaveInterval 10:"      /etc/vnstat.conf  # Less saves to disk
	sed -i "s:UseLogging 2:UseLogging 1:"           /etc/vnstat.conf  # Log to file instead of syslog
	
	if [[ $vnstat = 'vnstatphp' ]]; then
		notice "iNSTALLiNG VNSTAT-PHP"
		git clone -q git://github.com/bjd/vnstat-php-frontend.git vnstat-web                           # Checkout VnStat-Web
		rm -rf vnstat-web/themes/espresso vnstat-web/themes/light vnstat-web/themes/red                # Remove extra themes
		rm -rf vnstat-web/COPYING vnstat-web/vera_copyright.txt vnstat-web/config.php vnstat-web/.git  # Remove extra files
		cp $BASE/modules/vnstat/vnstat-web.config.php vnstat-web/config.php
		sed -i "s|\$iface_list = .*|\$iface_list = array('$iFACE');|" vnstat-web/config.php
		mv vnstat-web $WEB
	elif [[ $vnstat = 'jsvnstat' ]]; then
		notice "iNSTALLiNG JSVNSTAT"
		download http://www.rakudave.ch/userfiles/javascript/jsvnstat/jsvnstat.zip  # Download jsvnstat
		extract jsvnstat.zip && rm jsvnstat/README.txt jsvnstat/js/API.txt          # Remove extra files
		sed -i "s|\$interface =.*|\$interface = \"$iFACE\";|" jsvnstat/settings.php
		mv jsvnstat $WEB
	fi

	! is_running "vnstatd" &&  # Make database and start vnstatd
		vnstat -u -i $iFACE && vnstatd -d

	log "VnStat | Frontend Installed"
	debug_wait "vnstat.installed"
fi

##[ SABnzbd ]##
if [[ $sabnzbd = 'y' ]]; then
cd $SOURCE_DIR
	notice "iNSTALLiNG SABnzbd"
	if [[ $DISTRO = @(Ubuntu|[dD]ebian|*Mint) ]]; then
			packages install par2 python-cheetah python-dbus python-feedparser python-memcache python-utidylib python-yenc sabnzbdplus sabnzbdplus-theme-classic sabnzbdplus-theme-plush sabnzbdplus-theme-smpl
	elif [[ $DISTRO = @(SUSE|[Ss]use)* ]]; then
		echo "TODO" # packages install
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		echo "TODO" # packages install libpar2 python-cheetah
	fi
	if_error "Sabnzbd failed to install"

	# Install par2cmdline 0.4 with Intel Threading Building Blocks
	[[ $ARCH = 'x86_64' ]] &&
		download http://chuchusoft.com/par2_tbb/par2cmdline-0.4-tbb-20100203-lin64.tar.gz ||
		download http://chuchusoft.com/par2_tbb/par2cmdline-0.4-tbb-20090203-lin32.tar.gz

	extract par2cmdline-0.4*.tar.gz && cd par2cmdline-0.4*
	mv libtbb.so libtbb.so.2 par2 /usr/bin ; cd ..

	#if [[ $NAME = 'lenny' ]]; then
	#	libjs-mochikit >= 1.4
	#fi

	#read -p "  User Name that will run SABnzbd: " SABuser
	sabnzbd_conf=/home/$USER/.sabnzbd/sabnzbd.ini
	sabnzbd_init=/etc/default/sabnzbdplus

	sed -i "s:USER.*:USER=$USER:"   $sabnzbd_init
	sed -i "s:HOST.*:HOST=0.0.0.0:" $sabnzbd_init
	sed -i "s:PORT.*:PORT=8080:"    $sabnzbd_init
	/etc/init.d/sabnzbdplus start && /etc/init.d/sabnzbdplus stop  # Create config in user's home

	sed -i "s:host .*:host = $iP:"  $sabnzbd_conf
	[[ $CORES < 2 ]] && 
		sed -i "s:par2_multicore .*:par2_multicore = 0:" $sabnzbd_conf

	/etc/init.d/sabnzbdplus start  # Start 'er up

	log "SABnzbd Installation | Completed"
	log "SABnzbd Started and Running at http://$iP:8080" ; debug_wait "SABnzbd.installed"
fi

##[ iPLiST ]##
if [[ $ipblock = 'y' ]]; then
	notice "iNSTALLiNG iPBLOCK"
	if [[ $DISTRO = @(Ubuntu|[dD]ebian|*Mint) ]]; then
		if [[ $NAME = 'lenny' ]]; then
			apt-get -t squeeze install libpcre3 libnfnetlink0 libnetfilter-queue1 2>> $LOG  # Install updated libraries for lenny support
		fi
		packages install iplist
	elif [[ $DISTRO = @(SUSE|[Ss]use)* ]]; then
		packages install iplist libpcre0 libnfnetlink0 libnetfilter-queue1
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		packages install iplist libnetfilter_queue libnfnetlink
		echo "/etc/rc.d/iplist start" >> /etc/rc.local
	fi
	if_error "iPBLOCK failed to install"

	PATH_iplist=/etc/ipblock.conf
	filters='level1.gz'
	sed -i "s:AUTOSTART=.*:AUTOSTART=\"Yes\":"        $PATH_iplist
	sed -i "s:BLOCK_LIST=.*:BLOCK_LIST=\"$filters\":" $PATH_iplist

	echo -en "${bldred} Updating block lists... ${rst}"
	ipblock -u && echo -e "${bldylw} done ${rst}"
	/etc/init.d/ipblock start

	log "iPBLOCK Installation | Completed" ; debug_wait "ipblock.installed"
fi

##[ ViRTUALBOX ]##
if [[ $virtualbox = 'y' ]]; then  # TODO
	notice "iNSTALLiNG ViRTUALBOX"
	if [[ "$DISTRO" = @([uU]buntu|[dD]ebian|*Mint) ]]; then
		echo "deb http://download.virtualbox.org/virtualbox/debian "$NAME" contrib" >> $REPO_PATH/autoinstaller.list  # Add repo
		wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | apt-key add -                  # Add key
		packages update && packages install linux-headers-$(uname -r) dkms virtualbox-4.0                             # Install virtualbox
		download http://download.virtualbox.org/virtualbox/4.0.2/Oracle_VM_VirtualBox_Extension_Pack-4.0.2-69518.vbox-extpack
		VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-4.0.2-69518.vbox-extpack  # Install extention pack for remote support
		adduser $USER vboxusers  # Let our user use virtualbox
	elif [[ $DISTRO = @(SUSE|[Ss]use)* ]]; then
		packages install  # TODO
	elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
		packages install kernel26-headers virtualbox virtualbox-ext-oracle
		gpasswd -a $USER vboxusers
		/etc/rc.d/vboxdrv setup  # Build kernel modules
		modprobe vboxdrv && archlinux_add_module "vboxdrv"
	fi
	
	notice "VBoxManage --help \n VBoxHeadless --help"
	log "ViRTUALBOX Installation | Completed" ; debug_wait "virtualbox.installed"
	
	echo -en "\n Install php-virtualbox frontend? [y/n]: "
	if yes
		then phpvirtualbox='y'
		else phpvirtualbox='n'
	fi

##[ PHP-ViRTUALBOX ]##
if [[ $phpvirtualbox = 'y' ]]; then  # TODO
	echo "TODO"
	#if [[ $DISTRO = @(Ubuntu|[dD]ebian|*Mint) ]]; then
	#	packages install
	#elif [[ $DISTRO = @(SUSE|[Ss]use)* ]]; then
	#	packages install
	#elif [[ $DISTRO = @(ARCH|[Aa]rch)* ]]; then
	#	packages install phpvirtualbox
	#	sed -i "s:;extension=json.so:extension=json.so:" /etc/php/php.ini
	#	sed -i "s:;extension=soap.so:extension=soap.so:" /etc/php/php.ini
	#fi
fi
fi  # end `if $virtualbox`

##[ ZSHELL ]##
if [[ $zshell = 'y' ]]; then
	notice "iNSTALLiNG ZSHELL"
	packages install zsh
	if_error "ZSH failed to install"
	
sudo -u "$USER" bash -c '
	if [[ ! -d $HOME/.oh-my-zsh ]]; then
		git clone git://github.com/robbyrussell/oh-my-zsh.git $HOME/.oh-my-zsh

	[[ -f $HOME/.zshrc || -h $HOME/.zshrc ]] &&
		cp $HOME/.zshrc $HOME/.zshrc.pre-oh-my-zsh && rm $HOME/.zshrc

	cp ~/.oh-my-zsh/templates/zshrc.zsh-template $HOME/.zshrc
	echo "export PATH=$PATH" >> $HOME/.zshrc

	echo " Changing your default shell to zsh ..."
	chsh -s `which zsh`

	echo -e "\n Zsh is now installed"
	echo -e " Re-login to use it. \n"

	else
		echo "Previous Oh My Zsh installation detected. Running updater..."
		cd $HOME/.oh-my-zsh && git pull
		echo "Any new updates will be reflected when you start your next terminal session."
	fi
'
fi
