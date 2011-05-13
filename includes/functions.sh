##!=======================>> FUNCTiONS <<=======================!##
base_install() {  # install dependencies
COMMON="apache2-utils autoconf automake axel bash-completion binutils bzip2 ca-certificates cpp curl file gamin gcc git-core gzip htop iptables libexpat1 libtool libxml2 m4 make mcrypt openssl patch perl pkg-config python python-gamin python-openssl python-setuptools rsync screen subversion sudo unrar unzip"
DYNAMIC="libcurl3 libcurl3-gnutls libcurl4-openssl-dev libncurses5 libncurses5-dev libsigc++-2.0-dev"

DEBIAN="$COMMON $DYNAMIC aptitude autotools-dev build-essential cfv comerr-dev dtach g++ geoip-database libcppunit-dev libperl-dev libssl-dev libterm-readline-gnu-perl libtorrent-rasterbar-dev ncurses-base ncurses-bin ncurses-term perl-modules ssl-cert"
SUSE="$COMMON libcppunit-devel libcurl-devel libopenssl-devel libtorrent-rasterbar-devel gcc-c++ geoip ncurses-devel libncurses6 libsigc++2-devel"

ARCHLINUX="axel base-devel bash-completion binutils cppunit curl dtach freetype2 geoip htop libsigc++ libmcrypt libxslt ncurses openssl perl perl-digest-sha1 perl-json perl-json-xs perl-xml-libxslt perl-net-ssleay pcre popt rsync subversion sudo t1lib unrar unzip"

PHP_COMMON="php5-curl php5-geoip php5-gd php5-mcrypt php5-mysql php5-suhosin php5-xmlrpc"

PHP_DEBIAN="$PHP_COMMON php5-cgi php5-cli php5-dev"  # php5-json is provided by php5-common
PHP_SUSE="$PHP_COMMON php5-devel php5-json"
PHP_ARCHLINUX="php php-curl php-geoip php-suhosin"

	echo -en "${bldred} REFRESHiNG REPOSiTORiES...${rst}"
	packages update && echo -e "${bldylw} done${rst}"
	echo -en "${bldred} iNSTALLiNG BASE PACKAGES, this may take a while...${rst}"
	case "$DISTRO" in
		[uU]buntu|[Dd]ebian|*Mint) packages install $DEBIAN ;;
		ARCH*|[Aa]rch* ) packages install $ARCHLINUX        ;;
		SUSE*|[Ss]use* ) packages install $SUSE
						 if ! is_installed "dtach"
							then cd ${BASE}/tmp
							download http://sourceforge.net/projects/dtach/files/dtach/0.8/dtach-0.8.tar.gz && extract dtach-0.8.tar.gz
							cd dtach-0.8
							sh configure && make && install -m 755 dtach /usr/bin
						 fi ;;
	esac
	if_error "Required system packages failed to install"
	log "Base Installation | Completed"
	echo -e "${bldylw} done${rst}"
}

base_configure() {  # do this before base_install ^
	case "$DISTRO" in
		# [uU]buntu|[Dd]ebian|*Mint) ;;
		# SUSE*|[Ss]use* ) ;;
		# ARCH*|[Aa]rch* ) ;;
	esac
	log "Base Configuration | Completed"
}
			
archlinux_add_module() {
	cp /etc/rc.conf /etc/rc.conf.bak
	source /etc/rc.conf
	MODULES+=($@)
	NEWMODULES="MODULES=(${MODULES[@]})"
	sed -i "s:MODULES=.*:$NEWMODULES:" /etc/rc.conf
}

