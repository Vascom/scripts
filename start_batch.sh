#!/bin/bash

PROJECT_NAME="leon3mp"
EN64="--64bit"
READ_WRITE_SETTINGS="--read_settings_files=on --write_settings_files=off"
GIT_REPO="$HOME/triumph40n_git"
ASIC_CONFIG="$HOME/triumph40n_git/rtl/inc/global_config_dsp.inc"
JIC_CONF="output_file_sl340.cof"
ERROR_PRINT=1

#Check map or fit logs for errors
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
    ssh vascom@172.17.0.196 "DISPLAY=:0 notify-send Задание\ выполнено\ $1 Проект\ `basename $PWD`"
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
CHANNELS_QL_ENABLE=`grep -m 1 CHANNELS_QL_ENABLE $ASIC_CONFIG | awk '{print $4}' | cut -d ";" -f1 | cut -d "b" -f2`
CHANNELS_QL=`expr $CHANNELS_QL_NUMBER \* $CHANNELS_QL_ENABLE`;
FAST_ACQUISITION_LENGTH=`grep -m 1 FAST_ACQUISITION_LENGTH $ASIC_CONFIG | awk '{print $4}' | cut -d ";" -f1`
FILTERS_WB_ENABLE=`grep FILTERS_WB_ENABLE $ASIC_CONFIG | awk '{print $4}' | cut -d ";" -f1 | cut -d "h" -f2`
FFT_OUT_ENABLE=`grep FFT_OUT_ENABLE $ASIC_CONFIG | awk '{print $4}' | cut -d ";" -f1 | cut -d "b" -f2`

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
    \rChannels : `expr $CHANNELS_NUMBER + $CHANNELS_NUMBER_EXT` + ${CHANNELS_QL}QL
    \rFA Length: $FAST_ACQUISITION_LENGTH
    \rFilters  : $FILTERS_WB_NUMBER
    \rFFT ena  : $FFT_OUT_ENABLE" | tee --append config_last

cat $ASIC_CONFIG >> config_last

echo "Start mapping "

quartus_map $EN64 --parallel=on $READ_WRITE_SETTINGS $PROJECT_NAME -c $PROJECT_NAME &>longlog.map.log &
timer map

ERROR_PRESENT=`grep -c "Error:" "$PROJECT_NAME.map.rpt"`
if [ $ERROR_PRESENT == 0 ]
then
    echo -e "\nStart merging"
    quartus_cdb $EN64 $READ_WRITE_SETTINGS $PROJECT_NAME -c $PROJECT_NAME --merge=on 2>&1 1>>longlog.map.log
else
    echo -e "\nFinished with errors in mapping"
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
    echo "Start fitting "
    quartus_fit $EN64 --parallel=4 $READ_WRITE_SETTINGS $PROJECT_NAME -c $PROJECT_NAME &>longlog.fit.log &
    timer fit
else
    echo "Finished with errors in merging"
    send_email "с ошибкой в merging"
    exit
fi
#======================================================================================================
ERROR_PRESENT=`grep -c "Error:" "$PROJECT_NAME.fit.rpt"`
if [ $ERROR_PRESENT == 0 ]
then
    echo -e "\nStart STA and assembling"
    quartus_sta $EN64 --parallel=4 $PROJECT_NAME -c $PROJECT_NAME 1>/dev/null
    quartus_asm $EN64 $READ_WRITE_SETTINGS $PROJECT_NAME -c $PROJECT_NAME 1>/dev/null &
    head -n 2 $PROJECT_NAME.sta.rpt | tee --append config_last
    #head -n 159 $PROJECT_NAME.sta.rpt | tail -n 9
    grep "Restricted Fmax" "$PROJECT_NAME.sta.rpt" -m 1 -A 9 | cut -d ";" -f2,3,4 -s | tee --append config_last

    echo "Generating jic programming file"
    jic_seq_pre=`cat jic_sec_number`
    JIC_SEQ=`expr $jic_seq_pre + 1`
    echo $JIC_SEQ > jic_sec_number
    JIC_NAME=`echo avt2_${JIC_SEQ}_chan${CHANNELS_NUMBER}_filt${FILTERS_WB_NUMBER}_fft${FFT_OUT_ENABLE}_mf${FAST_ACQUISITION_LENGTH}_${GIT_COMMIT_SHORT}.jic`
    sed -i -e "s/<output_filename>.*<\/output_filename>/<output_filename>$JIC_NAME<\/output_filename>/" $JIC_CONF
    quartus_cpf -c $JIC_CONF > /dev/null
    echo "$JIC_NAME"

    echo "All finished"
    send_email "успешно"
else
    echo -e "\nFinished with errors in fitting"
    send_email "с ошибкой в fitting"
fi
