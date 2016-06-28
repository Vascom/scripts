#!/bin/bash

PROJECT_DIR=`basename $PWD`

function safe_exit() {
    impl_pids=`find . -name "*.pid"`
    for pid in $impl_pids
    do
        pkill -F $pid > /dev/null
        rm $pid
    done
    echo -e "\nAll \e[31minterrupted manually\e[0m"
    exit
}
trap "safe_exit" INT

function synthesis() {
    echo -e "Synthesis synth_$1 \e[32mstart\e[0m"
    $PWD/$PROJECT_DIR.runs/synth_$1/runme.sh &
    echo "$!" > synth_$1.pid
    wait
    rm synth_$1.pid
    echo -e "Synthesis synth_$1 \e[32mdone\e[0m"
}

function impl_timer() {
    sleep 1m
    local finished=`grep Exiting $PWD/$PROJECT_DIR.runs/impl_$1/runme.log`
    while [ -z "$finished" ]
    do
        sleep 1m
        finished=`grep Exiting $PWD/$PROJECT_DIR.runs/impl_$1/runme.log`
    done
    echo -e "Implementation impl_$1 \e[32mfinish\e[0m"
    rm impl_$1.pid timer_$1.pid
}

function implementation() {
    for impl_name in $@
    do
        echo -e "Implementation impl_$impl_name \e[32mstart\e[0m"
        $PWD/$PROJECT_DIR.runs/impl_$impl_name/runme.sh &
        echo "$!" > impl_$impl_name.pid
        impl_timer $impl_name &
        echo "$!" > timer_$impl_name.pid
    done
    wait
    #rm impl*.pid timer*.pid
}

if [ $# -lt 2 ]
then
    echo -e "\e[31mNot enougth params\e[0m"
    echo "Available options: synth impl all"
    echo "Example: all 1 2 3"
    exit
fi

n=0
for arg in "$@"
do
    if [ $n -ne 0 ]
    then
        runs=`echo $runs $arg`
    fi
    n=$[$n+1]
done

case "$1" in
    synth)  synthesis
            echo -e "Only synthesis \e[32mdone\e[0m";;
    impl)   implementation $runs
            echo -e "Only implementations \e[32mdone\e[0m";;
    all)    synthesis
            implementation $runs
            echo -e "All synthesis and implementations \e[32mdone\e[0m";;
    *)      echo -e "\e[31mWrong parameter\e[0m"
            echo "Available options: synth impl all"
            echo "Example: all 1 2 3"
            exit;;
esac
