format long
a=[455000 24255000 4200000];
a-mean(a)
(a-mean(a)).^2
sum((a-mean(a)).^2)
sum((a-mean(a)).^2)/2
sqrt(sum((a-mean(a)).^2)/2)
sqrt(sum((a-mean(a)).^2)/2)/mean(a)*100
