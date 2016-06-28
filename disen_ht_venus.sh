#!/bin/bash

temp_thr_1=55
temp_thr_2=52
cpu2="/sys/devices/system/cpu/cpu2/online"
cpu3="/sys/devices/system/cpu/cpu3/online"

function check_switch(){
    local check_cpu=1
    local set_spu=0
    check_online=`cat $2`

    if [ $1 = "en" ]
    then
        check_cpu=0
        set_spu=1
    fi

    if [ $check_online -eq $check_cpu ]
    then
        sudo echo $set_spu > $2
    fi
}

for k in `seq 1 600`
do

temperature=`sensors | grep "CPU Temperature" | cut -d "+" -f2 | cut -d "." -f1`

if [ $temperature -gt $temp_thr_1 ]
then
#     check_switch dis $cpu3
#     check_switch dis $cpu2
    echo "$temperature Disable 2 3"
elif [ $temperature -gt $temp_thr_2 ]
then
#     check_switch dis $cpu3
#     check_switch en $cpu2
    echo "$temperature Disable 3 Enable 2"
else
#     check_switch en $cpu3
#     check_switch en $cpu2
    echo "$temperature Enable 2 3"
fi

sleep 10
done

# case "$1" in
#     en)     command="1";;
#     dis)    command="0";;
#     *)      echo -e "Online CPUs:  `cat /sys/devices/system/cpu/online` of `cat /sys/devices/system/cpu/present`
#                     \rSyntax: disen_ht.sh en start_cpu_num end_cpu_num
#                     \rSyntax: disen_ht.sh dis cpu_num"
#             exit;;
# esac
#
# if [ $USER != "root" ]
# then
#     echo "You must be root to run this script"
#     exit
# fi
#
# if [ -z "$3" ]
# then
#     last_core="$2"
# else
#     last_core="$3"
# fi
#
# for i in `seq $2 $last_core`
# do
#     echo $command > /sys/devices/system/cpu/cpu$i/online
# done
#
# echo "Online CPUs:  `cat /sys/devices/system/cpu/online` of `cat /sys/devices/system/cpu/present`"
