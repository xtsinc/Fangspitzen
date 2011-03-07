#!/usr/bin/env bash
[[ $(uname -s) != "Linux" || $UID != 0 ]] && echo "Run with sudo" && exit

# Assumptions:
#	Apache or Lighttp using mod_auth_digest
#	/etc/apache2/.htpasswd, /etc/lighttpd/.htpasswd
#	/var/www/rutorrent/.htaccess
#
# You can, of course, change it below

	webserver='apache2'                     # apache, lighttpd  # Arch users enter 'httpd' for apache
	webuser='www-data'                      # webserver user
	htpasswd='/etc/apache2/.htpasswd'       # path to .htpasswd
	htaccess='/var/www/rutorrent/.htaccess' # path to .htaccess
	rutorrent='/var/www/rutorrent'          # path to rutorrent

init_variables()
{
	# Distributor -i > Ubuntu  > Debian  > Debian   > LinuxMint     > Arch  > SUSE LINUX  ($DISTRO)
	# Release     -r > 10.04   > 5.0.6   > 6.0      > 1|10          > n/a   > 11.3        ($RELASE)
	# Codename    -c > lucid   > lenny   > squeeze  > debian|julia  > n/a   > n/a         ($NAME)
	readonly DISTRO=$(lsb_release -is) RELEASE=$(lsb_release -rs) ARCH=$(uname -m) NAME=$(lsb_release -cs)
	user_name=''
	shell_reply=''
	declare -i scgi_port=0
	bldred='\e[1;31m'  # Red
	bldpur='\e[1;35m'  # Purple
	rst='\e[0m'        # Reset
}

assumption_check()
{
	ERROR=0
	[[ -f "$htpasswd" ]] &&
		echo -e "- htpasswd....[${bldpur} OK ${rst}]"   || {
		echo -e "- htpasswd....[${bldred} FAILED ${rst}]" && ERROR=1; }
	[[ -f "$htaccess" ]] &&
		echo -e "- htaccess....[${bldpur} OK ${rst}]"   || {
		echo -e "- htaccess....[${bldred} FAILED ${rst}]" && ERROR=2; }
	[[ -d "$rutorrent" ]] &&
		echo -e "- ruTorrent...[${bldpur} OK ${rst}]\n" || {
		echo -e "- ruTorrent...[${bldred} FAILED ${rst}]" && ERROR=3; }
	[[ $ERROR > 0 ]] && exit || echo ""
}

chown_rutorrent()
{
	[[ $(stat "$rutorrent" -c %U) != "$webuser" ]] &&
		chown -R "$webuser":"$webuser" "$rutorrent"
}

get_username()
{
	read -p "New User's Name: " user_name
	while [[ $(grep "^$user_name:" /etc/passwd) ]]; do
		echo -e "\n${bldred}- User Name Exists!${rst}"
		read -p "New User's Name: " user_name
	done
	read -p "Give shell access? [y|n]: " shell_reply
	if [[ "$shell_reply" = 'y' ]]
		then user_shell='/bin/bash' && sed -e "/AllowUsers/s/$/ $user_name/" -i /etc/ssh/sshd_config
		else user_shell='/usr/sbin/nologin'
	fi
}

create_user()
{
	useradd --create-home --shell "$user_shell" "$user_name"
	[[ $? = 0 ]] &&
		echo -e "\n${bldred}-${rst} System User .........[${bldpur} CREATED ${rst}]" ||
		echo -e "\n${bldred}-${rst} System User .........[${bldred} FAILED ${rst}]"
	echo
	passwd $user_name

	[[ $? = 0 ]] &&
		echo -e "\n${bldred}-${rst} User Password .......[${bldpur} CREATED ${rst}]" ||
		echo -e "\n${bldred}-${rst} User Password .......[${bldred} FAILED ${rst}]"
}

make_rtorrent_rc()
{
	cd /home/$user_name
	sudo -u $user_name mkdir downloads
	sudo -u $user_name mkdir .session
	chmod 750 downloads .session
	cat > .rtorrent.rc << "EOF"
max_peers = 50
max_peers_seed = 50
max_uploads = 250
download_rate = 12288
upload_rate = 12288
port_random = no
check_hash = no
hash_read_ahead = 32
hash_interval = 10
hash_max_tries = 5
schedule = low_diskspace,5,60,close_low_diskspace=100M
use_udp_trackers = yes
dht = off
encoding_list = UTF-8
encryption = allow_incoming,try_outgoing,enable_retry
#schedule = watch_directory,5,5,load_start=/absolute/path/to/watch/*.torrent
EOF
chmod 440 .rtorrent.rc

	listen_port=$[($RANDOM % 65534) + 20000]  # Generates a random number from 20000-65534
	echo "port_range = ${listen_port}-${listen_port}"       >> .rtorrent.rc
	echo "directory = /home/$user_name/downloads" >> .rtorrent.rc
	echo "session = /home/$user_name/.session"    >> .rtorrent.rc

	echo -e "${bldred}-${rst} rTorrent Config .....[${bldpur} CREATED ${rst}]"
	echo -e "${bldred}-${rst} rTorrent Port .......[${bldpur} $listen_port ${rst}]\n"
}

