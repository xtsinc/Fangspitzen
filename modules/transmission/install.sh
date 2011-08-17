cd $SOURCE_DIR
	notice "iNSTALLiNG TRANSMiSSiON"
	if [[ "$DISTRO" = @([Uu]buntu|[dD]ebian|*Mint) ]]; then
		packages addrepo "ppa:transmissionbt/ppa" "365C5CA1" && packages update
		packages install transmission-daemon transmission-common transmission-cli
		sed -i "s:USER=.*:USER=$USER:" /etc/init.d/transmission-daemon
		/etc/init.d/transmission-daemon restart && /etc/init.d/transmission-daemon stop
	elif [[ "$DISTRO" = @(SUSE|[Ss]use)* ]]; then
		packages addrepo "http://download.opensuse.org/repositories/filesharing/openSUSE_${RELEASE}/" "Transmission"
		packages update
		packages install transmission transmission-common
		sudo -u $USER transmission-daemon && sleep 2
		kill -u $USER $(pgrep transmission) && sleep 1
	elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		packages install transmission-cli
		echo "TRANS_USER=\"$USER\"" >> /etc/conf.d/transmissiond
		/etc/rc.d/transmissiond start && /etc/rc.d/transmissiond stop
		echo "/etc/rc.d/transmissiond start" >> /etc/rc.local
	fi
	if_error "Transmission failed to install"

	echo
	read -p " WEBUi User Name: " tUser
	read -p " WEBUi Password : " tPass

	PATH_tr=$HOME/.config/transmission-daemon/settings.json
	sed -i $PATH_tr \
		-e "s|\"blocklist-enabled.*|\"blocklist-enabled\": true,|" \
		-e "s|\"blocklist-url.*|\"blocklist-url\": \"http://www.bluetack.co.uk/config/level1.gz\",|" \
		-e "s|\"cache-size-mb.*|\"cache-size-mb\": 8,|"            \
		-e "s|\"open-file-limit.*|\"open-file-limit\": 64,|"       \
		-e "s|\"rpc-authentication-required.*|\"rpc-authentication-required\": true,|" \
		-e "s|\"rpc-password.*|\"rpc-password\": \"$tPass\",|"     \
		-e "s|\"rpc-username.*|\"rpc-username\": \"$tUser\",|"     \
		-e "s|\"rpc-whitelist.*|\"rpc-whitelist\": \"*.*.*.*\",|"

	[[ -d /etc/rc.d/ ]] && /etc/rc.d/transmissiond start || /etc/init.d/transmission-daemon start

	notice "http://code.google.com/p/transmisson-remote-gui  is recommened to access transmission remotely, instead of its built-in webui."
	log "Transmission Installation | Completed"
	log "WebUI is active on http://$IP:9091"
	debug_wait "transmission.installed"
