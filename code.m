%%%%%%%%%%%%%%%%%%%%%Free Noise Environment%%%%%%%%%%%%%%%%%%%
%Generating random sequence ---------------------------------
randSeq = randi([0,1] , 1, 10); %generating 10 random bits
randSeqEdit = (2*randSeq - 1); %converting 0 to -1 and 1 to +1
sampledSignal = upsample(randSeqEdit,5); %sapmle every 200ms
p = [5 4 3 2 1]/sqrt(55); %pulse shaping function
Yn= conv(sampledSignal,p); %output of the transmitter
%Yn = nonzeros(Y);
Yn(:,51:54) = []; %taking only nonzero values
%Matched Filter (matched to p) -------------------------------
MF = fliplr(p); %flip the pulse shaping function 
MF_out = conv(MF,Yn);
for i=1:10
    MF_outSampled (i) = MF_out(5*i); %sampling the output every Ts=1s
end
%Normalized filter --------------------------------------------
NF = [1 1 1 1 1]/sqrt(5);
NF_out = conv(Yn,NF);
for i=1:10
    NF_outSampled(i) = NF_out(5*i);
end
%Plots---------------------------------------------------------
figure;
subplot(2,1,1);
plot(MF_out,'b','linewidth',1);
xlabel("time");
title("Output of the matched filter");
subplot(2,1,2);
plot(NF_out,'r','linewidth',1);
xlabel("time");
title("Output pf the normalized filter");
figure;
subplot(2,1,1);
stem(MF_out,'b','linewidth',1);
xlabel("time");
title("Output of the matched filter before sampling");
subplot(2,1,2);
stem(NF_out,'r','linewidth',1);
xlabel("time");
title("Output of the normalized filter before sampling");
figure;
subplot(2,1,1);
stem(MF_outSampled,'b','linewidth',1);
xlabel("time");
title("Output of matched filter after sampling");
subplot(2,1,2);
stem(NF_outSampled,'r','linewidth',1);
xlabel("time");
title("Output of the normalized filter after sampling");
%Correlator in a noise free system-----------------------------
correlator_in=repmat(p,1,10).*Yn;
m=1;
for i=1:50
    correlator_out(i)=sum(correlator_in(m:i));
if mod(i,5)==0
    m=m+5;
end
end
for i=1:10
    correlator_outSampled(i)=correlator_out(5*i);
end
%Plots---------------------------------------------------------
figure;
plot(correlator_out,'r','linewidth',1);
hold on
plot(MF_out,'b','linewidth',1);
legend('Output of correlator','Output of matched filter');
title("Output of correlator & matched filter");
figure;
stem(correlator_out,'r','linewidth',1);
hold on
stem(MF_out,'b','linewidth',1);
legend('Output of correlator','Output of matched filter');
title("Output of correlator & matched filter before sampling");
figure;
stem(correlator_outSampled,'r','linewidth',1);
hold on
stem(MF_outSampled,'b','linewidth',1);
legend('Output of correlator','Output of matched filter');
title("Output of correlator & matched filter before sampling");

%%%%%%%%%%%%%%%%%%%%%%%Noisy Environment%%%%%%%%%%%%%%%%%%%%%%%
randSeq = randi([0,1],1,10000); %generating 10000 random bits
randSeqEdit = (2*randSeq - 1); %converting 0 to -1 and 1 to +1
sampledSignal = upsample(randSeqEdit,5); %sapmle every 200ms
p = [5 4 3 2 1]/sqrt(55); %pulse shaping function
Yn= conv(sampledSignal,p); %output of the transmitter
Yn(:,50001:50004) = []; %taking only nonzero values
noise = randn(1,size(Yn,2));
No=1;
Eb=1;
for j=-2:5
    No=Eb/(10^(j/10));
    noise_scaled = noise.*sqrt(No/2);
    Vn = Yn+noise_scaled; %adding noise to signal
%Matched and normalized filters---------------------------------
MF = fliplr(p);
MF_out = conv(Vn , MF);
NF = [5 5 5 5 5]/sqrt(125);
NF_out = conv(Vn,NF);
for i=1:10000
    MF_outSampled(i) = MF_out(i*5); %sampling every Ts=5*200ms
    NF_outSampled(i) = NF_out(i*5);
end
%Comparing with threshold for matched filter
for i = 1:length(MF_outSampled)
    if MF_outSampled(i)<0
        MF_outSampled(i) = -1;
    elseif MF_outSampled(i)>0
        MF_outSampled(i) = 1;
    end
end
%Comparing with threshold for matched filter
for i = 1:length(NF_outSampled)
    if NF_outSampled(i)<0
        NF_outSampled(i) = -1;
    elseif NF_outSampled(i)>0
        NF_outSampled(i) = 1;
    end
end
%Getting BER------------------------------------------------------
[numErrorMF , MF_ER] = symerr(MF_outSampled,randSeqEdit); %comparing output of MF with the original signal
[numErrorNF , NF_ER] = symerr(NF_outSampled,randSeqEdit); %comparing output of NF with the original signal
EbNo_ratio(j+3) = Eb/No;
MF_BER(j+3) = MF_ER; %BER for each itteration from -2dB to 5dB
NF_BER(j+3) = NF_ER;
end
%Getting theoritical BER------------------------------------------
for i=1:length(EbNo_ratio)
    theo_BER(i)=0.5*erfc(sqrt(EbNo_ratio(i)));
end
%Plots------------------------------------------------------------
figure;
semilogy(-2:5,MF_BER,'b','linewidth',1);
hold on
semilogy(-2:5,NF_BER,'r','linewidth',1);
hold on
semilogy(-2:5,theo_BER,'g','linewidth',1);
xlabel('Eb/No');
ylabel('BER');
legend('MF BER','NF BER','Theoretical BER');
title('Matched Filter BER ,Normalized Filter BER & Theoretical BER');

%%%%%%%%%%%%%%%%%%%%%%%ISI & Raised Cosine%%%%%%%%%%%%%%%%%%%%%%%
GenBits = randi([0,1],1,100); %data length of 100 bits
GenBitsEdit = (2*GenBits - 1); %converting 0 to -1 and 1 to +1
sampledBits = upsample(GenBitsEdit,5);
R = [0 0 1 1];
delay = [2 8 2 8];
for i=1:4
    [A,B]=rcosine(1,5,'sqrt',R(i),delay(i));
    TX_Filter=filter(A,B,sampledBits);
    RX_Filter=filter(A,B,TX_Filter);
    if i==1 
        eyediagram(TX_Filter,10);
        legend('TX 1');
        eyediagram(RX_Filter,10);
        legend('RX 1');
    elseif i==2
        eyediagram(TX_Filter,10);
        legend('TX 2');
        eyediagram(RX_Filter,10);
        legend('RX 2');
    elseif i==3
        eyediagram(TX_Filter,10);
        legend('TX 3');
        eyediagram(RX_Filter,10);
        legend('RX 3');
    elseif i==4
        eyediagram(TX_Filter,10);
        legend('TX 4');
        eyediagram(RX_Filter,10);
        legend('RX 4');
    end
    
end


