#!/bin/bash

echo "mount start" > /home/vascom/mount
#sleep 1m
check_count=4

received=`ping raspi -c $check_count | grep transmitted | awk '{print $4}'`
if [ $received -ne "0" ]
then
    #echo -e "$host \e[32mactive\e[0m"
    sudo systemctl start home-vascom-raspi.mount
    #echo -e "$host \e[31minactive\e[0m"
fi
#sudo systemctl start home-vascom-raspi.mount
