#!/bin/bash

if [ -e /home/vascom/rt_sessions/rtorrent.lock ]
then rm -f /home/vascom/rt_sessions/rtorrent.lock
fi

screen -mdS rtorrent rtorrent
