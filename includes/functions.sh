##!=======================>> FUNCTiONS <<=======================!##
base_configure() {  # do this before base_install()
ARCHLINUX_PRE="pacman-color perl-crypt-ssleay powerpill yaourt"

	case "$DISTRO" in
		# [uU]buntu|[Dd]ebian|*Mint) ;;
		# SUSE*|[Ss]use* ) ;;
		ARCH*|[Aa]rch* ) packages install $ARCHLINUX_PRE
					echo -en "${bldred} CONFiGURiNG PACKAGE MANAGER...${rst}"
						 sed -i "s:#USECOLOR=.*:USERCOLOR=1:"                       /etc/yaourtrc           # use color
						 sed -i "s:[#]*PACMAN=.*:PACMAN=powerpill:"                 /etc/yaourtrc           # tell yaourt to use powerpill
						 sed -i "s:PacmanBin=.*:PacmanBin = /usr/bin/pacman-color:" /etc/powerpill.conf ;;  # tell powerpill to use pacman-color
					echo -e "${bldylw} done${rst}"
	esac
	log "Base Configuration | Completed"
}

base_install() {  # install dependencies
COMMON="apache2-utils autoconf automake binutils bzip2 ca-certificates cpp curl file gamin gcc git-core gzip htop iptables libexpat1 libtool libxml2 m4 make openssl patch perl pkg-config python python-gamin python-openssl python-setuptools rsync screen subversion sudo unrar unzip zip"
DYNAMIC="libcurl3 libcurl3-gnutls libcurl4-openssl-dev libncurses5 libncurses5-dev libsigc++-2.0-dev"

DEBIAN="$COMMON $DYNAMIC aptitude autotools-dev build-essential cfv comerr-dev dtach g++ libcppunit-dev libperl-dev libssl-dev libterm-readline-gnu-perl libtorrent-rasterbar-dev ncurses-base ncurses-bin ncurses-term perl-modules ssl-cert"
SUSE="$COMMON libcppunit-devel libcurl-devel libopenssl-devel libtorrent-rasterbar-devel gcc-c++ ncurses-devel libncurses6 libsigc++2-devel"

ARCHLINUX="base-devel binutils curl dtach freetype2 geoip libsigc++ libmcrypt libxslt ncurses openssl perl perl-xml-libxml perl-digest-sha1 perl-html-parser perl-json perl-json-xs perl-xml-libxslt perl-net-ssleay pcre popt rsync subversion sudo t1lib unrar unzip"

PHP_COMMON="php5-curl php5-gd php5-mcrypt php5-mysql php5-suhosin php5-xmlrpc"

PHP_DEBIAN="$PHP_COMMON php5-cgi php5-cli php5-common php5-dev php5-mhash"  # php5-json is provided by php5-common
PHP_SUSE="$PHP_COMMON php5-devel php5-json"
PHP_ARCHLINUX="php php-cgi"  # TODO

	echo -en "${bldred} iNSTALLiNG BASE PACKAGES, this may take a while...${rst}"
	case "$DISTRO" in
		[uU]buntu|[Dd]ebian|*Mint) packages install $DEBIAN    ;;
		ARCH*|[Aa]rch* ) packages install $ARCHLINUX ;;
		SUSE*|[Ss]use* ) packages install $SUSE
						 if [[ ! -f /usr/bin/dtach ]]; then
							cd ${BASE}/tmp
							download http://sourceforge.net/projects/dtach/files/dtach/0.8/dtach-0.8.tar.gz && extract dtach-0.8.tar.gz
							cd dtach-0.8 && sh configure && make && cp dtach /usr/bin
						 fi ;;
	esac
	if_error "Required system packages failed to install"
	log "Base Installation | Completed"
	echo -e "${bldylw} done${rst}"
}

checkout() {  # increase verbosity
	if [[ "$DEBUG" = 1 ]]; then svn co "$@" ; E_=$?
	else svn co -q "$@" ; E_=$?
	fi	
}

