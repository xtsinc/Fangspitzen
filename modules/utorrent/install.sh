if [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
	build_from_aur "utorrent-server"  # TODO depends on multilib repo is x64
else
	cd $HOME
	download http://download.utorrent.com/linux/utorrent-server-3.0-24118.tar.gz
		if_error "uTorrent Download Failed"
	extract utorrent-server-3.0-24118.tar.gz
	cd bittorrent-server-v3_0
	# TODO echo 'some_settings'       > utserver.conf
	# TODO echo 'some_more_settings' >> utserver.conf
fi

log "uTorrent-server installed | Run: ./utserver | http://your.ip:8080/gui | User: admin"
debug_wait "utorrent.installed"