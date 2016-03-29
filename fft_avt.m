%Function for plot FFT from REC_DATA module
%Require octave, octave-signal
%dirname `rpm -ql octave-signal | grep hann.m` >> ~/.octaverc

%Prepare data
%system ('grep "3:" minicom.cap | cut -d ":" -f2 | cut -d " " -f1,2 > f3');
%grep "^0:" minicom.cap | cut -d ":" -f2 | cut -d " " -f1 > f8
%grep "^16:" minicom.cap | cut -d ":" -f2 | cut -d " " -f1,2 > f3
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

if nargin < 3
    error('Not enougth arguments');
end

%Check if we in Octave or Matlab and load additional library for Octave
vers = version;
if (str2num(vers(1)) >= 7)
else
    pkg load signal
end
%================================================
%Variables for change

%Filename of input data
%data_file = 'f0';
%data must be in one or two (for complex mode) columns with " " delimiter

%Sampling frequency, MHz
%Fs = 190;

%Number of FFT points as power of 2
%Low number - low Frequency resolution but big smoothnes of picture. Useful 9 to 14.
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
    snoi = normrnd(0,0.1,2^20,1);
    f4 = ssin' + snoi;
    [nr,nc] = size(f4);
    cplx_mode = 'real';
else
    f_pre = load(data_file);
    [nr,nc] = size(f_pre);
    if nc == 1
        f4 = f_pre;
        cplx_mode = 'real';
    else
        f4 = complex(f_pre(:,1),f_pre(:,2));
        cplx_mode = 'complex';
    end
end

fft_samples=2^smpl;
fft_samples_half=fft_samples/2;
number_dia=floor(length(f4)/fft_samples);

fprintf('Total %d %s samples (FFT %d samples and %d full diapasons)\n',length(f4),cplx_mode,fft_samples,number_dia);
fprintf('FFT precision: %d Hz (smpl = %d); MAX %d Hz (smpl = %d)\n',Fs*1e6/fft_samples,smpl,Fs*1e6/length(f4),log2(length(f4)));

%Use Hann window or not
if use_window == 1
    hann_coeffs = hann(fft_samples);
else
    hann_coeffs = ones(fft_samples,1);
end

for k=1:number_dia
    f0_s(k,:) = abs(fft(hann_coeffs.*f4(1+fft_samples*(k-1):fft_samples*k)));
end

f0_sum = zeros(1,fft_samples);
for k=1:number_dia
    f0_sum = f0_sum + f0_s(k,:);
end
f0_sum = 20*log10(f0_sum/max(f0_sum));

%Plot graphs
if Fs > 150
    fr=(1:fft_samples_half)/fft_samples_half*Fs/2+Fs/2;
    for_plot = f0_sum(fft_samples_half+1:end);
else
    if nc == 1
        fr=(1:fft_samples_half)/fft_samples_half*Fs/2;
        for_plot = f0_sum(1:fft_samples_half);
    else
        fr=(1:fft_samples)/fft_samples*Fs-Fs/2;
        for_plot = [f0_sum(fft_samples_half+1:end) f0_sum(1:fft_samples_half)];
    end
end

plot(fr,for_plot,plot_color)
axis('tight')
grid on
hold off
title ('Amplitude Frequency Characteristic');
xlabel ('Frequency, MHz');
ylabel ('Amplitude, dB');