build_from_aur() {  # compile and install PKBUILDs
	BIN_NAME="$1"
	PKG_NAME="$2"
	PKG_URL="https://aur.archlinux.org/packages/$PKG_NAME/${PKG_NAME}.tar.gz"

	is_version "gcc" "11-13" ">" "4.1" && {
		if [[ $(grep "mtune=generic" /etc/makepkg.conf) ]]; then
			sed -i /etc/makepkg.conf \
				-e "s;[#]*CFLAGS=.*;CFLAGS=\"-march=native\";" \  # implies -mtune=native
				-e "s;[#]*CXXFLAGS=.*;CXXFLAGS=\"${CFLAGS}\";"
		fi
		sed -i "s;[#]*MAKEFLAGS=.*;MAKEFLAGS=\"-j$(($(grep -c ^processor /proc/cpuinfo) + 1))\";" /etc/makepkg.conf ;}

	if ! is_installed "$BIN_NAME" ;then
		[[ $3 = 'ignore-deps' ]] && PKG_OPTS="-dfc" || PKG_OPTS="-sfc"
		LAST_DIR="$PWD" && cd $SOURCE_DIR
		download $PKG_URL
		extract "${PKG_NAME}.tar.gz" && cd "$PKG_NAME"
		makepkg "$PKG_OPTS" --asroot --noconfirm
			if_error "$PKG_NAME Failed to build"
		PKG_VER=$(ls $PKG_NAME*.pkg.tar.* | sed s/$PKG_NAME-// | sed s/-$ARCH.pkg.tar.*//)
		pacman -U $PKG_NAME-$PKG_VER-$ARCH.pkg.tar.*
		INST_VER=$(pacman -Q $PKG_NAME)
		if [[ "$INST_VER" != "$PKG_NAME $PKG_VER" ]]
			then echo -e "$PKG_NAME Failed to install"
			else log "$PKG_NAME Installed Successfully"
		fi
		cd $LAST_DIR
	else notice "$PKG_NAME is already installed. Skipping"
	fi
}

checkout() {  # increase verbosity
	if [[ "$DEBUG" = 1 ]]; then svn co "$@" ; E_=$?
	else svn co -q "$@" ; E_=$?
	fi	
}

cleanup() {  # remove tmp folder and restore permissions
	[[ "$RM_TMP" = 'y' ]] && rm --recursive --force $SOURCE_DIR
	GROUP=$(grep "$(id -g "$USER")" /etc/group | cut -d: -f1)
	chown -R "$USER:$GROUP" "$BASE"
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

debian_addrepo() {
	[[ "$DISTRO" = @(Debian|*Mint) ]] && ppa_dist='lucid' || ppa_dist="$NAME"
	ppa=$(echo "$1" | cut -d":" -f2 -s)
	key="$2"
	echo "deb http://ppa.launchpad.net/"$ppa"/ubuntu "$ppa_dist" main" >> /etc/apt/sources.list.d/autoinstaller.list
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key"
	log "Repository: "$ppa"|"$ppa_dist" ADDED"
}

debug_wait() {  # prints a message and wait for user before continuing
	if [[ "$DEBUG" = '1' || "$2" = 'force' ]]; then
		echo -e "${bldpur} DEBUG: $1"
		echo -en "${bldpur} Press Enter...${rst}"
		read ENTER
	fi
}

download() {  # prefer axel fallback to wget with quiet on if DEBUG is off
	is_installed "axel" && DL="axel -n 6 --alternate" || DL="wget --timeout=15"
	[[ "$DEBUG" = 1 ]] && DL="$DL --quiet"
	$DL $1  # GET URL
	E_=$?   # Check if it downloaded correctly
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
		echo -e " Error:${bldred} $1 ${rst}($E_)"
		log "Error: $1 (Error $E_)\n<--------------------------------->\n"
		cleanup ; exit $E_
	fi
}

is_installed() {  # check if a program is installed
	# $1 = program
	# 0 = IS installed  1 = is NOT installed
	[[ $(type -P "$1") ]] && return 0 || return 1
}

is_running() {  # check if a program is running
	# $1 = program  $2 = user (optional)
	# 0 = IS running  1 = is NOT running
	sleep 1
	if [[ "$#" = 1 ]]; then
		[[ ! -z $(pgrep "$1") ]] && return 0 || return 1
	elif [[ "$#" = 2 ]]; then
		[[ ! -z $(pgrep -u "$2" "$1") ]] && return 0 || return 1
	fi
}

is_version() {
	APP="$1" CHAR="$2" TYPE="$3" VER="$4"
	[[ $TYPE = ">" ]] &&
		if [[ $($APP --version | head -n1 | cut -c $CHAR) > $VER ]]
			then return 0
			else return 1
		fi || [[ $TYPE = "=" ]] &&
			if [[ $($APP --version | head -n1 | cut -c $CHAR) = $VER ]]
				then return 0
				else return 1
			fi || return 1
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
		sed -i /etc/ssl/openssl.cnf \
			-e 's:default_bits .*:default_bits = 2048:' \
			-e 's:default_md .*:default_md = sha256:'
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
			addrepo) debian_addrepo $2 $3                                        ;;
			clean  ) apt-get $quiet autoclean                                    ;;
			install) shift; apt-get install --yes $quiet $@ 2>> $LOG; E_=$?      ;;
			remove ) shift; apt-get autoremove --yes $quiet $@ 2>> $LOG; E_=$?   ;;
			update ) apt-get update >/dev/null                                   ;;
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
		case "$1" in
			clean  ) pacman --sync --clean --noconfirm ; echo
					 pacman-optimize >/dev/null                                  ;;
			install) shift; pacman --sync --noconfirm --needed $@ 2>> $LOG ;E_=$? ;;
			remove ) shift; pacman --remove --unneeded $@ 2>> $LOG; E_=$?         ;;
			update ) pacman --sync --refresh --refresh 2>> $LOG                   ;;
			upgrade) pacman --sync --refresh --sysupgrade --noconfirm 2>> $LOG    ;;
			version) pacman --sync --info $2 | grep Version                       ;;
			setvars)
				REPO_PATH=/etc/pacman.conf
				WEB=/srv/http
				WEBUSER='http'
				WEBGROUP='http'
				alias_autoclean="sudo pacman -Sc"
				alias_install="sudo pacman -S --needed"
				alias_remove="sudo pacman -R"
				alias_update="sudo pacman -Sy"
				alias_upgrade="sudo pacman -Syu" ;;
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
	fi
}

