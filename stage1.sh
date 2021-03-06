#!/bin/bash
#
# syno debian setup script
# written by: Diederik de Groot <ddegroot [at] users.sf.net>
#             Benjamin Busch <kpnetdesign [at] users.sf.net>
# copyright: GPL2 2015
#
#
# Usage 
# stage1 should be run on host system (not the synology nas)
# usage:
# ./stage1.sh <architecture> [jessie|sid] [astpackage|astcompile]
# architecture can be powerpc, powerpcspe, ppc64el, armhf, armel, (i386, amd64)

if [ -z "$1" ]; then
	echo -e "\e[1msynology debian setup script\e[0m"
	echo -e "\e[1m============================\e[0m"
	echo "$0 architecture [system] [asterisk]"
	echo "usage: $0 [powerpc, powerpcspe, ppc64el, armhf, armel, i386, amd64] [jessie|sid] [astcompile|astpackage]"
	echo ""
	echo "architecture: [required], one of powerpc, powerpcspe, ppc64el, armhf, armel, (i386, amd64)"
	echo "system (optional|default:sid): must be either jessie(stable) or sid(unstable)"
	echo "asterisk (optional|default:astcompile): should asterisk be compiled from source, or using asterisk-dev package"
	echo ""
	echo "Written by Diederik de Groot <ddegroot [at] users.sf.net>, Benjamin Busch <kpnetdesign [at] users.sf.net>"
	exit 1
fi

arch=$1
system=${2:-sid}
ast=${3:-astcompile}

echo -e "\e[1mRunning $0 $arch $system $ast\e[0m"
echo ""

# check for debootstrap
echo -e "\e[1mTesting for 'debootstrap' packages...\e[0m"
bootstrapper=`which debootstrap`
if [ -z "${bootstrapper}" ]; then
	# install debootstarp
	case "`grep "ID" /etc/os-release |awk -F= '{print $2}'`" in
		ubuntu|debian)
			apt-get install debootstrap
			;;
		suse|opensuse)
			zypper install debootstrap
			;;
		redhat|centos)
			yum install debootstrap
			;;
	esac
fi

bootstrapper=`which debootstrap`
base_requirements="bash-completion,htop,joe,debian-archive-keyring,debian-keyring,debian-ports-archive-keyring,sysvinit-core,sysvinit,sysvinit-utils"
prevent_installation="systemd,upstart"
compile_requirements="gcc,g++,autoconf,automake,make,flex,bison,locales,gdb"
case "${system}" in
	jessie)
		case "${ast}" in
			astpackage)
				asterisk_requirements="asterisk,asterisk-dev,asterisk-dbg,libtiff5-dev,libpng12-dev"
				;;
			astcompile)
				asterisk_requirements="libncurses5-dev,zlib1g-dev,libssl-dev,libxml2-dev,\
				libsqlite3-dev,uuid-dev,uuid,libcurl4-gnutls-dev,libspeex-dev,libspeexdsp-dev,\
				libogg-dev,libvorbis-dev,libpq-dev,libsqlite0-dev,libmysqlclient-dev,libneon27-dev,\
				lua5.1,libmysqlclient-dev,libsnmp-dev,libiksemel-dev,libnewt-dev,libpopt-dev,libical-dev,libspandsp-dev,\
				libjack-dev,libresample1-dev,libc-dev-bin,linux-libc-dev,binutils-dev,libsrtp0-dev,libedit-dev,libldap2-dev,\
				libusb-dev,liblua5.1-0-dev,subversion,git,libtiff5-dev,libpng12-dev"
				;;
			*)
				echo -e "\e[31m\e[1mERROR: the asterisk:${ast} setting on the commandline is unknown\e[0m"
				exit 3
				;;
		esac
		;;
	sid)   
		case "${ast}" in
			astpackage)
				asterisk_requirements="asterisk,asterisk-dev,asterisk-dbg,libtiff5-dev,libpng12-dev"
				;;
			astcompile)
				asterisk_requirements="libncurses5-dev,zlib1g-dev,libssl-dev,libxml2-dev,\
				libsqlite3-dev,uuid-dev,uuid,libcurl4-gnutls-dev,libspeex-dev,libspeexdsp-dev,\
				libogg-dev,libvorbis-dev,libpq-dev,libsqlite0-dev,libmysqlclient-dev,libneon27-dev,\
				lua5.1,libmysqlclient-dev,libsnmp-dev,libiksemel-dev,libnewt-dev,libpopt-dev,libical-dev,libspandsp-dev,\
				libjack-dev,libresample1-dev,libc-dev-bin,linux-libc-dev,binutils-dev,libsrtp0-dev,libedit-dev,libldap2-dev,\
				libusb-dev,liblua5.1-0-dev,subversion,git,libtiff5-dev,libpng12-dev"
				;;
			*)
				echo -e "\e[31m\e[1mERROR: the asterisk:${ast} setting on the commandline is unknown\e[0m"
				exit 3
				;;
		esac
		;;
	*)
		echo -e "\e[31m\e[1mERROR: the system:${system} is unknown\e[0m"
		exit 2
