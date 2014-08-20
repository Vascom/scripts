%Convert some decimal numbers and it shifts to one hexadecimal number
%data   - array of decimal numbers
%bit    - array of it shifts
%width  - array of width for negative numbers if they present in data

function [out] = dec_hex_bit (data, bit, width)

if nargin < 3
    width = ones(1,length(data))*32;
end

if (data(1) < 0)
    widht_mask = 2^width(1)-1;
    data(1) = bitand(2^32+data(1),widht_mask);
end

out = bitshift(data(1),bit(1));

for i = 2:length(data)
    if (data(i) < 0)
        widht_mask = 2^width(i)-1;
        data(i) = bitand(2^32+data(i),widht_mask);
    end
    out_pre = bitshift(data(i),bit(i));
    out = bitor(out,out_pre);
end

out=dec2hex(out);
