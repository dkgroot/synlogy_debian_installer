#!/bin/sh
debianroot=/volume1/syno_debian
if [ -d ${debianroot} ]; then
    case "$1" in
        start)
            echo "setting up chroot"
            cd ${debianroot}/var/
            rm ${debianroot}/var/run
            ln -s ${debianroot}/var/run  ../run
            cd ${debianroot}/root
            
            mount -o bind /proc ${debianroot}/proc
            mount -o bind /sys ${debianroot}/sys
            mount -o bind /dev ${debianroot}/dev
            mount -o bind /dev/pts ${debianroot}/dev/pts
            mount -t tmpfs none ${debianroot}/run
            mount -t tmpfs none ${debianroot}/var/run
            mount -t tmpfs none ${debianroot}/tmp
            mount -t tmpfs none ${debianroot}/var/tmp
            [ -d /proc/bus/usb ] && mount -t usbfs /proc/bus/usb ${debianroot}/proc/bus/usb
            [ ! -d ${debianroot}/volume1 ] && mkdir ${debianroot}/volume1
            mount -o bind /volume1 ${debianroot}/volume1
            
            cp /etc/resolv.conf /volume1/syno_debian/etc/
            
            echo "starting services"
            if [ -f ${debianroot}/etc/syno_debian_services ]; then
                for service in `cat ${debianroot}/etc/syno_debian_services`; do
                    echo "starting ${service}..."
                    chroot ${debianroot} /etc/init.d/${service} start
                done
            fi
            
            echo "syno_debian chroot has been setup"
            echo "you can use switch2debian.sh"
            echo "running" >${debianroot}/chroot_running
            ;;
        stop)
            echo "stopping services"
            if [ -f ${debianroot}/etc/syno_debian_services ]; then
                for service in `cat ${debianroot}/etc/syno_debian_services`; do
                    echo "stopping ${service}..."
                    chroot ${debianroot} /etc/init.d/${service} stop
                done
            fi
            echo "demanteling syno_debian chroot"
            if [ ! -z "`cat /etc/mtab | grep ${debianroot}`" ]; then
		    [ -d /proc/bus/usb ] && umount -f ${debianroot}/proc/bus/usb
		    umount -f ${debianroot}/dev/pts
		    umount -f ${debianroot}/volume1
		    umount -f ${debianroot}/var/run
		    umount -f ${debianroot}/var/tmp
		    umount -f ${debianroot}/proc
		    umount -f ${debianroot}/sys
		    umount -f ${debianroot}/dev
		    umount -f ${debianroot}/run
		    umount -f ${debianroot}/tmp
            fi
            [ -f ${debianroot}/chroot_running ] && rm ${debianroot}/chroot_running
            ;;
    esac
fi
