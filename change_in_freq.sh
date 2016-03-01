#!/bin/bash

#Change input frequency constraint for HTG-700 FPGA
#Real clock 100MHz (10ns) we change to 9.5ns

p1="/home/vglazov/cpu_full_smp/cpu_full_smp.srcs/sources_1/ip/clk_wiz_0_2/clk_wiz_0.xdc"
p2="/home/vglazov/cpu_full_smp/cpu_full_smp.srcs/sources_1/ip/clk_wiz_0_2/clk_wiz_0.v"
p3="/home/vglazov/cpu_full_smp/cpu_full_smp.srcs/sources_1/ip/clk_wiz_0_2/clk_wiz_0_clk_wiz.v"

if [ -z "$1" ]
then
    new_freq=9.5
else
    new_freq="$1"
fi

for i in $p1 $p2 $p3
do
    sed -i "s/10.0/$new_freq/g" $i
done
