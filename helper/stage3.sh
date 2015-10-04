#!/bin/bash
# syno debian setup stage3 script
# written by: Diederik de Groot <ddegroot [at] users.sf.net>
#             Benjamin Busch <kpnetdesign [at] users.sf.net>
# copyright: GPL2 2015
#
# Usage 
# stage3 should be run on the synology nas box
# usage:
# ./stage3.sh [astpackage]

ast=${1:-astcompile}

cd /root
echo -e "\e[1mFix cron package installation...\e[0m"
for i in $( grep "\" -- \"\\$\\@\"$" /var/lib/dpkg/info/cron.* -l ); do sed 's/-- "$@"/cron -- "$@"/g' $i > $i ; done

echo -e "\e[1mFixing groups file\e[0m"
for grp in daemon:x:1: bin:x:2: sys:x:3: adm:x:4: tty:x:5: disk:x:6: man:x:12: kmem:x:15: sudo:x:27: dip:x:30: backup:x:34: operator:x:37: list:x:38: shadow:x:42: utmp:x:43: users:x:100: crontab:x:102: syslog:x:103:; do
    echo "${grp}" >> /etc/group
done
        
echo -e "\e[1mPrevent installation of systemd/upstart\e[0m"
echo -e 'Package: systemd\nPin: origin ""\nPin-Priority: -1' > /etc/apt/preferences.d/systemd
echo -e '\n\nPackage: *systemd*\nPin: origin ""\nPin-Priority: -1' >> /etc/apt/preferences.d/systemd
echo -e 'Package: upstart\nPin: origin ""\nPin-Priority: -1' > /etc/apt/preferences.d/upstart
echo -e '\n\nPackage: *upstart*\nPin: origin ""\nPin-Priority: -1' >> /etc/apt/preferences.d/upstart
        
if [ -f /etc/init ]; then
    echo -e "\e[1mSwitching off upstart services\e[0m"
    mkdir /etc/init /etc/init.bak
    mv /etc/init/* /etc/init.bak/
fi

echo -e "\e[1mPlease select your local timezone...\e[0m"
sleep 5
dpkg-reconfigure tzdata
echo -e "\e[1mPlease choose your language (locale) and include 'en_US.UTF-8' as a fallback...\e[0m"
sleep 5
dpkg-reconfigure locales -u --terse
/usr/sbin/locale-gen >/dev/null

echo -e "\e[1mRunning apt-get update\e[0m"
mv /root/sources.list /etc/apt
apt-get update || exit 1

echo -e "\e[1mFixup apt-get\e[0m"
apt-get -f -y install || exit 2

if [ "${ast}" == "astcompile" ]; then
	echo -e "\e[1mInstall libgmime-dev,glib-dev packages (Internet required)\e[0m"
	apt-get -y install libgmime-2.6-dev libglib2.0-dev ca-cacert ca-certificates openssl  || exit 3
fi

echo -e "\e[1mRunning apt-get update\e[0m"
apt-get -y dist-upgrade || exit 4
echo ""
echo -e "\e[1msetting up services to be started within the chroot environment\e[0m"
if [ -z "`grep rsyslog /etc/syno_debian_services`" ]; then 
	echo rsyslog >> /etc/syno_debian_services
fi

echo ""
echo -e "\e[1mbase configuration stage complete\e[0m"
echo ""
echo ""
PARALLEL=" -j`cat /proc/cpuinfo |grep processor|wc -l` " 
echo "rsyslog" >/etc/syno_debian_services
case "$ast" in
    astcompile)
        if [ ! -f asterisk-11-current.tar.gz ]; then
	        echo -e "\e[1mGetting asterisk-11 sources...\e[0m"
        	wget --quiet http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-11-current.tar.gz || exit 5
        fi
       	tar xfz asterisk-11-current.tar.gz
        if [ -d asterisk-11.* ]; then
            echo -e "\e[1mSetting up and Compiling asterisk...\e[0m"
            cd asterisk-11.*
            contrib/scripts/get_mp3_source.sh
            ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --datarootdir=/usr/share && \
                make menuselect.makeopts && \
                menuselect/menuselect --disable chan_skinny --enable format_mp3 menuselect.makeopts && \
                menuselect/menuselect --enable CORE-SOUNDS-EN-ALAW --enable CORE-SOUNDS-EN-ULAW --enable CORE-SOUNDS-EN-G722 --enable CORE-SOUNDS-EN-G729  menuselect.makeopts && \
                menuselect/menuselect --enable MOH-OPSOUND-ULAW --enable MOH-OPSOUND-ALAW --enable MOH-OPSOUND-G729 --enable MOH-OPSOUND-G722 menuselect.makeopts && \
                make ${PARALLEL} && \
                make install && \
                make samples || exit 6
            cp contrib/init.d/etc_default_asterisk /etc/default/asterisk
            cp contrib/init.d/rc.debian.asterisk /etc/init.d/asterisk
            sed -i -e 's/__ASTERISK_SBIN_DIR__/\/usr\/sbin\/g' -e 's/__ASTERISK_VARRUN_DIR__/\/var\/run\//g' -e 's/__ASTERISK_ETC_DIR__/\/etc\/asterisk/g' /etc/init.d/asterisk
            chmod 755 /etc/init.d/asterisk
            echo -e "\e[1mAsterisk-11 has been compiled and installed\e[0m"
            if [ -f /usr/sbin/asterisk ]; then
                echo "asterisk" >> /etc/syno_debian_services
            fi
        fi
        ;;
    astpackage)
        echo -e "\e[1mAsterisk is already installed\e[0m"
        ;;
esac

echo ""
echo ""
if [ -f /usr/sbin/asterisk ] && [ -d /usr/include/asterisk ]; then
	echo -e "\e[1mGetting chan-sccp-b sources...\e[0m"
	git clone https://github.com/marcelloceschia/chan-sccp-b.git chan-sccp-b_trunk || exit 7
	if [ -d chan-sccp-b_trunk ]; then
		cd chan-sccp-b_trunk
		echo -e "\e[1mBootstrapping chan-sccp-b...\e[0m"
		./tools/bootstrap.sh
		echo -e "\e[1mConfiguring and Making chan-sccp-b...\e[0m"
		./configure --prefix=/usr --enable-conference --enable-advanced-functions --enable-video --enable-video-layer --enable-optimization --disable-debug && \
		make ${PARALLEL} && \
		make install && \
		cp conf/sccp.conf.minimal /etc/asterisk/sccp.conf || exit 8
		if [ -z "`grep 'noload => chan_skinny' /etc/asterisk/modules.conf`" ]; then
			echo "noload => chan_skinny.so" >> /etc/asterisk/modules.conf
		fi
		mv /root/stripper.sh tools/
		. ./tools/stripper.sh
	else
		echo -e "\e[31m\e[1mSomething went wrong while retrieving chan-sccp-b from github.\e[0m"
	fi
else
	echo -e "\e[31m\e[1mAsterisk binary or include files could not be found. Something must have gone wrong during the asterisk installation stage.\e[0m"
	exit 1
fi

echo ""
echo -e "\e[1mAsterisk and Chan-sccp-b have been installed successfully\e[0m"
echo ""
echo ""
echo -e "\e[1mCongratulations, setup has been completed\e[0m"
