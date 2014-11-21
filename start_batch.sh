#!/bin/bash

PROJECT_NAME="leon3mp"
EN64="--64bit"
READ_WRITE_SETTINGS="--read_settings_files=on --write_settings_files=off"
GIT_REPO="$HOME/Triumph2-MkII"
ASIC_CONFIG="$HOME/Triumph2-MkII/rtl/inc/global_config_dsp.inc"
JIC_CONF="output_file_sl340.cof"
ERROR_PRINT=1
ONLYMAP=0

#Check map or fit logs for errors
case "$1" in
    errmap)     grep "Error" "$PROJECT_NAME.map.rpt"
                exit;;
    errfit)     grep "Error" "$PROJECT_NAME.fit.rpt"
                exit;;
    onlymap)    ONLYMAP=1;;
    kill)       kill -s 15 `cat map.pid 2>/dev/null` 2>/dev/null
                kill -s 15 `cat fit.pid 2>/dev/null` 2>/dev/null
                exit
                ;;
    "")         ;;
    *)          echo -e "\n\e[31mWrong parameter\e[0m"
                echo "Available options: errmap errfit onlymap kill"
                exit;;
esac

if [[ $1 == errmap ]]
then
    grep "Error" "$PROJECT_NAME.map.rpt"
    exit
elif [[ $1 == errfit ]]
then
    grep "Error" "$PROJECT_NAME.fit.rpt"
    exit
fi

#Check Quartus binaries in user PATH
for q_bin in quartus_map quartus_cdb quartus_fit quartus_sta quartus_asm quartus_cpf
do
    if ! `which $q_bin &>/dev/null`
    then
        echo "Quartus binary $q_bin not found, check your PATH"
        exit
    fi
done

function send_email() {
    ssh vascom@172.17.0.236 "DISPLAY=:0 notify-send Задание\ выполнено\ $1 Проект\ `basename $PWD`"
}

function timer() {
    if [ -e "$PROJECT_NAME.$1.rpt" ]
    then
        mv "$PROJECT_NAME.$1.rpt" "$PROJECT_NAME.$1.old.rpt"
    fi
    local PTIME=0
    while [ ! -e "$PROJECT_NAME.$1.rpt" ]
    do
        echo -ne "\r$PTIME min "
        PTIME=`expr $PTIME + 1`
        sleep 1m
    done
}
#======================================================================================================
WINDOWS_NUMBER=`grep -m 1 WINDOWS_NUMBER $ASIC_CONFIG | awk '{print $4}' | cut -d ";" -f1`
CHAN_NUMBER_IN_WINDOW=`grep -m 1 CHAN_NUMBER_IN_WINDOW $ASIC_CONFIG | awk '{print $4}' | cut -d ";" -f1`
CHANNELS_NUMBER=`expr $WINDOWS_NUMBER \* $CHAN_NUMBER_IN_WINDOW`
CHANNELS_NUMBER_EXT=`grep -m 1 CHANNELS_NUMBER_EXT $ASIC_CONFIG | awk '{print $4}' | cut -d ";" -f1`
CHANNELS_QL_NUMBER=`grep -m 1 CHANNELS_QL_NUMBER $ASIC_CONFIG | awk '{print $4}' | cut -d ";" -f1`
CHANNELS_NUMBER_ALL=`expr $CHANNELS_NUMBER + $CHANNELS_NUMBER_EXT`
CHANNELS_QL_ENABLE=`grep -m 1 CHANNELS_QL_ENABLE $ASIC_CONFIG | awk '{print $4}' | cut -d ";" -f1 | cut -d "b" -f2`
CHANNELS_QL=`expr $CHANNELS_QL_NUMBER \* $CHANNELS_QL_ENABLE`;
FAST_ACQUISITION_LENGTH=`grep -m 1 FAST_ACQUISITION_LENGTH $ASIC_CONFIG | awk '{print $4}' | cut -d ";" -f1`
FILTERS_WB_ENABLE=`grep FILTERS_WB_ENABLE $ASIC_CONFIG | awk '{print $4}' | cut -d ";" -f1 | cut -d "h" -f2`
FFT_OUT_ENABLE=`grep FFT_OUT_ENABLE $ASIC_CONFIG | awk '{print $4}' | cut -d ";" -f1 | cut -d "b" -f2`
AJM_ENABLE=`grep AJM_ENABLE $ASIC_CONFIG | awk '{print $4}' | cut -d ";" -f1 | cut -d "b" -f2`
FAJ_NUMBER=`grep -m 1 FIR_AJM_NUMBER $ASIC_CONFIG | awk '{print $4}' | cut -d ";" -f1`

