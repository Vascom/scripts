#!/bin/bash

#Reset color
Color_Off='\e[0m'       # Text Reset

#Colors
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow

if [ -z "$1" ]
then
    echo "Please give at least one FPGA implementation number."
    exit 1
fi

PROJECT_DIR=`basename $PWD`
WORK_PATH=$PROJECT_DIR.runs/impl_
ROUTE_FILE=/.route_design.end.rst

#If run via symlink use anothe ssh connection to send e-mail
if [ `basename $0` = "vivado_notify_fulcrum.sh" ]
then
    SERVER="vglazov@fulcrum"
    EMAIL="v.glazov2@javad.com"
else
    SERVER="vascom@v-glazov"
    EMAIL="vascom2@gmail.com"
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
            LOG_FILE="$PROJECT_DIR.runs/impl_$arg/chip_timing_summary_routed.rpt"
            TIMING=`grep "Design Timing Summary" -A 6 $LOG_FILE | tail -n 1 | awk '{print $1" "$5}'`

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
            n=$[$n+1]
        fi
    done

    if [ $n -ne $# ]
    then
        sleep 60
    fi
done
