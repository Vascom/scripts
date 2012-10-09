#!/bin/bash

#HTTP bind
if [ ! -e /var/www/lighttpd/downloads/list ]
then
    sudo mount --bind /home/vascom/Загрузки /var/www/lighttpd/downloads/
    sudo mount -o remount,ro /var/www/lighttpd/downloads/
fi

#FTP start


#WEBcam debug
#USBFS_MOUNTED=`mount | grep -c usbfs`
#if [ $USBFS_MOUNTED -ne "1" ]
#then
#    sudo mount -t usbfs none /proc/bus/usbfs
#fi

#rtorrent start
if [ -e /home/vascom/rt_sessions/rtorrent.lock ]
then
    rm -f /home/vascom/rt_sessions/rtorrent.lock
fi
screen -mdS rtorrent rtorrent
