%Convert some decimal numbers and it shifts to one hexadecimal number
%data - array of decimal numbers
%bits - array of it shifts

function [out] = dec_hex_bit (data, bit)

out = bitshift(data(1),bit(1));

for i = 2:length(data)
    out_pre = bitshift(data(i),bit(i));
    out = bitor(out,out_pre);
end

out=dec2hex(out);