cleanup() {  # remove tmp folder and restore permissions
	cd "$BASE" && rm --recursive --force tmp
	chown -R "$USER:$USER" "$BASE"
	log "Removed tmp/ folder"
}

clear_logfile() {  # clear the logfile
	[[ -f "$LOG" ]] && mv "$LOG" "${LOG}.bak"
}

compile() {  # compile with num of threads as cpu cores and time it
	compile_time="$SECONDS"
	make -j"$CORES" "$@" ; E_=$?
	let compile_time=${SECONDS}-${compile_time}
}

ctrl_c() {  # interrupt trap
	log "CTRL-C : abnormal exit detected..."
	echo -en "\n Cleaning up and exiting..."
	cleanup
	echo -e " done \n"
	exit 0
}

debug_wait() {  # prints a message and wait for user before continuing
	if [[ "$DEBUG" = '1' ]]; then
		echo -e "${bldpur} DEBUG: $1"
		echo -en "${bldpur} Press Enter...${rst}"
		read ENTER
	fi
}

download() {  # show progress bars if debug is on
	if [[ "$DEBUG" = 1 ]]; then
		 wget --no-verbose $1 ; E_=$?
	else wget --quiet $1      ; E_=$?
	fi
}

error() {  # call this when you know there will be an error
	echo -e " Error:${bldred} $1 ${rst} \n" ;exit 1
}

extract() {  # find type of compression and extract accordingly
	case "$1" in
		*.tar.bz2) tar xjf    "$1" ;;
		*.tbz2   ) tar xjf    "$1" ;;
		*.tar.gz ) tar xzf    "$1" ;;
		*.tgz    ) tar xzf    "$1" ;;
		*.tar    ) tar xf     "$1" ;;
		*.gz     ) gunzip -q  "$1" ;;
		*.bz2    ) bunzip2 -q "$1" ;;
		*.rar    ) unrar x    "$1" ;;
		*.zip    ) unzip      "$1" ;;
		*.Z      ) uncompress "$1" ;;
		*.7z     ) 7z x       "$1" ;;
	esac
}

if_error() {  # call this to catch a bad return code and log the error
	if [[ "$E_" != 0 && "$E_" != 100 ]]; then
		echo -e " Error:${bldred} $1 ${rst} ($E_)"
		log "Error: $1 ($E_)"
		cleanup ; exit 1
	fi
}

log() {  # send to the logfile
	echo -e "$1" >> "$LOG"
}

mkpass() {  # generate a random password of user defined length
	newPass=$(tr -cd '[:alnum:]' < /dev/urandom | head -c ${1:-${passwdlength}})
	notice "$newPass" ;exit 0
}

mksslcert() {  # use 2048 bit certs, use sha256, and regenerate
	if [[ "$1" = 'generate-default-snakeoil' ]]; then  # do once and only once
		sed -i 's:default_bits .*:default_bits = 2048:' /etc/ssl/openssl.cnf
		sed -i 's:default_md .*:default_md = sha256:'   /etc/ssl/openssl.cnf
		if [[ -x /usr/sbin/make-ssl-cert ]]; then
			echo -en "${bldred} Generating SSL Certificate...${rst}"
			sed -i 's:default_bits .*:default_bits = 2048:' $SSLCERT
			make-ssl-cert $1 --force-overwrite
			echo -e "${bldylw} done${rst}"
			log "mksslcert() completed"
		fi
		MKSSLCERT_RUN=0
	else
		[[ "$#" = 1 ]] && openssl req -new -x509 -days 3650 -nodes -out "$1" -keyout "$1" -subj '/C=AN/ST=ON/L=YM/O=OU/CN=S/emailAddress=dev@slash.null'  # generate single key file
		[[ "$#" = 2 ]] && openssl req -new -x509 -days 3650 -nodes -out "$1" -keyout "$2" -subj '/C=AN/ST=ON/L=YM/O=OU/CN=S/emailAddress=dev@slash.null'  # 2nd arg creates separate .pem and .key files
		chmod 400 "$@"  # Read write permission for owner only
		log "mksslcert() completed"
	fi
}

