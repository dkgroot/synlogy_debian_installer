Automated debian installed on synolgy (using debootstrap)
=========================================================

This includes all the necessary development package to compile and install asterisk-11/asterisk-13 and the latest chan-sccp-b.

Stage 1
=======

This has to be executed on any Unix/Linux host system, but not the synology NAS itself. If you are running windows and don't 
have access to any unix/linux system, you may have to build a small virtual machine to complete this task.

* Log in to your host system (commandline / ssh / telnet)
* Create a new (temp) directory 
* Clone this git repository using:
    git clone https://github.com/dkgroot/synlogy_debian_installer.git
* Step into the directory
    cd synlogy_debian_installer
* Execute the stage1 script
    ./stage1.sh <architecture [system] [asterisk]
  
  * architecture: matches the cpu type used by your synology device and should be one of
    powerpc, powerpcspe, ppc64el, armhf, armel, i386, amd64
  * system (optional|default:sid): must be either jessie(stable) or sid(unstable)"
  * asterisk (optional|default:astcompile): should asterisk be compiled from source, or using asterisk-dev package"

* Get a cup of coffee while the first stage completes. The result will be a newly created tgz file, which has to be moved to
  your synology NAS in the /volume1 directory. This can be done using for example scp, ftp or samba.
  
Stage 2
=======
* Requirements: 
  * You have successfully created the tgz file in the previous stage and transfered the file to your NAS into directory /volume1
  * You have logged into the NAS device using ssh, telnet, serial connection
* Execute the command provided by the stage1.sh script in the one of the last lines, looking like
    cd /volume1/ && tar xzf syno_debian.tgz && /volume1/syno_debian/root/stage2.sh [astpackage]

Finished
========
Once stage 2 has completed successfully, you will have a fully functional debian chroot environment with asterisk and chan-sccp-b
installed on top of your synology base system. The synology operating itself has not been changed. You can use:
    switch2debian.sh
to jump in to the debian chroot environment. To get back to the synology base system / prompt, you can use:
    exit

Enjoy your new freshly installed asterisk + chan-sccp-b system !
