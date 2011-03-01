##!=====================>> REPOSiTORiES <<=======================!##
echo -e "\n********************************"
echo -e   "*****${bldred} ADDiNG REPOSiTORiES  ${rst}*****"
echo -e   "********************************\n"

if [[ "$DISTRO" = @([uU]buntu) ]]; then
	echo "deb http://archive.ubuntu.com/ubuntu/ "$NAME" multiverse"                > $REPO_PATH/multiverse.list  # non-free
	echo "deb-src http://archive.ubuntu.com/ubuntu/ "$NAME" multiverse"           >> $REPO_PATH/multiverse.list  # non-free
	echo "deb http://archive.ubuntu.com/ubuntu/ ${NAME}-updates multiverse"       >> $REPO_PATH/multiverse.list  # non-free
	echo "deb-src http://archive.ubuntu.com/ubuntu/ ${NAME}-updates multiverse"   >> $REPO_PATH/multiverse.list  # non-free

	echo "deb http://ppa.launchpad.net/cherokee-webserver/ppa/ubuntu "$NAME" main" > $REPO_PATH/autoinstaller.list  # Cherokee
	#echo "deb http://ppa.launchpad.net/cherokee-webserver/i-tse/ubuntu "$NAME" main" > $REPO_PATH/autoinstaller.list  # Uncomment for Unstable-Cherokee
	echo "deb http://ppa.launchpad.net/stbuehler/ppa/ubuntu "$NAME" main"         >> $REPO_PATH/autoinstaller.list  # Lighttp
	echo "deb http://ppa.launchpad.net/deluge-team/ppa/ubuntu "$NAME" main"       >> $REPO_PATH/autoinstaller.list  # Deluge
	echo "deb http://ppa.launchpad.net/transmissionbt/ppa/ubuntu "$NAME" main"    >> $REPO_PATH/autoinstaller.list  # Transmission
	echo "deb http://ppa.launchpad.net/ssakar/ppa/ubuntu "$NAME" main"            >> $REPO_PATH/autoinstaller.list  # iPList
	echo "deb http://ppa.launchpad.net/jcfp/ppa/ubuntu "$NAME" main"              >> $REPO_PATH/autoinstaller.list  # SABnzbd
	echo "deb http://download.virtualbox.org/virtualbox/debian "$NAME" non-free"  >> $REPO_PATH/autoinstaller.list  # VirtualBox
	echo "deb http://download.webmin.com/download/repository sarge contrib"       >> $REPO_PATH/autoinstaller.list  # Webmin
	log "Repositories ADD | Success"

elif [[ "$DISTRO" = @(Debian|*Mint) ]]; then
	if [[ "$NAME" = 'lenny' ]]; then  # Bascially updates to squeeze since packages are so old on lenny
#		touch /etc/apt/apt.conf
#		echo 'APT::Default-Release "stable";' >> /etc/apt/apt.conf  # Make lenny the default for package installation
#		echo "deb http://ftp.debian.org/debian/ lenny non-free contrib"              >> /etc/apt/sources.list
#		echo "deb http://security.debian.org/ lenny/updates non-free contrib"        >> /etc/apt/sources.list
		echo "deb http://ftp.debian.org/debian/ squeeze main non-free contrib"       >> /etc/apt/sources.list
		echo "deb http://security.debian.org/ squeeze/updates main non-free contrib" >> /etc/apt/sources.list
		echo "deb http://ppa.launchpad.net/stbuehler/ppa/ubuntu jaunty main"         >> $REPO_PATH/autoinstaller.list  # Lighttp
	#elif [[ "$NAME" = @(squeeze|debian) ]]; then  # 'debian' is used for mint debian releases
	else
		echo "deb http://ftp.debian.org/debian/ squeeze non-free contrib"            >> /etc/apt/sources.list
		echo "deb http://security.debian.org/ squeeze/updates non-free contrib"      >> /etc/apt/sources.list
	fi

	echo "deb http://ppa.launchpad.net/cherokee-webserver/ppa/ubuntu jaunty main"  > $REPO_PATH/autoinstaller.list  # Cherokee
	#echo "deb http://ppa.launchpad.net/cherokee-webserver/i-tse/ubuntu jaunty main" > $REPO_PATH/autoinstaller.list  # Uncomment for Unstable-Cherokee
	echo "deb http://ppa.launchpad.net/deluge-team/ppa/ubuntu karmic main"        >> $REPO_PATH/autoinstaller.list  # Deluge
	echo "deb http://ppa.launchpad.net/transmissionbt/ppa/ubuntu karmic main"     >> $REPO_PATH/autoinstaller.list  # Transmission
	echo "deb http://ppa.launchpad.net/ssakar/ppa/ubuntu karmic main"             >> $REPO_PATH/autoinstaller.list  # iPList
	echo "deb http://ppa.launchpad.net/jcfp/ppa/ubuntu jaunty main"               >> $REPO_PATH/autoinstaller.list  # SABnzbd
	echo "deb http://download.virtualbox.org/virtualbox/debian "$NAME" non-free"  >> $REPO_PATH/autoinstaller.list  # VirtualBox
	echo "deb http://download.webmin.com/download/repository sarge contrib"       >> $REPO_PATH/autoinstaller.list  # Webmin
	log "Repositories ADD | Success"

elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
	if [[ "$ARCH" = "x86_64" ]] && [[ ! $(grep '\[multilib\]' /etc/pacman.conf) || $(grep '#\[multilib\]' /etc/pacman.conf) ]]; then
		echo "[multilib]" >> /etc/pacman.conf
		echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
	fi
	log "Repositories ADD | Success"

elif [[ "$DISTRO" = @(SUSE|[Ss]use)* ]]; then
	packages addrepo http://download.opensuse.org/repositories/openSUSE:/11.3:/Contrib/standard/      "Contrib"
	packages addrepo http://ftp.uni-erlangen.de/pub/mirrors/packman/suse/11.3/                        "Packman"
	packages addrepo http://download.opensuse.org/repositories/Apache/openSUSE_11.3/                  "Apache"
	packages addrepo http://download.opensuse.org/repositories/Apache:/Modules/Apache_openSUSE_11.3/  "Apache-Modules"
	packages addrepo http://download.opensuse.org/repositories/server:/php/openSUSE_11.3/             "Apache-PHP"
	packages addrepo http://download.opensuse.org/repositories/server:/php:/extensions/openSUSE_11.3/ "PHP-Extensions"
	packages addrepo http://download.opensuse.org/repositories/server:/http/openSUSE_11.3/            "Cherokee"
	packages addrepo http://download.opensuse.org/repositories/filesharing/openSUSE_11.3/             "Transmission"
	packages addrepo http://download.opensuse.org/repositories/home:/uljanow/openSUSE_11.2/           "iPList"
	log "Repositories ADD | Success"
else
	error "Failed to add repositories to unknown distro... exiting (${DISTRO})"
fi
echo $(date) > $BASE/.repos.installed

##!=====================>> PUBLiC KEYS <<========================!##
if [[ "$DISTRO" = @([uU]buntu|[dD]ebian|*Mint) ]]; then  # Add signing keys
	packages addkey EBA7BD49
	packages addkey 5A43ED73
	packages addkey 249AD24C
	packages addkey 365C5CA1
	packages addkey 108B243F
	packages addkey 4BB9F05F
	wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | apt-key add -
	wget -q http://www.webmin.com/jcameron-key.asc -O- | apt-key add -
fi
debug_wait "repos.added"
clear
