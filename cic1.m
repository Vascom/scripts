function [nd, F] = cic1 ( Fs, d, f_pass_set, f_transition_set, f_stop_weight, m, plot_en, N )

if nargin < 7
    plot_en = 0;
end

if nargin < 8
    N = 59;
end

%================================================
%Variables for change

%Sampling frequency
%Fs=200;
%Divider after CIC filtering
%d=4;
%Filter pass frequency (half of band), MHz
%f_pass_set = 6;
%Transition band from passband to stopband (usual 3), MHz
%f_transition_set = 2;
%Stopband weight
%f_stop_weight = 1;
%CIC parameters
%m=[13 16 16 16 16 16];
%Plot parameter
%0 - no plot, 1 - plot from 0 to Fs/d, 2 - plot from 0 to Fs
%Filter order
%N = 59;

%================================================
%Variables not for change

%Frequency response irregularity in pass zone, dB
irreg_threshold = 1;
%Response compute precision
precise = 2^14;

F_pass = f_pass_set/Fs*d*2;
F_stop = (f_pass_set+f_transition_set)/Fs*d*2;
tt=1:1:precise;
g=tt/precise/d/2*F_pass;
ach1=1:1:precise;

%================================================
%Filter compute

ach1=abs(sin(pi*m(1).*g)./sin(pi.*g)) ...
    .*abs(sin(pi*m(2).*g)./sin(pi.*g)) ...
    .*abs(sin(pi*m(3).*g)./sin(pi.*g)) ...
    .*abs(sin(pi*m(4).*g)./sin(pi.*g)) ...
    .*abs(sin(pi*m(5).*g)./sin(pi.*g)) ...
    .*abs(sin(pi*m(6).*g)./sin(pi.*g));

% Frequency Vector
F = [linspace(0,F_pass,precise) F_stop 1];
% Amplitude Vector
A = [1./ach1 0 0];
% Weight Vector
W = [ones(1,precise/2-1) f_stop_weight f_stop_weight];
% Calculate the coefficients using the FIRLS function.
% Use firls in Matlab or firls_my in Octave
vers = version;
if (str2num(vers(1)) >= 7)
    b = firls(N, F, A, W);
    %fprintf('Use Matlab\n');
else
    b = firls_my(N, F, A, W);
    %fprintf('Use Octave\n');
end
%Hd = dfilt.dffir(b);
%set(Hd, 'Arithmetic', 'double');
%hn = coeffs(Hd);
%[h,w]=freqz(hn.Numerator,1,precise);
[h,w]=freqz(b,1,precise);

g=tt/precise/d/2*1;
ach1=1:1:precise;
ach=abs(sin(pi*m(1).*g)./sin(pi.*g)) ...
    .*abs(sin(pi*m(2).*g)./sin(pi.*g)) ...
    .*abs(sin(pi*m(3).*g)./sin(pi.*g)) ...
    .*abs(sin(pi*m(4).*g)./sin(pi.*g)) ...
    .*abs(sin(pi*m(5).*g)./sin(pi.*g)) ...
    .*abs(sin(pi*m(6).*g)./sin(pi.*g));
ach=ach.';

%Check frequency response irregularity
true_fr = 20*log10(abs(h)/(abs(h(1))))+20*log10(ach/max(ach));
true_f_pass = true_fr(1:floor(precise*F_pass));
check_coeff_resp = max(true_f_pass)-min(true_f_pass);
if(check_coeff_resp > irreg_threshold)
    disp('Irregularity more then threshold (1dB default)!');
    disp('Increase Transition band and/or decrease stopband weight.');
    disp(check_coeff_resp);
end

%Plot frequency responses
if (plot_en ~= 0)
    plot(g*Fs,true_fr,'b'); hold on;
    plot(g*Fs,20*log10(abs(h)/(abs(h(1)))),'r');
    if (plot_en == 2)
        g=tt/precise/2*1;
        ach1=1:1:precise;
        ach=abs(sin(pi*m(1).*g)./sin(pi.*g)) ...
            .*abs(sin(pi*m(2).*g)./sin(pi.*g)) ...
            .*abs(sin(pi*m(3).*g)./sin(pi.*g)) ...
            .*abs(sin(pi*m(4).*g)./sin(pi.*g)) ...
            .*abs(sin(pi*m(5).*g)./sin(pi.*g)) ...
            .*abs(sin(pi*m(6).*g)./sin(pi.*g));
        ach=ach.';
        plot(g*Fs,20*log10(ach/ach(1)),'m');
    else plot(g*Fs,20*log10(ach/ach(1)),'g');
    end
    grid on;
end
%Coefficients for ASIC
hd = floor(b(1:30)/max(abs(b(1:30)))*(2^11-0) + 0.5);
nd = hd';
if(max(nd)==2048)
    hd = floor(b(1:30)/max(abs(b(1:30)))*(2^11-1) + 0.5);
    nd = hd';
end
