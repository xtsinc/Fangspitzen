compile_xmlrpc='no'
while [[ $compile_xmlrpc = 'no' ]]; do
	if is_installed "xmlrpc-c-config"  # Ask to re-compile xmlrpc if already installed
		then echo -en "XMLRPC-C is already installed.... overwrite? [y/n]: "
		if yes
			then compile_xmlrpc='yes'  # yes, reinstall
			else compile_xmlrpc='skip'  # no, skip this 
		fi
	else compile_xmlrpc='yes'  # yes, install because its not installed
	fi

compile_rtorrent='no'
while [[ $compile_rtorrent = 'no' ]]; do 
	if is_installed "rtorrent"
		then echo -en "rTorrent is already installed.... overwrite? [y/n]: "
		if yes
			then compile_rtorrent='yes'
			else compile_rtorrent='skip'
		fi
		break
	else compile_rtorrent='yes'
	fi
done ; done

if [[ "$DISTRO" = @(ARCH|[Aa]rch)* && $rtorrent_svn != 'y' ]]; then
	compile_rtorrent='no' compile_xmlrpc='no'
	packages install "libsigc++ openssl curl xmlrpc-c"
	build_from_aur "/usr/lib/libtorrent.so" "libtorrent-extended"
	build_from_aur "rtorrent" "rtorrent-extended"
fi

if [[ $compile_xmlrpc = 'yes' ]]; then
cd $SOURCE_DIR
	notice "DOWNLOADiNG... XMLRPC"
	checkout http://xmlrpc-c.svn.sourceforge.net/svnroot/xmlrpc-c/advanced xmlrpc  # Checkout xmlrpc ~advanced
	if_error "XMLRPC Download Failed"
	log "XMLRPC | Downloaded" >> $LOG

	notice "COMPiLiNG... XMLRPC"
#-->[ Compile xmlrpc ]
	cd xmlrpc
	sh configure --prefix=/usr --disable-cplusplus
	compile
		if_error "XMLRPC Build Failed"
		log "XMLRPC Compile | Completed in $compile_time seconds"
	make install ; cd ..
	rm -r xmlrpc
		log "XMLRPC Installation | Completed" ; debug_wait "xmlrpc.installed"
fi #`end compile_xmlrpc`

if [[ $compile_rtorrent = 'yes' ]]; then
cd $SOURCE_DIR
	notice "DOWNLOADiNG... rTORRENT"
	if [[ $rtorrent_svn = 'y' ]]; then
		checkout -r 1180 svn://rakshasa.no/libtorrent/trunk
		if_error "Lib|rTorrent Download Failed"
		mv trunk/libtorrent libtorrent && mv trunk/rtorrent rtorrent && rm -r trunk
		log "Lib|rTorrent | Downloaded" >> $LOG
	else
		download http://libtorrent.rakshasa.no/downloads/libtorrent-0.12.6.tar.gz  # Grab libtorrent
		if_error "LibTorrent Download Failed"
		download http://libtorrent.rakshasa.no/downloads/rtorrent-0.8.6.tar.gz     # Grab rtorrent
		if_error "rTorrent Download Failed"
		log "Lib|rTorrent | Downloaded" >> $LOG

		extract libtorrent-0.12.6.tar.gz && extract rtorrent-0.8.6.tar.gz          # Unpack
		mv libtorrent-0.12.6 libtorrent && mv rtorrent-0.8.6 rtorrent
		log "Lib|rTorrent | Unpacked"
	fi

patch_rtorrent

	notice "COMPiLiNG... LiBTORRENT"
#-->[ Compile libtorrent ]
	cd libtorrent
	[[ $NAME = 'lenny' ]] && rm -f scripts/{libtool,lt*}.m4
	sh autogen.sh
	[[ $alloc = 'y' ]] &&  # Use posix_fallocate
		sh configure --prefix=/usr --with-posix-fallocate ||
		sh configure --prefix=/usr
	compile
		if_error "LibTorrent Build Failed"
		log "LibTorrent Compile | Completed in $compile_time seconds"
	make install ; cd ..
	rm -r libtorrent
		log "LibTorrent Installation | Completed" ; debug_wait "libtorrent.installed"

	notice "COMPiLiNG... rTORRENT"