make_rtorrent_init()
{
	if [[ -f /etc/init.d/rtorrent ]]; then
		sudo -u $user_name echo "user=$user_name"                              > .rtorrent.init.conf
		sudo -u $user_name echo "base=/home/$user_name"                       >> .rtorrent.init.conf
		sudo -u $user_name echo "config=(\"\$base/.rtorrent.rc\")"            >> .rtorrent.init.conf
		sudo -u $user_name echo "logfile=/home/$user_name/.rtorrent.init.log" >> .rtorrent.init.conf
		echo -e "${bldred}-${rst} rTorrent Init Script.[${bldpur} CREATED ${rst}]\n"
	else echo -e "${bldred}-${rst} rTorrent Init Script.[${bldpur} SKIPPED ${rst}]\n"
	fi
}

make_rutorrent_conf()
{
	cd $rutorrent/conf
	sudo -u $webuser mkdir users/$user_name
	sudo -u $webuser cp config.php users/$user_name
	if ! [[ $(grep -A 1 "\[rpc\]" $rutorrent/conf/plugins.ini | grep "enabled = yes") || $(grep -A 1 "\[httprpc\]" $rutorrent/conf/plugins.ini | grep "enabled = yes") ]]; then
		get_scgi_port
		httpd_add_scgi
		sudo -u $webuser sed -i "s:\$scgi_port .*:\$scgi_port = $scgi_port;:"                    users/$user_name/config.php
		sudo -u $webuser sed -i "s:\$XMLRPCMountPoint .*:\$XMLRPCMountPoint = \"$scgi_mount\";:" users/$user_name/config.php
	fi
	sudo -u $webuser cat >> users/$user_name/access.ini << "EOF"
[settings]
showDownloadsPage = no
showConnectionPage = no
showBittorentPage = no
showAdvancedPage = no
[tabs]
showPluginsTab = no
[statusbar]
canChangeULRate = no
canChangeDLRate = no
[dialogs]
canChangeTorrentProperties = yes
EOF
	echo -e "${bldred}-${rst} ruTorrent Config ....[${bldpur} CREATED ${rst}]\n"

	htdigest $htpasswd "ruTorrent" $user_name
	[[ $? = 0 ]] &&
		echo -e "\n${bldred}-${rst} ruTorrent Password ..[${bldpur} CREATED ${rst}]" ||
		echo -e "\n${bldred}-${rst} ruTorrent Password ..[${bldred} FAILED ${rst}]"
}

get_scgi_port()
{
	scgi_mount="/rutorrent/$user_name"
	read -p "SCGi Port: " scgi_port

	while [[ $scgi_port -lt 1024 || $scgi_port -gt 65535 || $scgi_port -eq 5000 ]]; do
		echo -e "\n${bldred}- Invalid Port${rst}"
		read -p "SCGi Port: " scgi_port
	done
}

httpd_add_scgi()
{
	if [[ $webserver = 'apache2' ]]; then
		echo "SCGIMount $scgi_mount 127.0.0.1:$scgi_port" >> /etc/apache2/mods-available/scgi.conf
	elif [[ $webserver = 'httpd' ]]; then
		echo "SCGIMount $scgi_mount 127.0.0.1:$scgi_port" >> /etc/httpd/conf/httpd.conf
	elif [[ $webserver = 'lighttpd' ]]; then
		sed -i "s:),:),\n\t\"/rutorrent/$user_name\" =>\n\t( \n\t\t\"127.0.0.1\" =>\n\t\t(\n\t\t\"host\"         => \"127.0.0.1\",\n\t\t\"port\"         => $scgi_port,\n\t\t\"check-local\"  => \"disable\",\n\t\t)\n\t):" /etc/lighttpd/conf-available/20-scgi.conf
	fi
	sudo -u $user_name echo "scgi_port = localhost:$scgi_port" >> /home/$user_name/.rtorrent.rc
	echo -e "${bldred}-${rst} SCGi Mount ..........[${bldpur} CREATED ${rst}]"
	echo -e "${bldred}-${rst} SCGi Port ...........[${bldpur} $scgi_port ${rst}]\n"
}

restart_services()
{
	echo -en "\n${bldred}-${rst} Restarting HTTP/SSH .["
	[[ -d /etc/rc.d/ ]] &&
		/etc/rc.d/sshd restart >&/dev/null &&
		/etc/rc.d/$webserver restart >&/dev/null 

	if [[ -d /etc/init.d ]]; then
		/etc/init.d/$webserver restart >&/dev/null 
	[[ -f /etc/init.d/sshd ]] &&
		/etc/init.d/sshd restart >&/dev/null ||
		/etc/init.d/ssh restart >&/dev/null 
	fi
	echo -e "${bldpur} DONE ${rst}]"
}

start_rtorrent()
{
	echo ; read -p "Start rtorrent for $user_name? [y|n]: " start_rt
	if [[ $start_rt = 'y' ]]; then
		echo -en "${bldred}-${rst} rTorrent Starting ...["
		sudo -u $user_name "mkdir -p /home/$user_name/.dtach"
		sudo -u $user_name "env TERM=linux dtach -n /home/$user_name/.dtach/rtorrent rtorrent"

		[[ ! -z $(pgrep -u $user_name rtorrent) ]] &&
			echo -e "${bldpur} SUCCESS ${rst}]" ||
			echo -e "${bldred} FAiLED ${rst}]"
	fi
}

##[ Main ]##
init_variables        # create some variables
assumption_check      # check if our paths are correct 
chown_rutorrent       # make sure rutorrent is writeable by our webserver
get_username          # get username and if it can have shell access
create_user           # do useradd
make_rtorrent_rc      # create new user's .rtorrent.rc
make_rtorrent_init    # if using rtorrent init script, add config for this user
make_rutorrent_conf   # add new user to rutorrent
restart_services      # restart webserver and ssh
start_rtorrent        # start rtorrent under new user
