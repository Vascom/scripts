#!/bin/bash
# https://www.convertcsv.com/html-table-to-csv.htm

work_file="/tmp/real_url_speed"

VERSION_ID=`grep VERSION_ID /etc/os-release | cut -d '=' -f2`
NAME=`grep NAME /etc/os-release | cut -d '=' -f2`
ARCH=`rpm -E %_arch`

# Test file parameters
# test_file="releases/$VERSION_ID/Everything/$ARCH/os/Packages/k/k3b-21.12.2-1.fc36.x86_64.rpm"
# test_file_size=10
test_file="releases/$VERSION_ID/Everything/$ARCH/os/Packages/k/kernel-debug-core-5.17.5-300.fc36.x86_64.rpm"
test_file_size=`echo 50248477/1024/1024 | bc -l`

DATA=`cat  convertcsvn.csv\
| sed 's|Fedora Linux|FedoraLinux|' \
| sed 's|Fedora EPEL|FedoraEPEL|' \
| sed 's|Fedora Secondary Arches|FedoraSecondaryArches|' \
| sed 's|a href|ahref|g'`

function download_time(){
    if [ "$1" = "http://mirror.alwyzon.net/fedora" ] || [ "$1" = "https://mirror.alwyzon.net/fedora" ] \
    || [ "$1" = "http://mirrors.nfetix.net/fedora" ] || [ "$1" = "https://mirrors.netix.net/fedora" ] \
    || [ "$1" = "http://linuxsoft.cern.ch/fedora" ] || [ "$1" = "https://linuxsoft.cern.ch/fedora" ] \
    || [ "$1" = "http://mirrors.ptisp.pt/fedora" ] || [ "$1" = "https://mirrors.ptisp.pt/fedora" ] \
    || [ "$1" = "http://mirror.ps.kz/fedora" ] || [ "$1" = "https://mirror.ps.kz/fedora" ] \
    || [ "$1" = "http://mirrors.nipa.cloud/fedora" ] || [ "$1" = "https://mirrors.nipa.cloud/fedora" ]
    then
        local_url="$1/linux"
    elif [ "$1" = "http://ftp.iij.ad.jp/pub/linux/Fedora" ]
    then
        local_url="$1/fedora/linux"
    else
        local_url="$1"
    fi

    start_time=`date +%s`
    wget -O /dev/null $local_url/$test_file -q
    finish_time=`date +%s`
    download_time=`expr $finish_time - $start_time`

    echo $test_file_size/$download_time | bc -l
}

FL_found=0

if [ -e $work_file ]
then
    rm $work_file
fi

for i in $DATA
do
    line_start=`echo $i | grep -E "^[A-Z]" -c`
#     echo $line_start
    if [ "$FL_found" -eq 1 ] && [ ! "$line_start" = 1 ]
    then
#         echo $i
        url_type=`echo $i | cut -d '>' -f2 | cut -d '<' -f1`
#         echo $i
        if [ $url_type = http ] || [ $url_type = https ]
        then
            echo $i
            real_url=`echo $i | cut -d '"' -f3`
            real_speed=`download_time $real_url`

            echo "$real_speed $real_url" >> $work_file
        fi
    fi

    FL_true=`echo $i | grep FedoraLinux -c`
    ahref_true=`echo $i | grep ahref -c`

    if [ "$FL_true" -eq 1 ] || [ "$FL_found" -eq 1 -a "$ahref_true" -eq 1 ]
    then
        FL_found=1
    else
        FL_found=0
    fi
done

sort -nr $work_file