#-->[ Compile rtorrent ]
	cd rtorrent
	[[ $NAME = 'lenny' ]] && rm -f scripts/{libtool,lt*}.m4
	sh autogen.sh
	sh configure --prefix=/usr --with-xmlrpc-c
	compile
		if_error "rTorrent Build Failed"
		log "rTorrent Compile | Completed in $compile_time seconds"
	make install ; cd ..
	rm -r rtorrent
		log "rTorrent Installation | Completed"
fi #`end compile_rtorrent`

if [[ -f .rtorrent.rc ]]; then
	log "Previous rTorrent.rc config found, creating backup..."
	mv .rtorrent.rc .rtorrent.rc.bak
	notice "BACKED UP PREVIOUS rTORRENT.RC"
fi

echo -en "\n${bldred} CREATiNG .rtorrent.rc CONFiG...${rst}"
cd $HOME
sudo -u $USER mkdir -p .session
sudo -u $USER mkdir -p downloads

PATH_rt=$HOME/.rtorrent.rc
cd $BASE
cp modules/rtorrent/rtorrent.rc "$PATH_rt"

NUMBER=$[($RANDOM % 65534) + 20000]  # Generate a random number from 20000-65534
echo "port_range = $NUMBER-$NUMBER"       >> $PATH_rt
echo "directory = /home/$USER/downloads"  >> $PATH_rt
echo "session = /home/$USER/.session"     >> $PATH_rt
echo -e "${bldylw} done${rst}"

if [[ $rtorrent_svn != 'y' ]]; then
	echo "max_open_files = 256"    >> $PATH_rt
	echo "max_memory_usage = 800M" >> $PATH_rt
	echo "preload_type = 1"        >> $PATH_rt
	if [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		download "http://iblocklist.charlieprice.org/files/bt_level1.gz"
		download "http://iblocklist.charlieprice.org/files/tbg_primarythreats.gz"
		echo "ip_filter=bt_level1.gz,tbg_primarythreats.gz"             >> $PATH_rt
		echo "schedule = filter,18:30:00,24:00:00,reload_ip_filter="    >> $PATH_rt
		echo 'schedule = snub_leechers,120,120,"snub_leechers=10,5,1M"' >> $PATH_rt
		echo 'schedule = ban_slow_peers,120,120,"ban_slow_peers=5,2K,64K,5,128K,10,1M,30"' >> $PATH_rt
		echo 'on_finished = unban,"d.unban_peers="'                     >> $PATH_rt
		echo 'on_finished = unsnub,"d.unsnub_peers="'                   >> $PATH_rt
		echo "done_fg_color = 1" >> $PATH_rt
	fi
fi

[[ $alloc = 'y' ]] &&
	echo "system.file_allocate.set = yes" >> $PATH_rt  # Enable file pre-allocation

log "rTorrent Config | Created" ; log "rTorrent listening on port: $NUMBER"

if [[ $DISTRO = @([Uu]buntu|[dD]ebian|*Mint) && ! -f /etc/init.d/rtorrent ]]; then  # Copy init script
	cp modules/rtorrent/rtorrent-init /etc/init.d/rtorrent
	cp modules/rtorrent/rtorrent-init-conf "$HOME"/.rtorrent.init.conf

	# Write init configuration
	sed -i "s:user=:user=\"$USER\":"                      $HOME/.rtorrent.init.conf
	sed -i "s:base=:base=$HOME:"                          $HOME/.rtorrent.init.conf
	sed -i 's:config=:config=("$base/.rtorrent.rc"):'     $HOME/.rtorrent.init.conf
	sed -i "s:logfile=:logfile=$HOME/.rtorrent.init.log:" $HOME/.rtorrent.init.conf

	chmod a+x /etc/init.d/rtorrent && update-rc.d rtorrent defaults  # Start at boot
	 log "rTorrent Config | Installed \nrTorrent Init Script | Created"
else log "Previous rTorrent Init Script Found, skipping..."
fi
debug_wait "rtorrent.installed"
