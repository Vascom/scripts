function [out] = LDPC_encode (s,max_iter_c,out_reg_sel);

if nargin < 3
    out_reg_sel = 0;
end

if nargin < 2
    max_iter_c = 100;
    out_reg_sel = 0;
end

main_length = length(s);
FRAME2 = 600;
FRAME3 = 274;

if (main_length~=FRAME2 && main_length~=FRAME3)
    error('%s\n','Input sequence must have 600 or 274 elements')
end

vers = version;

%Init encoding matrix
A = zeros(main_length-1,main_length);
B = zeros(main_length-1,1);
C = zeros(1,main_length);
D = 1;
E = zeros(1,main_length-1);
T = zeros(main_length-1);

%Define coordinates of 'ones' in matrix
if (main_length==FRAME2)
    pa = load('a_600.txt');
    pb = [ 1 44 110 155 178 205 229 263 269 335 423 510 532 597];
    pc = [74 322 402 485 527];
    pe = [598 599];
    pt = load('t_600.txt');
elseif (main_length==FRAME3)
    pa = load('a_274.txt');
    pb = [3 20 71 76 124 137 155 195 222 253];
    pc = [23 86 177 227];
    pe = [271 273];
    pt = load('t_274.txt');
end

%Filling matrix with 'ones'
for k=1:length(pa) A(pa(k,1),pa(k,2)) = 1; end
for k=1:length(pb) B(pb(k)) = 1; end
for k=1:length(pc) C(pc(k)) = 1; end
for k=1:length(pe) E(pe(k)) = 1; end
for k=1:length(pt) T(pt(k,1),pt(k,2)) = 1; end
H = [A B T; C D E];

%Registers for ASIC programming
%octave -q --eval "disp(LDPC_encode([1 1 1 1 1 0 1 0 1 0 1 zeros(1,585) 0 1 0 1],50,1))" > /tmp/pvs.txt
%head -n 3820 /tmp/pvs.txt > ps.txt
%tail -n +3821 /tmp/pvs.txt | head -n 3820 > vs.txt
%tail -n +6741 /tmp/pvs.txt | head -n 100 > de.txt
%tail -n 300 /tmp/pvs.txt > llr.txt

if (str2num(vers(1)) >= 7)
    %Encoder and Decoder initialization for Matlab
    enc = comm.LDPCEncoder(sparse(H));
    dec = comm.LDPCDecoder(sparse(H));
    dec.DecisionMethod = 'Hard decision';
    dec.OutputValue = 'Information part';
    dec.MaximumIterationCount = max_iter_c;
    dec.IterationTerminationCondition = 'Parity check satisfied';
    dec.NumIterationsOutputPort = true;
end

