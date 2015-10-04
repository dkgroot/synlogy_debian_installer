#!/bin/sh
debianroot=/volume1/syno_debian
if [ -d ${debianroot} ]; then
	if [ -f ${debianroot}/chroot_running ]; then
		chroot ${debianroot} /bin/bash --rcfile /etc/bash.bashrc
	else
		echo "/usr/local/init.d/99setupDebianChroot.sh has not been started (correctly)."
	fi
fi