notice() {  # echo status or general info to stdout
	echo -en "\n${bldred} $1... ${rst}\n"
}

packages() {  # use appropriate package manager depending on distro
	if [[ "$DISTRO" = @(Ubuntu|[dD]ebian|*Mint) ]]; then
		[[ "$DEBUG" = 0 ]] && quiet="-qq" || quiet=
		case "$1" in
			addkey ) apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $2 ;;
			clean  ) apt-get $quiet autoclean                                    ;;
			install) shift; apt-get install --yes $quiet $@ 2>> $LOG; E_=$?      ;;
			remove ) shift; apt-get autoremove --yes $quiet $@ 2>> $LOG; E_=$?   ;;
			update ) apt-get update $quiet                                       ;;
			upgrade) apt-get upgrade --yes $quiet                                ;;
			version) aptitude show $2 | grep Version:                            ;;
			setvars)
				REPO_PATH=/etc/apt/sources.list.d 
				alias_autoclean="sudo apt-get autoremove && sudo apt-get autoclean"
				alias_install="sudo apt-get install"
				alias_remove="sudo apt-get autoremove"
				alias_update="sudo apt-get update"
				alias_upgrade="sudo apt-get upgrade" ;;
		esac
	elif [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
		noconfirm="--pacman-noconfirm"
		[[ "$DEBUG" = 0 ]] && quiet="--quiet" || quiet=
		case "$1" in
			clean  ) powerpill --sync --clean $quiet -c $noconfirm ; pacman-optimize       ;;
			install) shift; powerpill --sync $quiet $noconfirm $@ --needed 2>> $LOG; E_=$? ;;
			remove ) shift; powerpill --remove $@ 2>> $LOG; E_=$?                          ;;
			update ) powerpill --sync --refresh $quiet                                     ;;
			upgrade) powerpill --sync --refresh --sysupgrade $quiet $noconfirm             ;;
			version) powerpill -Si $2 | grep Version                                       ;;
			setvars)
				REPO_PATH=/etc/pacman.conf
				WEB=/srv/http
				WEBUSER='http'
				WEBGROUP='http'
				alias_autoclean="sudo powerpill -Scc"
				alias_install="sudo powerpill -S"
				alias_remove="sudo powerpill -R"
				alias_update="sudo powerpill -Sy"
				alias_upgrade="sudo powerpill -Syu" ;;
		esac
	elif [[ $DISTRO = @(SUSE|[Ss]use)* ]]; then
		[[ "$DEBUG" = 0 ]] && quiet="--quiet" || quiet=
		case "$1" in
			addrepo) shift; zypper --no-gpg-checks addrepo --refresh $@ 2>> $LOG       ;;
			clean  ) zypper $quiet clean                                               ;;
			install) shift; zypper $quiet --non-interactive install $@ 2>> $LOG; E_=$? ;;
			remove ) shift; zypper $quiet remove $@ 2>> $LOG; E_=$?                    ;;
			update ) zypper $quiet refresh                                             ;;
			upgrade) zypper $quiet --non-interactive update --auto-agree-with-licenses ;;
			version) zypper info $2 | grep Version:                                    ;;
			setvars)
				REPO_PATH=/etc/zypp/repos.d
				WEB=/srv/www/htdocs
				WEBUSER='wwwrun'
				WEBGROUP='www'
				alias_autoclean="sudo zypper clean"
				alias_install="sudo zypper install"
				alias_remove="sudo zypper remove"
				alias_update="sudo zypper refresh"
				alias_upgrade="sudo zypper update" ;;
		esac

	elif [[ "$DISTRO" = "Fedora" ]]; then
		[[ "$DEBUG" = 0 ]] && quiet="-e 0" || quiet=
		case "$1" in
			clean  ) yum clean all -y                                ;;
			install) shift; yum install $quiet -y $@ 2>> $LOG; E_=$? ;;
			remove ) shift; yum remove $quiet -y $@ 2>> $LOG; E_=$?  ;;
			update ) yum check-update -y                             ;;
			upgrade) yum upgrade -y                                  ;;
			version) yum info $2 | grep Version:                     ;;
			setvars)
				REPO_PATH=/etc/yum/repos.d
				alias_autoclean="sudo yum clean all"
				alias_install="sudo yum install"
				alias_remove="sudo yum remove"
				alias_update="sudo yum check-update"
				alias_upgrade="sudo yum upgrade" ;;
		esac

	elif [[ "$DISTRO" = "Gentoo" ]]; then
		[[ "$DEBUG" = 0 ]] && quiet="--quiet" || quiet=
		case "$1" in
			clean  ) emerge --clean                                        ;;
			install) shift; emerge $quiet --jobs=$CORES $@ 2>> $LOG; E_=$? ;;
			remove ) shift; emerge --unmerge $quiet $@ 2>> $LOG; E=$?      ;;
			update ) emerge --sync                                         ;;
			upgrade) emerge --update world $quiet                          ;;
			version) emerge -S or emerge -pv                               ;;
			setvars)
				REPO_PATH=/etc/portage/repos.conf  # TODO
				alias_autoclean="sudo emerge --clean"
				alias_install="sudo emerge"
				alias_remove="sudo emerge -C"
				alias_update="sudo emerge --sync"
				alias_upgrade="sudo emerge -u world" ;;
		esac
	fi
}

