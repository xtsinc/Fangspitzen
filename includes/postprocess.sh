##!===================>> Post Processing <<======================!##
echo -e "\n*******************************"
echo -e   "******${bldred} POST PROCESSiNG ${rst}********"
echo -e   "*******************************\n"

if [[ -f /etc/ssh/sshd_config ]]; then
	sed -i 's:Protocol .*:Protocol 2:'                       /etc/ssh/sshd_config
	sed -i 's:IgnoreRhosts no:IgnoreRhosts yes:'             /etc/ssh/sshd_config
	sed -i 's:PermitRootLogin yes:PermitRootLogin no:'       /etc/ssh/sshd_config
	sed -i 's:LoginGraceTime 120:LoginGraceTime 30:'         /etc/ssh/sshd_config
	sed -i 's:StrictModes no:StrictModes yes:'               /etc/ssh/sshd_config
	sed -i 's:ServerKeyBits .*:ServerKeyBits 1024:'          /etc/ssh/sshd_config
	sed -i 's:AllowTcpForwarding yes:AllowTcpForwarding no:' /etc/ssh/sshd_config
	sed -i 's:X11Forwarding yes:X11Forwarding no:'           /etc/ssh/sshd_config
	if [[ -f /etc/init.d/ssh ]]; then /etc/init.d/ssh restart
	elif [[ -f /etc/init.d/sshd ]]; then /etc/init.d/sshd restart
	fi
fi

cat /etc/sysctl.conf | grep '# added by autoscript' >/dev/null
if [[ "$?" != 0 ]]; then  # Check if this has already been added or not
	echo '# added by autoscript' >> /etc/sysctl.conf
	echo 'kernel.exec-shield=1'                    >> /etc/sysctl.conf  # Turn on execshield
	echo 'kernel.randomize_va_space=1'             >> /etc/sysctl.conf
	echo 'net.ipv4.conf.all.rp_filter=1'           >> /etc/sysctl.conf  # Enable IP spoofing protection
	echo 'net.ipv4.conf.all.accept_source_route=0' >> /etc/sysctl.conf  # Disable IP source routing
	echo 'net.ipv4.icmp_echo_ignore_broadcasts=1'  >> /etc/sysctl.conf  # Ignoring broadcasts request
	echo 'net.ipv4.conf.all.log_martians=1'        >> /etc/sysctl.conf  # Make sure spoofed packets get logged
	echo 'net.ipv4.tcp_syncookies=1'               >> /etc/sysctl.conf  # Prevent against the common 'syn flood attack'
	echo 'vm.dirty_background_ratio=20'            >> /etc/sysctl.conf  # Less frequent writeback flushes
	echo 'vm.swappiness=5'                         >> /etc/sysctl.conf  # Very low use of swapfile
	echo 'net.core.wmem_max=12582912'              >> /etc/sysctl.conf  # Set the max send buffer (wmem) and receive buffer (rmem) size to 12 MB for queues on all protocols
	echo 'net.core.rmem_max=12582912'              >> /etc/sysctl.conf
	echo 'net.ipv4.tcp_rmem=10240 87380 12582912'  >> /etc/sysctl.conf  # Set minimum size, initial size, and maximum size in bytes
	echo 'net.ipv4.tcp_wmem=10240 87380 12582912'  >> /etc/sysctl.conf
	echo 'net.ipv4.tcp_window_scaling=1'           >> /etc/sysctl.conf  # Enlarge the transfer window
	echo 'net.ipv4.tcp_timestamps=1'               >> /etc/sysctl.conf  # Enable timestamps
	echo 'net.ipv4.tcp_sack=1'                     >> /etc/sysctl.conf  # Enable select acknowledgments
	echo 'net.core.netdev_max_backlog=5000'        >> /etc/sysctl.conf  # Maximum number of packets, queued on INPUT
	sysctl -p
fi

if [[ "$http" = 'apache'   ]]; then
	if [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		/etc/rc.d/httpd restart
	else /etc/init.d/apache2 restart
	fi
elif [[ "$http" = 'lighttp'  ]]; then
	/etc/init.d/lighttpd restart
elif [[ "$http" = 'cherokee' ]]; then
	notice "Run sudo cherokee-admin -b to configure Cherokee."
fi

[[ "$sql" = 'mysql' ]] &&
	/etc/init.d/mysql restart

if [[ "$sql" = 'postgre' ]]; then  # This needs to change per version
	post_ver=8.4
	[[ "$NAME" = 'lenny' ]] &&
		post_ver=8.3
	post_conf=/etc/postgresql/${post_ver}/main/postgresql.conf
	sed -i "s:#autovacuum .*:autovacuum = on:"     $post_conf
	sed -i "s:#track_counts .*:track_counts = on:" $post_conf
	/etc/init.d/postgresql-${post_ver} restart
fi

#[ Add Some Useful Command Alias' ]#
if [[ -f ${HOME}/.bashrc ]];then
	cat ${HOME}/.bashrc | grep '# added by autoscript' >/dev/null
if [[ "$?" != 0 ]]; then  # Check if this has already been added or not
	sed -i 's:force_color_prompt=no:force_color_prompt=yes:' ${HOME}/.bashrc
	echo "# added by autoscript">> ${HOME}/.bashrc
	echo "alias install='$alias_install'"     >> ${HOME}/.bashrc
	echo "alias remove='$alias_remove'"       >> ${HOME}/.bashrc
	echo "alias update='$alias_update'"       >> ${HOME}/.bashrc
	echo "alias upgrade='$alias_upgrade'"     >> ${HOME}/.bashrc
	echo "alias autoclean='$alias_autoclean'" >> ${HOME}/.bashrc
	
	if [[ "$torrent" = 'rtorrent' ]];then
		echo "alias rtorrent-start='dtach -n .dtach/rtorrent rtorrent'" >> ${HOME}/.bashrc
		echo "alias rtorrent-resume='dtach -a .dtach/rtorrent'"         >> ${HOME}/.bashrc
	fi
fi  # end `if $?`
fi

if [[ "$torrent" = 'rtorrent' ]]; then
echo ; read -p "Start rtorrent now? [y/n]: " start_rt
	if [[ "$start_rt" = 'y' ]]; then
		mkdir -p ${HOME}/.dtach ; rm -f ${HOME}/.dtach/rtorrent
		chmod -R 755 ${HOME}/.dtach
		chown -R "$USER" ${HOME}/.dtach
		sudo -u "$USER" dtach -n /home/${USER}/.dtach/rtorrent rtorrent

		TESTrt=$(pgrep -u "$USER" rtorrent)
		[[ "$?" = 0 ]] &&
			echo "rTorrent has been started with dtach in ~/.dtach/rtorrent" ||
			echo "rtorrent FAILED to start!"
	fi
fi

ldconfig
log "Linking Shared Libaries | Completed"

echo -en "\n${bldred} Cleaning up... ${rst}"
packages clean  # remove uneeded and cached packages
cleanup
echo -e "${bldylw} done${rst}"
