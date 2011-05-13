cd $SOURCE_DIR
	notice "iNSTALLiNG DELUGE"
	if [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		build_from_aur "deluge" "deluge-git"
	else
		packages install deluge-common deluge-console deluge-web deluged
			if_error "Deluge failed to install"
	fi

	sudo -u $USER deluged && sleep 1
	sudo -u $USER killall deluged

	cp ../modules/deluge/deluge-daemon.defaults /etc/default/deluge-daemon  # Copy init config
	cp ../modules/deluge/deluge-daemon.init     /etc/init.d/deluge-daemon   # Copy init script
	echo
	read -p " WEBUi User Name: "   dUser
	read -p " WEBUi  Password: "   dPass

	echo "$dUser:$dPass:10" >> $HOME/.config/deluge/auth
	sed -i "s:DELUGED_USER=:DELUGED_USER=\"$USER\":" /etc/default/deluge-daemon  # Put UserName in script
	chmod a+x /etc/init.d/deluge-daemon && update-rc.d deluge-daemon defaults    # Start at boot

	log "Deluge Init Script Created"
	debug_wait "deluge.init.copied"
	
	NUMBER=$[($RANDOM % 65534) + 20000]  # Generate a random number from 20000-65534
	deluge_conf="$HOME/.config/deluge/core.conf"

	sed -i $deluge_conf \
		-e "s,\"move_completed\": .*,\"move_completed\": \"true\","                     \
		-e "s,\"move_completed_path\": .*,\"move_completed_path\": \"$HOME/Finished\"," \
		-e "s,\"download_location\": .*,\"download_location\": \"$HOME/downloads\","    \
		-e "s,\"autoadd_location\": .*,\"autoadd_location\": \"$HOME/watch\","          \
		-e "s,\"plugins_location\": .*,\"plugins_location\": \"$HOME/.config/deluge/plugins\"," \
		-e "s,\"max_active_limit\": .*,\"max_active_limit\": \"200\","                  \
		-e "s,\"max_active_downloading\": .*,\"max_active_downloading\": \"200\","      \
		-e "s,\"max_active_seeding\": .*,\"max_active_seeding\": \"200\","              \
		-e "s,\"allow_remote\": .*,\"allow_remote\": \"true\","                         \
		-e "s,\"dht\": .*,\"dht\": \"false\","                                          \
		-e "s:6881,:$NUMBER,:"                                                          \
		-e "s:6891,:$NUMBER:"

	chown -R $USER:$USER $HOME/.config/deluge

	sudo -u $USER deluged deluged
	sudo -u $USER deluged deluge-web

	log "Deluge Config | Created"
	log "Deluge WebUi listening on Port 8112"
	debug_wait "deluged.installed"