runchecks() {
	clear
	if [[ -f config.ini ]]; then  # Find Config and Load it
		source config.ini || error "while loading config.ini"
		[[ "$iDiDNTEDiTMYCONFiG" ]] && error "PLEASE EDiT THE CONFiG"  # Die if it hasnt been edited
		[[ "$PWD" != "$BASE"     ]] && error "Does not match $BASE "   # Check if the user declared BASE correctly in the config
	else error "config.ini not found!"  # Cant continue without a config so produce an error and exit
	fi
	echo -n ">>> Checking Requires..."
		[[ "$BASH_VERSION" = 4* ]] ||  # Check for bash verion 4+
			error "Please install package: bash, version 4.0 or higher. (Current: $(bash --version | head -n1 | cut -c 1-23))"
		[[ -x /usr/bin/lsb_release ]] ||  # Check if lsb-release is installed
			error "Please install package: lsb-release"
	echo -e "[${bldylw} OK ${rst}]"
	[[ "$UID" = 0 ]] &&  # Check if user is root
		echo -e ">>> User Check .........[${bldylw} OK ${rst}]" ||
		error "PLEASE RUN WITH SUDO"
	[[ "$DEBUG" = 1 ]] &&  # Check if debug is on/off
		echo -e ">>> Debug Mode .........[${bldylw} ON ${rst}]" ||
		echo -e ">>> Debug Mode .........[${bldylw} OFF ${rst}]"

	LOG=$BASE/logs/installer.log
	mkdir --parents logs/ ; touch $LOG
	log "runchecks() completed" ; sleep 1
}

spanner() {
	SP_COUNT=0
	while [[ -d /proc/$1 ]]; do
		while [[ "$SP_COUNT" -lt 10 ]]; do
			echo -en "${bldpur}\b+ " ;sleep 0.1
			((SP_COUNT++))
		done
		until [[ "$SP_COUNT" -eq 0 ]]; do
			echo -en "\b\b ${rst}" ;sleep 0.1
			((SP_COUNT -= 1))
		done
	done
}

spinner() {
	SP_WIDTH=0.1
	SP_STRING=".o0Oo"
	while [[ -d /proc/$1 ]]; do
		printf "${bldpur}\e7  %${SP_WIDTH}s  \e8${rst}" "$SP_STRING"
		sleep 0.2
		SP_STRING=${SP_STRING#"${SP_STRING%?}"}${SP_STRING%?}
	done
}

usage() {  # help screen
	echo -e "\n${bldpur} Usage:${bldred} "$0" ${bldpur}[${bldred}option${bldpur}]"
	echo -e " Options:"
	echo -e " ${bldred}  -p,  --pass ${bldpur}[${bldred}length${bldpur}] ${bldylw}   Generate a strong password"
	echo -e " ${bldred}  -v,  --version ${bldylw}         Show version number\n ${rst}"
	exit 1
}

yes() {  # user input for yes or no
	while read line; do
	case "$line" in
		y|Y|Yes|YES|yes) return 0 ;;
		n|N|No|NO|no) return 1 ;;
		*) echo -en " Please enter ${undrln}y${rst} or ${undrln}y${rst}: " ;;
	esac;done
}

