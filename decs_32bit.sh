#!/bin/bash

#Script convert sequence of numbers to splitted 32-bit words
#Can be used for load Filter coeffiicients to 32-bit registers
#Use Octave and decs_32bit.m file

decs=`octave -q --eval "disp(decs_32bit([ 1 2 3 4 5 6 7 8 -1 -2 -3 -4 -5 -6 -7 -8],14))"`
length_pre=`wc -m decs | cut -d " " -f1`
length=`expr $length_pre - 1`
len=`expr $length / 4`
len8=`expr $len / 8`

#Convert 4-bit binary to hex
for i in `seq 1 $len`
do
    i1=`expr $i \* 4 - 3`
    i2=`expr $i \* 4 - 2`
    i3=`expr $i \* 4 - 1`
    i4=`expr $i \* 4`
    symbol=`echo $decs | cut -c$i1,$i2,$i3,$i4`

    case $symbol in
        0000)   hex[i]=0
        ;;
        0001)   hex[i]=1
        ;;
        0010)   hex[i]=2
        ;;
        0011)   hex[i]=3
        ;;
        0100)   hex[i]=4
        ;;
        0101)   hex[i]=5
        ;;
        0110)   hex[i]=6
        ;;
        0111)   hex[i]=7
        ;;
        1000)   hex[i]=8
        ;;
        1001)   hex[i]=9
        ;;
        1010)   hex[i]=A
        ;;
        1011)   hex[i]=B
        ;;
        1100)   hex[i]=C
        ;;
        1101)   hex[i]=D
        ;;
        1110)   hex[i]=E
        ;;
        1111)   hex[i]=F
        ;;
    esac
done

#Show 32-bit words
for j in `seq $len8 -1 1`
do
    for k in `seq 7 -1 0`
    do
        echo -en ${hex[j*8-k]}
    done
    echo ""
done