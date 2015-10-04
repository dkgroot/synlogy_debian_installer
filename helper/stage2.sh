#!/bin/sh
# syno debian setup stage2 script
# written by: Diederik de Groot <ddegroot [at] users.sf.net>
#             Benjamin Busch <kpnetdesign [at] users.sf.net>
# copyright: GPL2 2015
#
# Usage 
# stage2 should be run on the synology nas box
# usage:
# ./stage2.sh [astpackage]

ast=${1:-astcompile}
debianroot=/volume1/syno_debian/

echo -e "\e[1mStage 2\e[0m"
echo -e "\e[1m=======\e[0m" 
cd /volume1
if [ -f syno_debian/debootstrap/debootstrap ]; then
	echo -e "\e[1mFinishing debootstrap installation (takes a bit of time, standby)...\e[0m"
	chroot syno_debian /debootstrap/debootstrap --second-stage >/dev/null
	if [ $? != 0 ]; then
		echo -e "\e[31m\e[1mError occured during the debootstrap second stage, please check /volume1/syno_debian/debootstrap/debootstrap.log to see what happened\e[0m"
		exit 1
	fi
	echo -e "\e[1mdebootstrap second stage has finished.\e[0m"
	
	echo -e "\e[1mcopying some files...\e[0m"
	cp /etc/passwd ${debianroot}/etc/
	cp /etc/shadow ${debianroot}/etc/
	cp /etc/group ${debianroot}/etc/
	mv syno_debian/root/inputrc ${debianroot}/etc/

	echo -e "\e[1mcopying some files...\e[0m"
	mkdir -p /usr/local/etc/init.d/
	mv syno_debian/root/S99setupDebianChroot.sh /usr/local/etc/rc.d/
	mv syno_debian/root/switch2debian.sh /usr/local/sbin/
	
	echo -e "\e[1mchanging permissions...\e[0m"
	chmod 755 /usr/local/etc/rc.d/S99setupDebianChroot.sh
	chmod 755 /usr/local/sbin/switch2debian.sh

	echo -e "\e[1minitializing chroot...\e[0m"
	. /usr/local/etc/rc.d/S99setupDebianChroot.sh start
	
	echo ""
	echo -e "\e[1mStage 3 (running inside chroot)\e[0m"
	echo -e "\e[1m===============================\e[0m" 
	chroot ${syno_debian} /bin/bash --rcfile /etc/bash.bashrc /root/stage3.sh "$ast"
	echo -e "\e[1mstarting services\e[0m"
	if [ -f ${debianroot}/etc/syno_debian_services ]; then
		for service in `cat ${debianroot}/etc/syno_debian_services`; do
			echo -e "\e[1mstarting ${service}...\e[0m"
			chroot ${debianroot} /etc/init.d/${service} start
		done
	fi
	
	echo -e "\e[1mStage 3 Finished\e[0m"
	echo -e "\e[1m================\e[0m" 
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
	echo -e "\e[1mEnjoy !\e[0m"
else
	echo -e "\e[31m\e[1mThe syno_debian.tgz was not unpacked or formed correctly\e[0m"
fi
