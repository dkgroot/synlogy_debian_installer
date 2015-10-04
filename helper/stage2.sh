#!/bin/sh
# syno debian setup stage2 script
# written by: Diederik de Groot <ddegroot [at] users.sf.net>
# copyright: GPL2 2015
#
# Usage 
# stage2 should be run on the synology nas box
# usage:
# ./stage2.sh [astpackage]

ast=${1:-astcompile}

echo "Stage 2"
echo "=======" 
cd /volume1
if [ -f syno_debian/debootstrap/debootstrap ]; then
	echo "Finishing debootstrap installation (takes a bit of time, standby)..."
	chroot syno_debian /debootstrap/debootstrap --second-stage >/dev/null
	if [ $? != 0 ]; then
		echo "Error occured during the debootstrap second stage, please check /volume1/syno_debian/debootstrap/debootstrap.log to see what happened"
		exit 1
	fi
	echo "debootstrap second stage has finished."
	
	echo "coping some files..."
	cp /etc/passwd /volume1/syno_debian/etc/
	cp /etc/shadow /volume1/syno_debian/etc/
	cp /etc/group /volume1/syno_debian/etc/
	mv syno_debian/root/inputrc /volume1/syno_debian/etc/

	echo "coping some files..."
	mkdir -p /usr/local/etc/init.d/
	mv syno_debian/root/99setupDebianChroot.sh /usr/local/etc/rc.d/
	mv syno_debian/root/switch2debian.sh /usr/sbin/
	
	echo "changing permissions..."
	chmod 755 /usr/local/etc/rc.d/99setupDebianChroot.sh
	chmod 755 /usr/sbin/switch2debian.sh

	echo "initializing chroot..."
	. /usr/local/etc/rc.d/99setupDebianChroot.sh start
	
	echo ""
	echo "Stage 3 (running inside chroot)"
	echo "===============================" 
	chroot syno_debian /bin/bash --rcfile /etc/bash.bashrc /root/stage3.sh "$ast"
    echo "rsyslog" >/etc/syno_debian_services
    if [ -f /volume1/syno_debian/usr/sbin/asterisk ]; then
        echo "asterisk" >> /etc/syno_debian_services
    fi
	
    echo "starting services"
    if [ -f ${debianroot}/etc/syno_debian_services ]; then
        for service in `cat ${debianroot}/etc/syno_debian_services`; do
	        echo "starting ${service}..."
	        chroot ${debianroot} /etc/init.d/${service} start
        done
    fi
	
	echo "Stage 3 Finished"
	echo "================" 
	echo ""
	echo "+-----------------------------------------------+"
	echo "| BTW: You can use:                             |"
	echo "|   switch2debian.sh                            |"
	echo "| to jump into the new syno_debian environment  |"
	echo "| and use:                                      |"
	echo "|   exit                                        |"
	echo "| to get back to the synology environment again |"
	echo "+-----------------------------------------------+"
	echo ""
	echo "Enjoy !"
else
	echo "The syno_debian.tgz was not unpacked or formed correctly"
fi
