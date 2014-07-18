%Function for plot FFT from REC_DATA module
%Require octave, octave,signal
%dirname `rpm -ql octave-signal | grep hann.m` >> ~/.octaverc

%Prepare data
%grep "8:" minicom.cap | cut -d ":" -f2 | cut -d " " -f1 > f8
%histc(a,[-3 -2 -1 0 1 2 3])/length(a)*100

function [] = fft_avt (data_file, Fs, smpl, use_window, plot_color, test_mode)

if nargin < 6
    test_mode = 0;
end

if nargin < 5
    plot_color = 'b';
end

if nargin < 4
    use_window = 1;
end
%================================================
%Variables for change

%Filename of input data
%data_file = "f0";
%data must be in one or two (for complex mode) columns with " " delimiter

%Sampling frequency, MHz
%Fs = 190;

%Number of FFT points as power of 2
%smpl = 14;

%Enable Hann window for FFT
%use_window = 1;

%Color of FFT plot
%plot_color = 'b';

%Test mode
%test_mode = 0;
%================================================

if test_mode == 1
    f=1:2^20;
    ssin = sin(f);
    snoi = normrnd(0,0.001,1,2^20);
    f4 = ssin + snoi;
    [nr,nc] = size(f4);
    
    l1=0.64;
    l2=0.64*2/3;
    l3=0.64*1/3;
    for k=1:2^12
        sd(k) =  0;
        if ssin(k)<(-l1) sd(k) = -1; end
        if ssin(k)<(-l2) sd(k) = -2; end
        if ssin(k)<(-l3) sd(k) = -3; end
        if ssin(k)>( l1) sd(k) =  1; end
        if ssin(k)>( l2) sd(k) =  2; end
        if ssin(k)>( l3) sd(k) =  3; end
    end
else
    f_pre = load(data_file);
    [nr,nc] = size(f_pre);
    if nc == 1
        f4 = f_pre;
    else
        f4 = complex(f_pre(:,1),f_pre(:,2));
    end
end

fft_samples=2^smpl;
fft_samples_half=fft_samples/2;
number_dia=length(f4)/fft_samples;

printf("Total %d samples\n",length(f4));
printf("FFT %d samples\n",fft_samples);
printf("Total %d diapasons\n",number_dia);
printf("Max FFT precision: %d Hz if FFT smpl = %d\n",Fs*1e6/length(f4),log2(length(f4)));
printf("Real FFT precision: %d Hz with FFT smpl = %d\n",Fs*1e6/fft_samples,smpl);

if use_window == 1
    hann_coeffs = hann(fft_samples);
else
    hann_coeffs = ones(1,fft_samples)';
end

for k=1:number_dia
    f0_s(k,:) = abs(fft(hann_coeffs.*f4(1+fft_samples*(k-1):fft_samples*k)));
end

f0_sum = zeros(1,fft_samples);
for k=1:number_dia
    f0_sum = f0_sum + f0_s(k,:);
end
f0_sum = 20*log10(f0_sum/max(f0_sum));

if Fs > 100
    fr=(1:fft_samples_half)/fft_samples_half*Fs/2+Fs/2;
    plot(fr,(f0_sum(fft_samples_half+1:end)),plot_color)
else
    if nc == 1
        fr=(1:fft_samples_half)/fft_samples_half*Fs/2;
        plot(fr,(f0_sum(1:fft_samples_half)),plot_color)
    else
        fr=(1:fft_samples)/fft_samples*Fs-Fs/2;
        for_plot = [f0_sum(fft_samples_half+1:end) f0_sum(1:fft_samples_half)];
        plot(fr,for_plot,plot_color)
    end
end

grid on
hold off
title ("Amplitude Frequency Characteristic");
xlabel ("Frequency, MHz");
ylabel ("Amplitude, dB");
