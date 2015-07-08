function [ff] = sign_repair (data, sign_bit);

[nr,nc] = size(data);

ff = zeros(nr,nc);

for k=1:nc
    for n=1:nr
        if(data(n,k)>15)   ff(n,k)=data(n,k)-2^sign_bit;
        else                ff(n,k)=data(n,k);
        end
    end
end
