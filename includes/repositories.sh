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

elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
	if [[ "$ARCH" = "x86_64" ]] && [[ ! $(grep '\[multilib\]' /etc/pacman.conf) || $(grep '#\[multilib\]' /etc/pacman.conf) ]]; then
		echo "[multilib]" >> /etc/pacman.conf
		echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
	fi
	log "Repositories ADD | Success"

elif [[ "$DISTRO" = @(SUSE|[Ss]use)* ]]; then
	! is_installed "zypper" && packages install zypper
	packages addrepo http://download.opensuse.org/repositories/openSUSE:/${RELEASE}:/Contrib/standard/      "Contrib"
	packages addrepo http://download.opensuse.org/repositories/network:/utilities/openSUSE_${RELEASE}/      "Axel"
	packages addrepo http://ftp.uni-erlangen.de/pub/mirrors/packman/suse/${RELEASE}/                        "Packman"
	packages addrepo http://download.opensuse.org/repositories/server:/php:/extensions/openSUSE_${RELEASE}/ "PHP-Extensions"
	log "Repositories ADD | Success"
else
	error "Failed to add repositories to unknown distro... exiting (${DISTRO})"
fi
echo $(date) > $BASE/.repos.installed
packages update
debug_wait "repos.added.and.updated"
clear
