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

#If run via symlink use anothe ssh connection to send e-mail
if [ `basename $0` = "vivado_notify_fulcrum.sh" ]
then
    SERVER="vglazov@fulcrum"
    EMAIL="v.glazov@javad.com"
else
    SERVER="vascom@v-glazov"
    EMAIL="vascom2@gmail.com"
fi

#Rename MCS file with GOOD/POOR/FAIL tag
function rename_mcs() {
    while [ ! -e mcs/chip_auto_i$1.mcs ]
    do
        sleep 10
    done
    sleep 30
    mv mcs/chip_auto_i$1.mcs mcs/chip_auto_i$1_$2.mcs
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
elif [ "$1" = "check" ] && [ -n "$2" ]
then
    shift
    echo -e "${Green}Watching$Color_Off $@"
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

            #Send e-mail with message about task
            ssh $SERVER "echo -e Разводка\ завершена\ $HOSTNAME\ $PROJECT_DIR\ $arg\ $TIMING | mutt -x -s Route_${STATUS}_${HOSTNAME}_${PROJECT_DIR}_$arg ${EMAIL}"
            state[$arg]=1
            rename_mcs $arg $STATUS &

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
