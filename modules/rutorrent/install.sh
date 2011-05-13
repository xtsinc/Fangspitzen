install_rutorrent='no'
while [[ $install_rutorrent = 'no' ]]; do
	if [[ ! -d $WEB/rutorrent ]]; then
		install_rutorrent='yes'
	else  # Ask to update rutorrent if exists
		notice "ruTorrent Found => Updating" ; sleep 1
		cd $WEB/rutorrent && svn up
		break
	fi
done

if [[ $install_rutorrent = 'yes' ]]; then
cd $SOURCE_DIR
	notice "iNSTALLiNG ruTorrent"
	checkout http://rutorrent.googlecode.com/svn/trunk/rutorrent
	if_error "ruTorrent Download Failed"
	log "ruTorrent | Downloaded"

cd rutorrent
	rm -R plugins conf/plugins.ini favicon.ico
	cp $BASE/modules/rutorrent/plugins.ini conf/plugins.ini
	cp $BASE/modules/rutorrent/favicon.ico favicon.ico

	notice "iNSTALLiNG Plugins"
	checkout http://rutorrent.googlecode.com/svn/trunk/plugins  # Checkout plugins-svn
	if_error "ruTorrent Plugins Download Failed"

	# Install extra plugins
cd plugins
	checkout http://rutorrent-pausewebui.googlecode.com/svn/trunk pausewebui
	checkout http://rutorrent-logoff.googlecode.com/svn/trunk logoff
	checkout http://rutorrent-instantsearch.googlecode.com/svn/trunk instantsearch
	checkout http://svn.rutorrent.org/svn/filemanager/trunk/filemanager
	checkout http://svn.rutorrent.org/svn/filemanager/trunk/fileshare
	checkout http://svn.rutorrent.org/svn/filemanager/trunk/mediastream
	checkout http://rutorrent-chat.googlecode.com/svn/trunk chat
	extract $BASE/modules/rutorrent/nfo_img.tar.gz nfo_img
	log "ruTorrent plugins | Downloaded"

cd $SOURCE_DIR
	sed -i rutorrent/conf/config.php \
	-e "s:\$saveUploadedTorrents .*:\$saveUploadedTorrents = false;:"         \
	-e "s:\$topDirectory .*:\$topDirectory = '/home';:"                       \
	-e "s:\$XMLRPCMountPoint .*:\$XMLRPCMountPoint = \"/rutorrent/master\";:"
	sed -i "s:\$defaultTheme .*:\$defaultTheme = \"Oblivion\";:"                  rutorrent/plugins/theme/conf.php

	notice "CONFiGURiNG USER AUTHENTiCATiON"
	if [[ $(pgrep apache2) || $(pgrep httpd) || $http = 'apache' ]]; then  # Apache - Create user authentication
		cp $BASE/modules/apache/htaccess rutorrent/.htaccess
		if [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]
			then htdigest -c /etc/httpd/.htpasswd "ruTorrent" $USER
				 sed -i "s:apache2:httpd:" rutorrent/.htaccess
		elif [[ "$DISTRO" = @(SUSE|[Ss]use)* ]]
			then htdigest2 -c /etc/apache2/.htpasswd "ruTorrent" $USER
		else htdigest -c /etc/apache2/.htpasswd "ruTorrent" $USER
		fi
	elif [[ $(pgrep lighttpd) || $http = 'lighttp' ]]; then  # Lighttp - Create user authentication
		if [[ "$DISTRO" = @(SUSE|[Ss]use)* ]]
			then htdigest2 -c /etc/lighttpd/.htpasswd "ruTorrent" $USER
			else htdigest -c /etc/lighttpd/.htpasswd "ruTorrent" $USER
		fi
	fi

	if is_installed "buildtorrent"
		then sed -i "s:	\$useExternal .*;:	\$useExternal = \"buildtorrent\";:"                              rutorrent/plugins/create/conf.php
			#sed -i "s:	\$pathToCreatetorrent .*;:	\$pathToCreatetorrent = '/usr/local/bin/buildtorrent';:" rutorrent/plugins/create/conf.php
	elif is_installed "mktorrent"
		then sed -i "s:	\$useExternal .*;:	\$useExternal = \"mktorrent\";:"                                 rutorrent/plugins/create/conf.php
			#sed -i "s:	\$pathToCreatetorrent .*;:	\$pathToCreatetorrent = '/usr/local/bin/mktorrent';:"    rutorrent/plugins/create/conf.php
	fi
	log "ruTorrent Config | Created"

	cp -R rutorrent "$WEB"  # Move rutorrent to webroot
	chmod -R 755 $WEB
	chown -R $WEBUSER:$WEBGROUP $WEB
	log "ruTorrent Installation | Completed" ; debug_wait "rutorrent.installed"
fi
