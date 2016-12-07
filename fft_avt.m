%Function for plot FFT from REC_DATA module
%Require octave, octave-signal
%dirname `rpm -ql octave-signal | grep hann.m` >> ~/.octaverc

%Prepare data
%system ('grep "3:" minicom.cap | cut -d ":" -f2 | cut -d " " -f1,2 > f3');
%grep "^0:" minicom.cap | cut -d ":" -f2 | cut -d " " -f1 > f8
%grep "^16:" minicom.cap | cut -d ":" -f2 | cut -d " " -f1,2 > f3
%histc(a,[-3 -2 -1 0 1 2 3])/length(a)*100

function [spectre_freq_points,spectre_data,plot_color] = fft_avt (data_file, Fs, smpl, use_window, plot_color, test_mode)

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
if (str2num(vers(1)) < 7)
    pkg load signal
end

%Set frequency threshold for fast real input, MHz
%If Fs less then FS_FAST it will be slow real or complex
FS_FAST = 150;
%================================================
%Variables for change

%Filename of input data
%data_file = 'f0';
%data must be in one or two (for complex mode) columns with " " (witespace) delimiter.
%In Test mode enter 0.

%Sampling frequency, MHz
%Fs = 190;

%Number of FFT points as power of 2
%Low number - low Frequency resolution but more smoothnes of picture. Useful 9 to 14.
%smpl = 14;

%Enable window for FFT
%0 - no window, 1 - Hann, 2 - Blackman
%use_window = 1;

%Color of FFT plot
%plot_color = 'b';

%Test mode
%0 - normal mode, 1 - real test mode, 2 - complex test mode
%test_mode = 0;
%================================================

if test_mode == 1
    f           = 1:2^20;
    ssin        = sin(f) + 0.1*cos(f/2);
    snoi        = normrnd(0,0.1,2^20,1);
    input_data  = ssin' + snoi;
    [nr,nc]     = size(input_data);
    cplx_mode   = 'real';
elseif test_mode == 2
    f           = 1:2^20;
    ssin0       = (sin(f) + 0.1*cos(f/4));
    ssin1       = (cos(f) + 0.1*sin(f/4));
    snoi0       = normrnd(0,0.1,2^20,1);
    snoi1       = normrnd(0,0.1,2^20,1);
    input_data0 = [ssin0;ssin1]' + [snoi0 snoi1];
    input_data  = complex(input_data0(:,1),input_data0(:,2));
    [nr,nc]     = size(input_data0)
    cplx_mode   = 'complex';
else
    f_pre       = load(data_file);
    [nr,nc] = size(f_pre);
    if nc == 1
        input_data  = f_pre;
        cplx_mode   = 'real';
    else
        input_data  = complex(f_pre(:,1),f_pre(:,2));
        cplx_mode   = 'complex';
    end
end

input_data_lth      = length(input_data);
fft_samples         = 2^smpl;
fft_samples_half    = fft_samples/2;
number_dia          = floor(input_data_lth/fft_samples);
Fs2                 = Fs/2;

fprintf('Total %d %s samples (FFT %d samples and %d full diapasons)\n',input_data_lth,cplx_mode,fft_samples,number_dia);
fprintf('FFT precision: %d Hz (smpl = %d); MAX %d Hz (smpl = %d)\n',Fs*1e6/fft_samples,smpl,Fs*1e6/input_data_lth,log2(input_data_lth));

%Use Hann window or not
if use_window == 1
    wind_coeffs = hann(fft_samples);
elseif use_window == 2
    wind_coeffs = blackman(fft_samples);
else
    wind_coeffs = ones(fft_samples,1);
end

%Compute separate FFT for each part
for k=1:number_dia
    fft_data_parts(k,:) = abs(fft(wind_coeffs.*input_data(1+fft_samples*(k-1):fft_samples*k)));
end

%Sum samples from each part and make logarithm
fft_data_sum        = sum(fft_data_parts,1);
fft_data_sum_log    = 20*log10(fft_data_sum/max(fft_data_sum));

%Plot graphs
if Fs > FS_FAST
    spectre_freq_points = (1:fft_samples_half)/fft_samples_half*Fs2+Fs2;
    spectre_data        = fft_data_sum_log(fft_samples_half+1:end);
else
    if nc == 1
        spectre_freq_points = (1:fft_samples_half)/fft_samples_half*Fs2;
        spectre_data        = fft_data_sum_log(1:fft_samples_half);
    else
        spectre_freq_points = (1:fft_samples)/fft_samples*Fs-Fs2;
        spectre_data        = [fft_data_sum_log(fft_samples_half+1:end) fft_data_sum_log(1:fft_samples_half)];
    end
end

plot(spectre_freq_points,spectre_data,plot_color)
axis('tight')
grid on
hold off
title ('Amplitude Frequency Characteristic');
xlabel ('Frequency, MHz');
ylabel ('Amplitude, dB');
