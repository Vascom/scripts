agc_max = 16256;
gain_0 = [10 24 6 3 12 6];
y_pre = [0 10; 1 9; 9 15; 0 1; 10.8 22; 1 3];
y_const = [10 22; 0 1; 1 15];
kb = zeros(length(gain_0),2);

gain_1 = gain_0;
for i=2:length(gain_0)
    gain_1(i) = gain_1(i) + gain_1(i-1);
end

gain_step = agc_max/sum(gain_0);
agc_step = [0 round(gain_1*gain_step)];

for i=1:length(gain_0)
    x = agc_step(i:i+1);
    y = y_pre(i,:);

    k = (y(1)-y(2))/(x(1)-x(2));
    b = y(2)-k*x(2);

    kb(i,:) = round([(k*2^15) b]);
end
display(kb)
display(agc_step(2:end))


for i=1:agc_max
    if(i<=agc_step(2))      out(1,i) = floor(i*kb(1,1)/2^15) + kb(1,2);
    else if(i<=agc_step(3)) out(1,i) = y_const(1,1);
    else if(i<=agc_step(4)) out(1,i) = y_const(1,1);
    else if(i<=agc_step(5)) out(1,i) = y_const(1,1);
    else if(i<=agc_step(6)) out(1,i) = floor(i*kb(5,1)/2^15) + kb(5,2);
    else                    out(1,i) = y_const(1,2);
    end; end; end; end; end
end

for i=1:agc_max
    if(i<=agc_step(2))      out(2,i) = y_const(2,1);
    else if(i<=agc_step(3)) out(2,i) = y_const(2,1);
    else if(i<=agc_step(4)) out(2,i) = y_const(2,1);
    else if(i<=agc_step(5)) out(2,i) = floor(i*kb(4,1)/2^15) + kb(4,2);
    else if(i<=agc_step(6)) out(2,i) = y_const(2,2);
    else                    out(2,i) = floor(i*kb(6,1)/2^15) + kb(6,2);
    end; end; end; end; end
end

for i=1:agc_max
    if(i<=agc_step(2))      out(3,i) = y_const(3,1);
    else if(i<=agc_step(3)) out(3,i) = floor(i*kb(2,1)/2^15) + kb(2,2);
    else if(i<=agc_step(4)) out(3,i) = floor(i*kb(3,1)/2^15) + kb(3,2);
    else if(i<=agc_step(5)) out(3,i) = y_const(3,2);
    else if(i<=agc_step(6)) out(3,i) = y_const(3,2);;
    else                    out(3,i) = y_const(3,2);;
    end; end; end; end; end
end

plot(out(1,:),'b','linewidth',2)
hold on
plot(out(2,:),'g','linewidth',2)
plot(out(3,:),'r','linewidth',2)
hold off
grid on