%system("cp co2mon/build/co2mon_07092015.log .");
%system("grep CntR co2mon_07092015.log | awk '{print $2}' > co2mon_test");
system("grep CntR co2mon_20151105.log | awk '{print $2}' > co2mon_test");
# system("grep Tamb co2mon_20151105.log | awk '{print $2}' > co2mon_test_tamb");

load('co2mon_test');
# load('co2mon_test_tamb');
%plot(co2mon_test)

len_num = length(co2mon_test);
%f=(1:len_num)*5/60/60+14.48;
f=(1:len_num)*5/60/60+12;

for k=1:len_num
    if(f(k)>=24)
            f2(k) = f(k) - 24;
    else
            f2(k) = f(k);
    end
end

plot(f2,co2mon_test)
axis("tight")
grid
