#!/bin/bash

PROJECT_DIR=`basename $PWD`
ROUTE_FILE=$PROJECT_DIR.runs/impl_
MSG_FILE=$PROJECT_DIR.runs/impl_

n=0
while [ $n -ne $# ]
do
    for arg in "$@"
    do
        if [ -e $ROUTE_FILE$arg/.route_design.end.rst ] && [ ! -e $MSG_FILE$arg/msg_send ]
        then
            echo a0
            ssh vascom@v-glazov "echo Разводка\ завершена\ asic-tm\ $arg | mutt -x -s Route_asic-tm_$arg vascom2@gmail.com"
            touch $MSG_FILE$arg/msg_send
            n=$[$n+1]
        fi
    done
    sleep 60
done

for arg in "$@"
do
    if [ -e $MSG_FILE$arg/msg_send ]
    then
        rm $MSG_FILE$arg/msg_send
    fi
done
