#!/bin/bash

#Change input frequency constraint for HTG-700 FPGA
#Real input clock 10ns (100MHz) we change to 9.5ns (105.263MHz)

hardware_input_freq="100"
hardware_input_ns=`echo "scale=1; 1000/$hardware_input_freq" | bc`

p0="/home/vglazov/Triumph3/sim/fpga/htg-700-2000t/chip.v"
p1="/home/vglazov/cpu_full_smp/cpu_full_smp.srcs/sources_1/ip/clk_wiz_0_2/clk_wiz_0.xdc"
p2="/home/vglazov/cpu_full_smp/cpu_full_smp.srcs/sources_1/ip/clk_wiz_0_2/clk_wiz_0.v"
p3="/home/vglazov/cpu_full_smp/cpu_full_smp.srcs/sources_1/ip/clk_wiz_0_2/clk_wiz_0_clk_wiz.v"

out_f_mult=`grep CLKFBOUT_MULT  $p3 | tr \(\) " " | awk '{print $2}'`
out_f_cdiv=`grep CLKOUT0_DIVIDE $p3 | tr \(\) " " | awk '{print $2}'`
out_f_ddiv=`grep DIVCLK_DIVIDE  $p3 | tr \(\) " " | awk '{print $2}'`

if [ -z "$1" ]
then
    new_freq_ns=9.5
else
    new_freq_ns="$1"
fi

real_clk=`echo "$hardware_input_freq * $out_f_mult / $out_f_cdiv / $out_f_ddiv" | bc`
virt_clk=`echo "scale=3; 1000/$new_freq_ns * $out_f_mult / $out_f_cdiv / $out_f_ddiv" | bc`
echo "Real out clock: ${real_clk}.000 MHz
Virt out clock: ${virt_clk} MHz"

if [ "$2" = "test" ]
then
    echo "Test only"
else
    sed -ie "s!..; //Set CPU Freq!${real_clk}; //Set CPU Freq!" $p0

    for clk_wiz_file in $p1 $p2 $p3
    do
        sed -i "s/$hardware_input_ns/$new_freq_ns/g" $clk_wiz_file
    done
fi
