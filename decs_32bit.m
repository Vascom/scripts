%Convert some decimal numbers to splitted 32-bit words
%data   - array of decimal numbers
%width  - width for numbers

function [full_mem] = decs_32bit (data, width)

width_mask = 2^width-1;
word = 32;
width_word = 2^word;

full_mem = char();
for i = 1:length(data)
    full_mem = char([ dec2bin(bitand(width_word+data(i),width_mask),width) full_mem]);
end
