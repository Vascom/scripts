#!/bin/bash

case "$1" in
    en)     command="1";;
    dis)    command="0";;
    *)      echo -e "Online CPUs:  `cat /sys/devices/system/cpu/online` of `cat /sys/devices/system/cpu/present`
                    \rSyntax: disen_ht.sh en start_cpu_num end_cpu_num
                    \rSyntax: disen_ht.sh dis cpu_num"
            exit;;
esac

if [ $USER != "root" ]
then
    echo "You must be root to run this script"
    exit
fi

if [ -z "$3" ]
then
    last_core="$2"
else
    last_core="$3"
fi

for i in `seq $2 $last_core`
do
    echo $command > /sys/devices/system/cpu/cpu$i/online
done

echo "Online CPUs:  `cat /sys/devices/system/cpu/online` of `cat /sys/devices/system/cpu/present`"
