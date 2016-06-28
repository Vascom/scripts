#!/bin/bash

#sudo umount /home/vascom/raspi
echo "mount finish 1" >> /home/vascom/mount
sudo systemctl stop home-vascom-raspi.mount
date >> /home/vascom/mount
echo "mount finish 2" >> /home/vascom/mount

