#!/bin/bash

#Script convert sequence of numbers to splitted 32-bit words
#Can be used for load Filter coefficients to 32-bit registers
#Use Octave and decs_32bit.m file

decs=`octave -q --eval "disp(decs_32bit([ 1 2 3 4 5 6 7 8 -1 -2 -3 -4 -5 -6 -7 -8],14))"`

length_pre=`wc -m decs | cut -d " " -f1`
length=`expr \( $length_pre - 1 \) / 32`

hexs=`echo "obase=16;ibase=2; $decs" | bc`

#Show 32-bit words
for j in `seq $length -1 1`
do
    k8=`expr $j \* 8`
    k1=`expr $k8 - 7`
    echo $hexs | cut -c$k1-$k8
done
