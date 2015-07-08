#!/bin/bash

#Script convert sequence of numbers to splitted 32-bit words
#Can be used for load Filter coefficients to 32-bit registers
#Use Octave and decs_32bit.m file

if [ -z "$1" ]
then
    bit_width=14
else
    bit_width="$1"
fi

if [ -z "$2" ]
then
    data_in="0,0,0,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,2,2,2,2,2,3,2,3,2,3,2,3,2,3,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,5,4,5,4,5,4,6,4,7,4,7,4,9,4,11,5,13,5,16,5,19,5,24,5,32,5,43,5,61,5,92,5,154,5,303,5,846,5,7629"
else
    data_in="$2"
fi

decs=`octave -q --eval "disp(decs_32bit([$data_in],$bit_width))"`
echo $decs > /tmp/decs
length_pre=`wc -m /tmp/decs | cut -d " " -f1`
length=`expr \( $length_pre - 1 \) / 32`

# hexs=`echo "obase=16;ibase=2; $decs" | bc`
# 
# #Show 32-bit words
# for j in `seq $length -1 1`
# do
#     k8=`expr $j \* 8`
#     k1=`expr $k8 - 7`
#     echo $hexs | cut -c$k1-$k8
# done

bin_cnt=`expr \( $length_pre - 1 \) / 4`

for i in `seq 1 $bin_cnt`
do
    cstop=`expr $i \* 4`
    cstart=`expr $cstop - 3`

    one_bin=`echo $decs | cut -c$cstart-$cstop`
    one_hex=`echo "obase=16;ibase=2; $one_bin" | bc`
    hex_full=`echo -n $hex_full$one_hex`
done

#Show 32-bit words
for j in `seq $length -1 1`
do
    k8=`expr $j \* 8`
    k1=`expr $k8 - 7`
    echo $hex_full | cut -c$k1-$k8
done


