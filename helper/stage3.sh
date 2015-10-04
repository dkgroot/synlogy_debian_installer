#!/bin/bash
# syno debian setup stage3 script
# written by: Diederik de Groot <ddegroot [at] users.sf.net>
# copyright: GPL2 2015
#
# Usage 
# stage3 should be run on the synology nas box
# usage:
# ./stage3.sh [astpackage]

ast=${1:-astcompile}
export LC_ALL=C

cd /root
echo "Fix cron package installation..."
for i in $( grep "\" -- \"\\$\\@\"$" /var/lib/dpkg/info/cron.* -l ); do sed 's/-- "$@"/cron -- "$@"/g' $i > $i ; done

#echo "Running dkpg-reconfigure"
#dpkg-reconfigure --all

echo "Setting up locale. please choose the correct location..."
dpkg-reconfigure locales -u --terse
dpkg-reconfigure tzdata -u --terse >/dev/null
/usr/sbin/locale-gen >/dev/null

echo "Running apt-get update"
mv /root/sources.list /etc/apt
apt-get update

echo "Fixup apt-get"
apt-get -f -y install

if [ "${ast}" == "astcompile" ]; then
	echo "Install libgmime-dev,glib-dev packages (Internet required)"
	apt-get -y install libgmime-2.6-dev libglib2.0-dev ca-cacert ca-certificates openssl 
fi

echo "Running apt-get update"
apt-get -y dist-upgrade
echo ""
echo "setting up services to be started within the chroot environment"
if [ -z "`grep rsyslog /etc/syno_debian_services`" ]; then 
	echo rsyslog >> /etc/syno_debian_services
fi

echo ""
echo "base configuration stage complete"
echo ""
echo ""
PARALLEL=" -j`cat /proc/cpuinfo |grep processor|wc -l` " 
case "$ast" in
    astcompile)
        if [ ! -f asterisk-11-current.tar.gz ]; then
	        echo "Getting asterisk-11 sources..."
        	wget --quiet http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-11-current.tar.gz
        fi
       	tar xfz asterisk-11-current.tar.gz
        if [ -d asterisk-11.* ]; then
            echo "Setting up and Compiling asterisk..."
            cd asterisk-11.*
            contrib/scripts/get_mp3_source.sh
            ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --datarootdir=/usr/share && \
                make menuselect.makeopts && \
                menuselect/menuselect --disable chan_skinny --enable format_mp3 menuselect.makeopts && \
                menuselect/menuselect --enable CORE-SOUNDS-EN-ALAW --enable CORE-SOUNDS-EN-ULAW --enable CORE-SOUNDS-EN-G722 --enable CORE-SOUNDS-EN-G729  menuselect.makeopts && \
                menuselect/menuselect --enable MOH-OPSOUND-ULAW --enable MOH-OPSOUND-ALAW --enable MOH-OPSOUND-G729 --enable MOH-OPSOUND-G722 menuselect.makeopts && \
                make ${PARALLEL} && \
                make install && \
                make samples
            cp contrib/init.d/etc_default_asterisk /etc/default/asterisk
            cp contrib/init.d/rc.debian.asterisk /etc/init.d/asterisk
            sed -i -e 's/__ASTERISK_SBIN_DIR__/\/usr\/sbin\/asterisk/g' -e 's/__ASTERISK_VARRUN_DIR__/\/var\/run\//g' -e 's/__ASTERISK_ETC_DIR__/\/etc\/asterisk/g' /etc/init.d/asterisk
            chmod 755 /etc/init.d/asterisk
            echo "Asterisk-11 has been compiled and installed"
            if [ -z "`grep asterisk /etc/syno_debian_services`" ]; then
            	echo rsyslog >> /etc/syno_debian_services
            fi
        fi
        ;;
    astpackage)
        echo "Asterisk is already installed"
        ;;
esac

echo ""
echo ""
if [ -f /usr/sbin/asterisk ] && [ -d /usr/include/asterisk ]; then
	echo "Getting chan-sccp-b sources..."
	git clone https://github.com/marcelloceschia/chan-sccp-b.git chan-sccp-b_trunk
	if [ -d chan-sccp-b_trunk ]; then
		cd chan-sccp-b_trunk
		echo "Bootstrapping chan-sccp-b..."
		./tools/bootstrap.sh
		echo "Configuring and Making chan-sccp-b..."
		./configure --prefix=/usr --enable-conference --enable-advanced-functions --enable-video --enable-video-layer --enable-optimization --disable-debug && \
		make ${PARALLEL} && \
		make install && \
		cp conf/sccp.conf.minimal /etc/asterisk/sccp.conf
		if [ -z "`grep 'noload => chan_skinny' /etc/asterisk/modules.conf`" ]; then
			echo "noload => chan_skinny.so" >> /etc/asterisk/modules.conf
		fi
		mv /root/stripper.sh tools/
		. ./tools/stripper.sh
	else
		echo "Something went wrong while retrieving chan-sccp-b from github."
	fi
else
	echo "Asterisk binary or include files could not be found. Something must have gone wrong during the asterisk installation stage"
	exit 1
fi

echo ""
echo "Asterisk and Chan-sccp-b have been installed successfully"
echo ""
echo ""
echo "Congratulations, setup has been completed"
