#!/bin/bash

#Reset color
Color_Off='\e[0m'       # Text Reset

#Colors
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow

PROJECT_DIR=`basename $PWD`
WORK_PATH="$PROJECT_DIR.runs/impl_"
ROUTE_FILE="/.route_design.end.rst"
TIMING_FILE="/chip_timing_summary_routed.rpt"
CONFIG_MCS_FILE=config_mcs.txt

#Parsing config file
if [ ! -e "$CONFIG_MCS_FILE" ]
then
    echo -e "Config file ${Red}config_mcs.txt$Color_Off not found"
    exit 1
fi

all_configs=`tail -n 1 "$CONFIG_MCS_FILE"`
for i in `seq 1 8`
do
    PAR[$i]=`echo $all_configs | cut -d " " -f$i`
done
MCS_CONF_NAME=${PAR[1]}_${PAR[2]}cpu_${PAR[3]}Miram_${PAR[6]}ch_${PAR[7]}filt_${PAR[5]}MHz_${PAR[4]}mm_${PAR[8]}_i

#If run via symlink use anothe ssh connection to send e-mail
if [ `basename $0` = "vivado_notify_fulcrum.sh" ]
then
    SERVER="vglazov@fulcrum"
    EMAIL="v.glazov@javad.com"
else
    SERVER="vascom@v-glazov"
    EMAIL="vascom2@gmail.com"
fi

#Send e-mail with message about task
function send_email() {
    ssh $SERVER "echo -e Разводка\ завершена\ $HOSTNAME\ $PROJECT_DIR\ $1\ $3 | mutt -x -s Route_${2}_${HOSTNAME}_${PROJECT_DIR}_$1 ${EMAIL}"
}

#Rename MCS file with GOOD/POOR/FAIL
function rename_mcs() {
    while [ ! -e mcs/chip_auto_i$1.mcs ]
    do
        sleep 10
    done
    sleep 60

    mv mcs/chip_auto_i$1.mcs mcs/$MCS_CONF_NAME$1_$2.mcs
    if [ "$HOSTNAME" = "systech6" ]
    then
        scp mcs/$MCS_CONF_NAME$1_$2.mcs asic-tm:/home/vglazov/mcs_backup/
    elif [ "$PROJECT_DIR" = "cpu_full_4175" ]
    then
        cp mcs/$MCS_CONF_NAME$1_$2.mcs ../mcs_backup/
    else
        cp mcs/$MCS_CONF_NAME$1_$2.mcs ../mcs_sitara/
    fi
    send_email $1 $2 $3
}

if [ "$1" = "full" ] && [ -n "$2" ]
then
    shift
    for arg in "$@"
    do
        #Add bitstream generation and MCS file write instructions
        echo -e "start_step write_bitstream
            \rset rc [catch {
            \r  create_msg_db write_bitstream.pb
            \r  catch { write_mem_info -force chip.mmi }
            \r  write_bitstream -force chip.bit
            \r  catch { write_sysdef -hwdef chip.hwdef -bitfile chip.bit -meminfo chip.mmi -file chip.sysdef }
            \r  catch {write_debug_probes -quiet -force debug_nets}
            \r  close_msg_db -file write_bitstream.pb
            \r} RESULT]
            \rif {\$rc} {
            \r  step_failed write_bitstream
            \r  return -code error \$RESULT
            \r} else {
            \r  end_step write_bitstream
            \r}
            \r
            \rif {[regexp {^2016\.[12].*} [version -short]]} { set_param bitgen.maxThreads 1 }
            \rwrite_cfgmem -format mcs -interface bpix16 -size 1024 -loadbit \"up 0x0 $PWD/$WORK_PATH$arg/chip.bit\" -force -file \"$PWD/mcs/chip_auto_i$arg.mcs\"
            \r" >> $WORK_PATH$arg/chip.tcl

        #Check and run implementation in background
        if [ ! -e "$WORK_PATH$arg/.init_design.begin.rst" ]
        then
            $WORK_PATH$arg/runme.sh &
        else
            echo -e "Please ${Red}create start scripts$Color_Off in Vivado for ${Red}impl_$arg$Color_Off"
            exit 1
        fi
    done
    echo -e "${Green}Tasks runned, now watching$Color_Off $@"
    usemcs="1"
elif [ "$1" = "check" ] && [ -n "$2" ]
then
    shift
    echo -e "${Green}Watching$Color_Off $@"
    usemcs="0"
else
    echo -e "Please give ${Red}full/check$Color_Off and at least one FPGA implementation number."
    exit 1
fi

#Repeat checking while not finished all tasks
n=0
while [ $n -ne $# ]
do
    #Counting all given tasks
    for arg in "$@"
    do
        #Check that task finished and it is first time
        if [ -e $WORK_PATH$arg$ROUTE_FILE ] && [ -z ${state[$arg]} ]
        then
            #Getting finish timing values
            TIMING=`grep "Design Timing Summary" -A 6 $WORK_PATH$arg$TIMING_FILE | tail -n 1 | awk '{print $1" "$5}'`

            WNS_STATUS=`echo "$TIMING" | awk '{print $1}' | grep - -c`
            WHS_STATUS=`echo "$TIMING" | awk '{print $2}' | grep - -c`

            #Set status depends on timing values
            if [ $WNS_STATUS -eq 0 ]
            then
                if [ $WHS_STATUS -eq 0 ]
                then
                    STATUS=GOOD
                    COLOR=$Green
                else
                    STATUS=POOR
                    COLOR=$Yellow
                fi
            else
                STATUS=FAIL
                COLOR=$Red
            fi

            echo -e Routed $HOSTNAME $arg $COLOR$STATUS$Color_Off

            state[$arg]=1
            #Send e-mail immediately if checking or wait MCS if full
            TIMING=`echo $TIMING | tr " " _`
            if [ $usemcs = "1" ]
            then
                rename_mcs $arg $STATUS $TIMING &
            else
                send_email $arg $STATUS $TIMING
            fi

            n=$[$n+1]
        fi
    done

    if [ $n -ne $# ]
    then
        sleep 60
    fi
done

#Wait all background tasks finished
wait
