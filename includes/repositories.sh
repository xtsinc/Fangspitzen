##!=====================>> REPOSiTORiES <<=======================!##
echo -e "\n********************************"
echo -e   "*****${bldred} ADDiNG REPOSiTORiES  ${rst}*****"
echo -e   "********************************\n"

if [[ "$DISTRO" = @([uU]buntu|[dD]ebian|*Mint) ]]; then
! is_installed "apt-key" && packages install apt
	if [[ "$DISTRO" = @([uU]buntu) ]]; then
		echo "deb http://archive.ubuntu.com/ubuntu/ "$NAME" multiverse"                > $REPO_PATH/multiverse.list  # non-free
		echo "deb-src http://archive.ubuntu.com/ubuntu/ "$NAME" multiverse"           >> $REPO_PATH/multiverse.list  # non-free
		echo "deb http://archive.ubuntu.com/ubuntu/ ${NAME}-updates multiverse"       >> $REPO_PATH/multiverse.list  # non-free
		echo "deb-src http://archive.ubuntu.com/ubuntu/ ${NAME}-updates multiverse"   >> $REPO_PATH/multiverse.list  # non-free

	elif [[ "$DISTRO" = @(Debian|*Mint) ]]; then
		if [[ "$NAME" = 'lenny' ]]; then  # Bascially updates to squeeze since packages are so old on lenny
			echo "deb http://ftp.debian.org/debian/ squeeze main non-free contrib"       >> /etc/apt/sources.list
			echo "deb http://security.debian.org/ squeeze/updates main non-free contrib" >> /etc/apt/sources.list
		else
			echo "deb http://ftp.debian.org/debian/ squeeze non-free contrib"            >> /etc/apt/sources.list
			echo "deb http://security.debian.org/ squeeze/updates non-free contrib"      >> /etc/apt/sources.list
		fi
	fi
	packages addrepo "ppa:cherokee-webserver/ppa" "EBA7BD49" # Cherokee
	packages addrepo "ppa:nginx/stable"           "C300EE8C" # Nginx (ppa:nginx/php5 is Broken)
	packages addrepo "ppa:brianmercer/php"        "8D0DC64F" # Nginx-PHP
	packages addrepo "ppa:stbuehler/ppa"          "5A43ED73" # Lighttp
	packages addrepo "ppa:deluge-team/ppa"        "249AD24C" # Deluge
	packages addrepo "ppa:transmissionbt/ppa"     "365C5CA1" # Transmission
	packages addrepo "ppa:ssakar/ppa"             "108B243F" # iPList
	packages addrepo "ppa:jcfp/ppa"               "4BB9F05F" # SABnzbd
	echo "deb http://download.virtualbox.org/virtualbox/debian "$NAME" non-free" >> $REPO_PATH/autoinstaller.list  # VirtualBox
	echo "deb http://download.webmin.com/download/repository sarge contrib"      >> $REPO_PATH/autoinstaller.list  # Webmin
	wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | apt-key add -
	wget -q http://www.webmin.com/jcameron-key.asc -O- | apt-key add -

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
echo $(date) > $BASE/.repos.installed
packages update
debug_wait "repos.added.and.updated"
clear
