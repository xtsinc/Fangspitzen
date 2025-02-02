##!===================>> Post Processing <<======================!##
echo -e "\n*******************************"
echo -e   "******${bldred} POST PROCESSiNG ${rst}********"
echo -e   "*******************************"

if [[ -f /etc/ssh/sshd_config && ! $(grep '#added by autoscript' /etc/ssh/sshd_config) ]]; then  # Check if this has already been done
	sed -i /etc/ssh/sshd_config \
		-e 's:[#]*Protocol .*:Protocol 2:'                       \
		-e 's:[#]*IgnoreRhosts no:IgnoreRhosts yes:'             \
		-e 's:[#]*PermitRootLogin yes:PermitRootLogin no:'       \
		-e 's:[#]*LoginGraceTime .*:LoginGraceTime 30:'          \
		-e 's:[#]*StrictModes no:StrictModes yes:'               \
		-e 's:[#]*ServerKeyBits .*:ServerKeyBits 1024:'          \
		-e 's:[#]*AllowTcpForwarding yes:AllowTcpForwarding no:' \
		-e 's:[#]*X11Forwarding yes:X11Forwarding no:'
	[[ $(grep "AllowUsers" /etc/ssh/sshd_config) ]] &&
		sed -e "/AllowUsers/s/$/ $USER/"                      -i /etc/ssh/sshd_config ||
		echo "AllowUsers $USER"                               >> /etc/ssh/sshd_config
	echo "#added by autoscript"                               >> /etc/ssh/sshd_config
	if [[ -d /etc/rc.d/ ]]  # restart ssh daemon
		then /etc/rc.d/sshd restart
	elif [[ -f /etc/init.d/ssh ]]
		then /etc/init.d/ssh restart
		else /etc/init.d/sshd restart
	fi
fi

if [[ ! $(grep '# added by autoscript' /etc/sysctl.conf) ]]; then  # Check if this has already been added or not
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
	sysctl -p  # Put changes into effect
fi

if [[ "$http" = 'apache' ]]; then  # Restart webserver
	[[ -d /etc/rc.d/ ]] &&
		/etc/rc.d/httpd restart || /etc/init.d/apache2 restart
elif [[ "$http" = 'lighttp' ]]; then
	[[ -d /etc/rc.d/ ]] &&
		/etc/rc.d/lighttpd restart || /etc/init.d/lighttpd restart
elif [[ "$http" = 'nginx' ]]; then
	[[ -d /etc/rc.d/ ]] &&
		/etc/rc.d/nginx restart || /etc/init.d/nginx restart
elif [[ "$http" = 'cherokee' ]]; then
	notice "Run [ sudo cherokee-admin -b ] to launch Cherokee's webinterface."
fi

if [[ $ftpd = 'vsftp' ]]; then  # Restart ftpserver
	[[ -d /etc/rc.d/ ]] &&
		/etc/rc.d/vsftpd restart || /etc/init.d/vsftpd restart
elif [[ $ftpd = 'proftp' ]]; then
	[[ -d /etc/rc.d/ ]] &&
		/etc/rc.d/proftpd restart || /etc/init.d/proftpd restart
elif [[ $ftpd = 'pureftp' ]]; then
	[[ -d /etc/rc.d/ ]] &&
		/etc/rc.d/pure-ftpd restart || /etc/init.d/pure-ftpd restart
fi

if [[ "$sql" = 'postgre' ]]; then
	post_ver=$(psql -V | head -n 1 | cut -c 19-21)
	post_conf=/etc/postgresql/$post_ver/main/postgresql.conf
	[[ "$DISTRO" = @(ARCH|[Aa]rch)* ]] && post_conf=/var/lib/postgres/data/postgresql.conf
	sed -i "s:#autovacuum .*:autovacuum = on:"     $post_conf
	sed -i "s:#track_counts .*:track_counts = on:" $post_conf
	[[ -d /etc/rc.d/ ]] &&
		/etc/rc.d/postgresql restart || /etc/init.d/postgresql restart
fi

if [[ $fail2ban = 'y' ]]; then
		echo -n "Restarting fail2ban..."
		killall -q -15 fail2ban-server ; sleep 2
		if [[ -e /var/run/fail2ban/fail2ban.sock ]]; then
			rm /var/run/fail2ban/fail2ban.sock
			/etc/init.d/fail2ban start
		fi ; echo " done"
fi

#[ Add Some Useful Command Alias' ]#
if [[ -f $HOME/.bashrc && ! $(grep '# added by autoscript' $HOME/.bashrc) ]]; then  # Check if this has already been added or not
cp $HOME/.bashrc $HOME/.bashrc.saved
echo "
#sudo completion
complete -cf sudo
#system
alias ls='ls -o -h --color=always --group-directories-first'
alias rm='rm -r'
alias mkdir='mkdir -p'
alias sizeof='du -sh'
alias killall='sudo killall'
alias grep='grep --color'
alias df='df -h -T --total'
#chmod
alias chx='chmod +x'
alias chfile='chmod 644'
alias chdir='chmod 755'
" > $HOME/.bashrc
	sed -i 's:force_color_prompt=no:force_color_prompt=yes:' $HOME/.bashrc
	echo "# added by autoscript">> $HOME/.bashrc
	echo "alias install='$alias_install'"     >> $HOME/.bashrc
	echo "alias remove='$alias_remove'"       >> $HOME/.bashrc
	echo "alias update='$alias_update'"       >> $HOME/.bashrc
	echo "alias upgrade='$alias_upgrade'"     >> $HOME/.bashrc
	echo "alias autoclean='$alias_autoclean'" >> $HOME/.bashrc
	if [[ "$torrent" = 'rtorrent' ]]; then
		echo "alias rtorrent-start='dtach -n .dtach/rtorrent rtorrent'" >> $HOME/.bashrc
		echo "alias rtorrent-resume='dtach -a .dtach/rtorrent'"         >> $HOME/.bashrc
	fi
fi

if [[ "$torrent" = 'rtorrent' ]]; then  # Start rtorrent
	echo ; read -p "Start rtorrent now? [y/n]: " start_rt
	if [[ "$start_rt" = 'y' ]]; then
		sudo -u "$USER" mkdir -p $HOME/.dtach ; rm -f $HOME/.dtach/rtorrent
		sudo -u "$USER" env TERM=linux dtach -n $HOME/.dtach/rtorrent rtorrent
		is_running "rtorrent" "$USER" &&
			echo -e "${bldgrn}[SUCCESS]${txtgrn}\n ${bldgrn}Resume:${txtgrn} dtach -a ~/.dtach/rtorrent\n ${bldgrn}Detach:${txtgrn} Ctrl-\\ ${rst}" ||
			echo -e "${bldred}[FAILURE]${txtred} rtorrent FAILED to start!${rst}"
	fi
fi

ldconfig
log "Linking Shared Libaries | Completed"

echo -en "\n${bldred} Cleaning up... ${rst}"
packages clean  # remove uneeded and cached packages
cleanup
echo -e "${bldylw} done${rst}"