patch_rtorrent() {  # Put rtorrent|libtorrent patches here
if [[ "$DISTRO" = @(ARCH|[Aa]rch)* ]]; then
	if [[ "$ARCH" = "x86_64" ]]; then
		if [[ $rtorrent_svn = 'n' ]]; then
			if is_version "ncursesw5-config" "1-3" "=" "5.8"; then  # Fix segfault caused by ncurses 5.8
				sed -i "s|width = 0, int height = 0|width = 1, int height = 1|" rtorrent/src/display/canvas.h
			fi
		fi
	fi
fi
}

runchecks() {
if [[ $(uname -s) = "Linux" ]] ; then
	if [[ -f config.ini ]]; then  # Find Config and Load it
		source config.ini || error "while loading config.ini"
		[[ "$iDiDNTEDiTMYCONFiG" ]] && error "PLEASE EDiT THE CONFiG"  # Die if it hasnt been edited
		[[ "$PWD" != "$BASE"     ]] && error "Does not match $BASE "   # Check if the user declared BASE correctly in the config
	else error "config.ini not found!"  # Cant continue without a config so produce an error and exit
	fi

	echo -en "${rst}>>> Checking Requires..."
		[[ -x /usr/bin/lsb_release ]] ||  # Check if lsb-release is installed
			error "Please install package: lsb-release"
	echo -e "[${bldylw} OK ${rst}]"

	[[ "$UID" = 0 ]] &&  # Check if user is root
		echo -e ">>> User Check .........[${bldylw} OK ${rst}]" ||
		error "PLEASE RUN WITH SUDO"

	[[ "$DEBUG" = 1 ]] &&  # Check if debug is on/off
		echo -e ">>> Debug Mode .........[${bldylw} ON ${rst}]" ||
		echo -e ">>> Debug Mode .........[${bldylw} OFF ${rst}]"

	if [[ $OVERWRITE_SOURCE_DIR != "" ]]; then
		SOURCE_DIR="$OVERWRITE_SOURCE_DIR"
	else [[ $(grep /tmp /etc/mtab | grep noexec) != "" ]] &&  # Check whether /tmp is mounted 'noexec'
			SOURCE_DIR="$BASE/tmp" || SOURCE_DIR="/tmp/.fangspitzen"
	fi

	echo -ne ">>> Internet Access ..."
	[[ $(ping -c 1 74.125.226.116) ]] && [[ $(ping -c 1 208.67.222.222) ]] &&  # Ping google and opendns
		echo -e ".[${bldylw} OK ${rst}]" || error "Unable to ping outside world..."

sleep 1
else error "Unsupported OS"
fi
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
	echo -e " ${bldred}  -p,  --pass    ${bldpur}(length) ${bldylw} Generate a strong password of 'x' length"
	echo -e " ${bldred}  -t,  --threads ${bldpur}(num) ${bldylw}    Number of threads to create when using 'make'"
	echo -e " ${bldred}  -v,  --version ${bldylw}          Show date and version number \n ${rst}"
	echo -e " ${bldred}       --save-tmp ${bldylw}          Dont remove script src directory ${rst}"
	echo -e " ${bldred}       --rtorrent-prealloc ${bldylw} Build rtorrent with file preallocation \n ${rst}"
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

init() {  # find distro and architecture
	echo -n ">>> iNiTiALiZiNG......"
	# Distributor -i > Ubuntu  > Debian  > Debian   > LinuxMint     > Arch  > SUSE LINUX  ($DISTRO)
	# Release     -r > 10.04   > 5.0.6   > 6.0      > 1|10          > n/a   > 11.3        ($RELASE)
	# Codename    -c > lucid   > lenny   > squeeze  > debian|julia  > n/a   > n/a         ($NAME)
	readonly DISTRO=$(lsb_release -is) RELEASE=$(lsb_release -rs) ARCH=$(uname -m) KERNEL=$(uname -r)
	NAME=$(lsb_release -cs)
	[[ "$NAME" = 'n/a' ]] && NAME=
	readonly NAME

	iP=$(wget --quiet --timeout=30 www.whatismyip.com/automation/n09230945.asp -O - 2)
	LOG=$BASE/logs/installer.log

	mkdir --parents $BASE/logs/
	mkdir --parents $SOURCE_DIR

	packages setvars
	readonly iP USER CORES BASE HOME=/home/$USER LOG  # make sure these variables aren't overwritten
	echo -e "[${bldylw} done ${rst}]"
	sleep 1
}

##[ VARiABLE iNiT ]##
if [[ $OVERWRITE_THREAD_COUNT ]]
	then CORES="$OVERWRITE_THREAD_COUNT"
	else CORES=$(grep -c ^processor /proc/cpuinfo)
fi
SSLCERT=/usr/share/ssl-cert/ssleay.cnf
MKSSLCERT_RUN=1
iFACE=eth0
RM_TMP='y'

##[ Default Webserver Settings
##+ can be changed in packages()setvars ]##
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