esac
#libradiusclient-ng-dev,libcorosync-dev,unixodbc-dev,libcurl4-nss-dev,libcurl4-openssl-dev,libgmime-2.6-dev,
if [ ! -z "${bootstrapper}" ]; then
	echo -e "\e[1mRunning debootstrap, please stand by (this will take a while)....\e[0m"
	# starting
	echo ""
	${bootstrapper} --no-check-certificate --no-check-gpg --foreign --arch ${arch} --include="${base_requirements},${compile_requirements},${asterisk_requirements}" --exclude="${prevent_installation}" --verbose ${system} syno_debian | \
		tee debootstrap.log | grep -e "Resolving" -e "Found" -e "Retrieving Release"
	if [ $? == 0 ]; then
		echo -e "\e[1mdebootstrap finished.\e[0m"
		echo ""
		echo -e "\e[1mCreating tgz file\e[0m"
		mkdir -p syno_debian/root/
		cp helper/stage?.sh syno_debian/root/
		cp helper/S99setupDebianChroot.sh helper/switch2debian.sh helper/inputrc helper/stripper.sh syno_debian/root/
		cp helper/bash.bashrc syno_debian/etc
		case "${system}" in
			sid)
				cp helper/sources_sid.list syno_debian/root/sources.list
				;;
			jessie)
				cp helper/sources_jessie.list syno_debian/root/sources.list
				;;
		esac

		[ -f syno_debian.tgz ] && rm -rf syno_debian.tgz
		tar cfz syno_debian.tgz syno_debian
		#rm -rf syno_debian
		echo ""
		echo -e "\e[1msyno_debian.tgz has been created\e[0m"
		echo ""
		echo -e "\e[1mIt's time for stage 2\e[0m"
		echo -e "\e[1m=====================\e[0m"
		echo "Please copy the syno_debian.tgz file to your synology nas in the /volume1, using [scp, winscp, ftp, samba]"
		echo ""
		echo "when the file has been copied completely, log into your nas (telnet/ssh) and execute:"
		case "$ast" in
			astpackage)
				echo -e "\e[1m    cd /volume1/ && tar xzf syno_debian.tgz && /volume1/syno_debian/root/stage2.sh astpackage\e[0m"
				;;
			astcompile)
				echo -e "\e[1m    cd /volume1/ && tar xzf syno_debian.tgz && /volume1/syno_debian/root/stage2.sh\e[0m"
				;;
		esac
		echo "To continue the installation process"
	else
		echo "'debootstrap' failed, please check ./debootstrap.log to see what went wrong"
	fi
else
	echo -e "\e[31m\e[1mThe 'debootstrap' program is missing on your system. Please install this package manually before trying again.\e[0m"
fi

