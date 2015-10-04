#!/bin/bash 
ASTDIR=/usr/
MODDIR=/lib/asterisk/modules/
mkdir -p /usr/lib/debug/${ASTDIR}/${MODDIR}/
objcopy --only-keep-debug src/.libs/chan_sccp.so /usr/lib/debug/${ASTDIR}/${MODDIR}/chan_sccp.so
cp src/.libs/chan_sccp.so /${ASTDIR}/${MODDIR}
objcopy --strip-debug /${ASTDIR}/${MODDIR}/chan_sccp.so
objcopy --add-gnu-debuglink=/usr/lib/debug/${ASTDIR}/${MODDIR}/chan_sccp.so /${ASTDIR}/${MODDIR}/chan_sccp.so