%Encode input data
if (str2num(vers(1)) >= 7)
    c = step(enc, s');
    %fprintf('%s\n','Use Matlab');
else
    Ti = inv(T);
    f = mod(-E*Ti*B+D,2);
    p1 = mod(-inv(f)*(-E*Ti*A+C)*s',2);
    p2t = -Ti*(A*s'+B*p1);
    p2 = p2t';
    c = [s mod([p1 p2],2)];
    %c = c';
    %fprintf('%s\n','Use Octave');
end

c_init = c;

%Add noise
c = c*2 - 1;
%noise = normrnd(0,10,main_length*2,1);
%c = -c + noise;
%c = sign(c);
%nnz(c)
c = c*(-10);
c(1) = -c(1)*10;

if (str2num(vers(1)) >= 7)
    [decoded numIter] = step(dec, c);
    smod = (s*2 -1)*(-10);
    fprintf('%s%d\n','Done iterations: ',numIter);
    fprintf('%s%d\n','Total correct input: ',sum(c(1:main_length)' == smod));
    fprintf('%s%d\n','Total correct decoded: ',sum(decoded' == s));
end

switch (out_reg_sel)
    case 'ps'
        out = pshed_prepare(H,FRAME2,FRAME3);
    case 'vs'
        out = vshed_prepare(H,FRAME2,FRAME3);
    case 'de'
        out = degree_prepare(H,FRAME2,FRAME3);
    case 'llr'
        out = llr_prepare(c,FRAME2,FRAME3);
    case 'data'
        out = input_data_prepare(c_init,FRAME2,FRAME3);
    otherwise
        pshed = pshed_prepare(H,FRAME2,FRAME3);
        vshed = vshed_prepare(H,FRAME2,FRAME3);
        degree = degree_prepare(H,FRAME2,FRAME3);
        llr = llr_prepare(c,FRAME2,FRAME3);
        input_data = input_data_prepare(c_init,FRAME2,FRAME3);
        out = [pshed;  vshed; degree; llr; input_data];
end

%Function pack PSHEDs to 32-bits words
function [pshed] = pshed_prepare(H,FRAME2,FRAME3);

size_H = size(H);
main_length = size_H(1);
if (main_length~=FRAME2)
    H = [H zeros(size_H(1),(FRAME2-FRAME3)*2)];
    H = [H; zeros(FRAME2-FRAME3,FRAME2*2)];
end

for k=1:ceil(main_length/24)
    for m=1:(main_length*2)
        bn = k-1;
        ed = H(1+24*(k-1):24*k,m);
        if (sum(ed)~=0)

            LDPC_PSCHED = 0;
            for n=1:24
                if (ed(n)==1) LDPC_PSCHED = bitset(LDPC_PSCHED,n); end
            end
            LDPC_PSCHED = bitor(LDPC_PSCHED,bitshift(bn,24));

            if (k==1 && m==1)
                pshed = LDPC_PSCHED;
            else
                pshed = [pshed; LDPC_PSCHED];
            end
        end
    end
    %Switch bank addition
    pshed(end:end) = bitor(pshed(end:end),bitshift(1,31));
end

size_p = size(pshed);
if (size_p(1)~=3820)
    pshed = [pshed; zeros(3820-size_p(1),1)];
end

pshed = dec2hex(pshed,8);

%Function pack VSHEDs to 32-bits words
function [vshed] = vshed_prepare(H,FRAME2,FRAME3);

size_H = size(H);
main_length = size_H(1);
if (main_length~=FRAME2)
    H = [H zeros(size_H(1),(FRAME2-FRAME3)*2)];
    H = [H; zeros(FRAME2-FRAME3,FRAME2*2)];
end

vn_first_use = ones(1,main_length*2);

for k=1:25
    for m=1:(main_length*2)
        ed = H(1+24*(k-1):24*k,m);
        if (sum(ed)~=0)
            LDPC_VSCHED = m-1;
            LDPC_VSCHED = bitor(LDPC_VSCHED,bitshift(vn_first_use(m),15));
            vn_first_use(m) = 0;

            if (k==1 && m==1)
                vshed = LDPC_VSCHED;
            else
                vshed = [vshed; LDPC_VSCHED];
            end
        end
    end
end

size_v = size(vshed);
if (size_v(1)~=3820)
    vshed = [vshed; zeros(3820-size_v(1),1)];
end

vshed = dec2hex(vshed,8);

%Function pack DEGREEs to 32-bits words
function [degree] = degree_prepare(H,FRAME2,FRAME3);

sums_row = sum(H');
sums_length = ceil(length(sums_row));
if (sums_length~=FRAME2)
    sums_row = [sums_row zeros(1,FRAME2-FRAME3)];
end

for k=0:99;
    degree_pre = bitshift(k,24);
    for m=0:5
        degree_pre = bitor(degree_pre,bitshift(sums_row(k*6+m+1),m*4));
    end
    if (k==0)
        degree = degree_pre;
    else
        degree = [degree; degree_pre];
    end
end

degree = dec2hex(degree,8);

%Function pack LLRs to 32-bits words
function [llr] = llr_prepare(c,FRAME2,FRAME3);

c_length = length(c);
c_prep = c;
for k=1:c_length
    if (c(k)<0) c_prep(k) = 256+c(k); end
end

if (c_length~=FRAME2*2)
    c_prep = [c_prep zeros(1,(FRAME2-FRAME3)*2)];
end

for k=0:299
    llr_pre = 0;
    for m=0:3
        llr_pre = bitor(llr_pre,bitshift(c_prep(k*4+m+1),m*8));
    end

    if (k==0)
        llr = llr_pre;
    else
        llr = [llr; llr_pre];
    end
end

llr = dec2hex(llr,8);

%Function pack input data to 32-bits words
function [data] = input_data_prepare (s,FRAME2,FRAME3);

s_length = length(s);

s = [s zeros(1,16)];
if (s_length~=FRAME2*2)
    s = [s zeros(1,(FRAME2-FRAME3)*2)];
end

for k=0:37
    data_pre = 0;
    for m=0:31
        data_pre = bitor(data_pre,bitshift(s(k*32+m+1),m));
    end

    if(k==0)
        data = data_pre;
    else
        data = [data; data_pre];
    end
end

data = dec2hex(data,8);