case "$FILTERS_WB_ENABLE" in
    001)        FILTERS_WB_NUMBER=1;;
    003)        FILTERS_WB_NUMBER=2;;
    007)        FILTERS_WB_NUMBER=3;;
    00f|00F)    FILTERS_WB_NUMBER=4;;
    *)          echo "Filters number not defined"
                exit
                ;;
esac

cd $GIT_REPO
    GIT_COMMIT=`git log | head -n 3`
    GIT_COMMIT_SHORT=`git log | head -n 1 | cut -d " " -f2`
cd -

echo -e "$GIT_COMMIT\n" | tee config_last

echo -e "Date     : `date`
    \rChannels : $CHANNELS_NUMBER_ALL + ${CHANNELS_QL}QL
    \rFA Length: $FAST_ACQUISITION_LENGTH
    \rFilters  : $FILTERS_WB_NUMBER + ${FAJ_NUMBER}FAJ
    \rAJM ena  : $AJM_ENABLE
    \rFFT ena  : $FFT_OUT_ENABLE" | tee --append config_last

cat $ASIC_CONFIG >> config_last

echo -en "\e[32mStart\e[0m mapping PID: "

quartus_map $EN64 --parallel=on $READ_WRITE_SETTINGS $PROJECT_NAME -c $PROJECT_NAME &>longlog.map.log &
echo "$!" | tee map.pid
timer map

ERROR_PRESENT=`grep -c "Error:" "$PROJECT_NAME.map.rpt"`
if [ $ERROR_PRESENT == 0 ]
then
    echo -e "\n\e[32mStart\e[0m merging"
    quartus_cdb $EN64 $READ_WRITE_SETTINGS $PROJECT_NAME -c $PROJECT_NAME --merge=on 2>&1 1>>longlog.map.log
else
    echo -e "\n\e[31mFinished with errors in mapping\e[0m"
    if [[ $ERROR_PRESENT == 1 ]]
    then
        grep "Error " "$PROJECT_NAME.map.rpt"
        send_email "с ошибкой в mapping"
    fi
    exit
fi
#======================================================================================================
ERROR_PRESENT=`grep -c "Error:" "$PROJECT_NAME.merge.rpt"`
if [ $ERROR_PRESENT == 0 ]
then
    #Exit if only mapping is need
    if [[ $ONLYMAP == 1 ]]
    then
        echo -e "\e[32mOnly Mapping done.\e[0m"
        exit
    fi
    echo -en "\e[32mStart\e[0m fitting PID: "
    quartus_fit $EN64 --parallel=4 $READ_WRITE_SETTINGS $PROJECT_NAME -c $PROJECT_NAME &>longlog.fit.log &
    echo "$!" | tee map.pid
    timer fit
else
    echo -e "\e[31mFinished with errors in merging\e[0m"
    send_email "с ошибкой в merging"
    exit
fi
#======================================================================================================
ERROR_PRESENT=`grep -c "Error:" "$PROJECT_NAME.fit.rpt"`
if [ $ERROR_PRESENT == 0 ]
then
    echo -e "\n\e[32mStart\e[0m STA and assembling"
    quartus_sta $EN64 --parallel=4 $PROJECT_NAME -c $PROJECT_NAME 1>/dev/null
    quartus_asm $EN64 $READ_WRITE_SETTINGS $PROJECT_NAME -c $PROJECT_NAME 1>/dev/null
    head -n 2 $PROJECT_NAME.sta.rpt | tee --append config_last
    #head -n 159 $PROJECT_NAME.sta.rpt | tail -n 9
    grep "Restricted Fmax" "$PROJECT_NAME.sta.rpt" -m 1 -A 9 | cut -d ";" -f2,3,4 -s | tee --append config_last

    echo "Generating jic programming file"
    jic_seq_pre=`cat jic_sec_number`
    JIC_SEQ=`expr $jic_seq_pre + 1`
    echo $JIC_SEQ > jic_sec_number
    JIC_NAME=`echo avt2_${JIC_SEQ}_chan${CHANNELS_NUMBER_ALL}_filt${FILTERS_WB_NUMBER}_fft${FFT_OUT_ENABLE}_mf${FAST_ACQUISITION_LENGTH}_${GIT_COMMIT_SHORT}`
    sed -i -e "s/<output_filename>.*<\/output_filename>/<output_filename>$JIC_NAME.jic<\/output_filename>/" $JIC_CONF
    quartus_cpf -c $JIC_CONF > /dev/null
    cp config_last $JIC_NAME.config
    echo -e "\e[31m$JIC_NAME.jic\e[0m"

    echo -e "\e[32mAll finished\e[0m"
    send_email "успешно"
else
    echo -e "\n\e[31mFinished with errors in fitting\e[0m"
    send_email "с ошибкой в fitting"
fi
