function x_delay_noise = receivedSignal0(sigen,config,CNo)


%% load configuration file
eval(config)

x_delay = sigen.x_delay;
NsamplesData = sigen.NsamplesData;

order = 36;
fn = 2e6;
wn = pi*fn/(pi*fs/2);
h = fir1(order,wn);
%% memory allocation
x_delay_noise = zeros(numSV,NsamplesData);

%% Add AWGN noise to the transmitted signals
for kSV=1:numSV       
    A = sqrt(10^(CNo(kSV)/10)/fs);
    noise = sqrt(1/2)*randn(1,NsamplesData) + 1i*sqrt(1/2)*randn(1,NsamplesData);
    noise = 0;
    x_delay_noise(kSV,:) = A*x_delay(kSV,:) + noise;
    x_delay_noise(kSV,:) = filtfilt(h,1,x_delay_noise(kSV,:));
end

% noise = sqrt(1/2)*randn(1,NsamplesData) + 1i*sqrt(1/2)*randn(1,NsamplesData);
% for kSV=1:numSV
%     A = sqrt(10^(CNo(kSV)/10)/fs);
%     x_delay_noise(kSV,:) = A*x_delay(kSV,:) + noise;
% end