init() {
	clear ; echo -n ">>> iNiTiALiZiNG......"
	OS=$(uname -s)

	##[ Determine OS ]##
if [[ "$OS" = "Linux" ]] ; then
	[[ -f /etc/fedora-release ]] && error "TODO - Fedora"
	[[ -f /etc/gentoo-release ]] && error "TODO - Gentoo"

	# Distributor -i > Ubuntu  > Debian  > Debian   > LinuxMint     > Arch  > SUSE LINUX  (DISTRO)
	# Release     -r > 10.04   > 5.0.6   > testing  > 1|10          > n/a   > 11.3        (RELASE)
	# Codename    -c > lucid   > lenny   > squeeze  > debian|julia  > n/a   > n/a         (NAME)
	readonly DISTRO=$(lsb_release -is) RELEASE=$(lsb_release -rs) ARCH=$(uname -m) KERNEL=$(uname -r)
	NAME=$(lsb_release -cs)
	[[ "$NAME" = 'n/a' ]] && NAME=
	readonly NAME

	##[ Create folders if not already created ]##
	mkdir --parents tmp/

	iP=$(wget --quiet --timeout=30 www.whatismyip.com/automation/n09230945.asp -O - 2)
	[[ "$iP" != *.*.* ]] && error "Unable to find ip from outside"

	packages setvars
	readonly iP USER CORES BASE WEB HOME=/home/$USER LOG  # make sure these variables aren't overwritten
	else error "Unsupported OS"
fi
	echo -e "[${bldylw} done ${rst}]"
	log "init() completed"
	sleep 1
}

##[ VARiABLE iNiT ]##
CORES=$(grep -c ^processor /proc/cpuinfo)
SSLCERT=/usr/share/ssl-cert/ssleay.cnf
MKSSLCERT_RUN=1
iFACE=eth0
WEBUSER='www-data'
WEBGROUP='www-data'
WEB=/var/www

#!=====================>> COLOR CONTROL <<=====================!#
##[ echo -e "${txtblu}test ${rst}" ]##
txtblk='\e[0;30m'  # Black ---Regular
txtred='\e[0;31m'  # Red
txtgrn='\e[0;32m'  # Green
txtylw='\e[0;33m'  # Yellow
txtblu='\e[0;34m'  # Blue
txtpur='\e[0;35m'  # Purple
txtcyn='\e[0;36m'  # Cyan
txtwht='\e[0;37m'  # White
bldblk='\e[1;30m'  # Black ---Bold
bldred='\e[1;31m'  # Red
bldgrn='\e[1;32m'  # Green
bldylw='\e[1;33m'  # Yellow
bldblu='\e[1;34m'  # Blue
bldpur='\e[1;35m'  # Purple
bldcyn='\e[1;36m'  # Cyan
bldwht='\e[1;37m'  # White
unkblk='\e[4;30m'  # Black ---Underline
undred='\e[4;31m'  # Red
undgrn='\e[4;32m'  # Green
undylw='\e[4;33m'  # Yellow
undblu='\e[4;34m'  # Blue
undpur='\e[4;35m'  # Purple
undcyn='\e[4;36m'  # Cyan
undwht='\e[4;37m'  # White
bakblk='\e[40m'    # Black ---Background
bakred='\e[41m'    # Red
badgrn='\e[42m'    # Green
bakylw='\e[43m'    # Yellow
bakblu='\e[44m'    # Blue
bakpur='\e[45m'    # Purple
bakcyn='\e[46m'    # Cyan
bakwht='\e[47m'    # White
undrln='\e[4m'     # Underline
rst='\e[0m'        # --------Reset
