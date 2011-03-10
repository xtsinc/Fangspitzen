##!=====================>> REPOSiTORiES <<=======================!##
echo -e "\n********************************"
echo -e   "*****${bldred} ADDiNG REPOSiTORiES  ${rst}*****"
echo -e   "********************************\n"

if [[ "$DISTRO" = @([uU]buntu) ]]; then
	! is_installed "add-apt-repository" && packages install python-software-properties
	echo "deb http://archive.ubuntu.com/ubuntu/ "$NAME" multiverse"                > $REPO_PATH/multiverse.list  # non-free
	echo "deb-src http://archive.ubuntu.com/ubuntu/ "$NAME" multiverse"           >> $REPO_PATH/multiverse.list  # non-free
	echo "deb http://archive.ubuntu.com/ubuntu/ ${NAME}-updates multiverse"       >> $REPO_PATH/multiverse.list  # non-free
	echo "deb-src http://archive.ubuntu.com/ubuntu/ ${NAME}-updates multiverse"   >> $REPO_PATH/multiverse.list  # non-free

	packages addrepo "ppa:cherokee-webserver/ppa" # Cherokee
	packages addrepo "ppa:nginx/stable"           # Nginx (ppa:nginx/php5 is Broken)
	packages addrepo "ppa:brianmercer/php"        # Nginx-PHP
	packages addrepo "ppa:stbuehler/ppa"          # Lighttp
	packages addrepo "ppa:deluge-team/ppa"        # Deluge
	packages addrepo "ppa:transmissionbt/ppa"     # Transmission
	packages addrepo "ppa:ssakar/ppa"             # iPList
	packages addrepo "ppa:jcfp/ppa"               # SABnzbd
	
	echo "deb http://download.virtualbox.org/virtualbox/debian "$NAME" non-free"  >> $REPO_PATH/autoinstaller.list  # VirtualBox
	echo "deb http://download.webmin.com/download/repository sarge contrib"       >> $REPO_PATH/autoinstaller.list  # Webmin
	log "Repositories ADD | Success"

elif [[ "$DISTRO" = @(Debian|*Mint) ]]; then
	! is_installed "apt" && packages install apt
	if [[ "$NAME" = 'lenny' ]]; then  # Bascially updates to squeeze since packages are so old on lenny
#		touch /etc/apt/apt.conf
#		echo 'APT::Default-Release "stable";' >> /etc/apt/apt.conf  # Make lenny the default for package installation
#		echo "deb http://ftp.debian.org/debian/ lenny non-free contrib"              >> /etc/apt/sources.list
#		echo "deb http://security.debian.org/ lenny/updates non-free contrib"        >> /etc/apt/sources.list
		echo "deb http://ftp.debian.org/debian/ squeeze main non-free contrib"       >> /etc/apt/sources.list
		echo "deb http://security.debian.org/ squeeze/updates main non-free contrib" >> /etc/apt/sources.list
		echo "deb http://ppa.launchpad.net/stbuehler/ppa/ubuntu jaunty main"         >> $REPO_PATH/autoinstaller.list  # Lighttp
	else
		echo "deb http://ftp.debian.org/debian/ squeeze non-free contrib"            >> /etc/apt/sources.list
		echo "deb http://security.debian.org/ squeeze/updates non-free contrib"      >> /etc/apt/sources.list
	fi

	echo "deb http://ppa.launchpad.net/cherokee-webserver/ppa/ubuntu lucid main"  > $REPO_PATH/autoinstaller.list  # Cherokee
	echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu lucid main"           >> $REPO_PATH/autoinstaller.list  # Nginx
	echo "deb http://ppa.launchpad.net/brianmercer/php/ubuntu lucid main"        >> $REPO_PATH/autoinstaller.list  # Nginx-PHP
	echo "deb http://ppa.launchpad.net/deluge-team/ppa/ubuntu lucid main"        >> $REPO_PATH/autoinstaller.list  # Deluge
	echo "deb http://ppa.launchpad.net/transmissionbt/ppa/ubuntu lucid main"     >> $REPO_PATH/autoinstaller.list  # Transmission
	echo "deb http://ppa.launchpad.net/ssakar/ppa/ubuntu lucid main"             >> $REPO_PATH/autoinstaller.list  # iPList
	echo "deb http://ppa.launchpad.net/jcfp/ppa/ubuntu lucid main"               >> $REPO_PATH/autoinstaller.list  # SABnzbd
	echo "deb http://download.virtualbox.org/virtualbox/debian "$NAME" non-free" >> $REPO_PATH/autoinstaller.list  # VirtualBox
	echo "deb http://download.webmin.com/download/repository sarge contrib"      >> $REPO_PATH/autoinstaller.list  # Webmin
	packages addkey C300EE8C # Nginx
	packages addkey 8D0DC64F # Nginx-PHP
	packages addkey EBA7BD49 # Cherokee
	packages addkey 5A43ED73 # Lighttpd
	packages addkey 249AD24C # Deluge
	packages addkey 365C5CA1 # Transmission
	packages addkey 108B243F # iPList
	packages addkey 4BB9F05F # SABnzbd
	log "Repositories ADD | Success"

elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
	if [[ "$ARCH" = "x86_64" ]] && [[ ! $(grep '\[multilib\]' /etc/pacman.conf) || $(grep '#\[multilib\]' /etc/pacman.conf) ]]; then
		echo "[multilib]" >> /etc/pacman.conf
		echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
	fi
	log "Repositories ADD | Success"

elif [[ "$DISTRO" = @(SUSE|[Ss]use)* ]]; then
	! is_installed "zypper" && packages install zypper
	packages addrepo http://download.opensuse.org/repositories/openSUSE:/11.3:/Contrib/standard/      "Contrib"
	packages addrepo http://download.opensuse.org/repositories/network:/utilities/openSUSE_11.3/      "Axel"
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

##!=====================>> PUBLiC KEYS <<========================!##
if [[ "$DISTRO" = @([uU]buntu|[dD]ebian|*Mint) ]]; then  # Add signing keys
	wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | apt-key add -
	wget -q http://www.webmin.com/jcameron-key.asc -O- | apt-key add -
fi
packages update
debug_wait "repos.added.and.updated"
echo $(date) > $BASE/.repos.installed
clear
