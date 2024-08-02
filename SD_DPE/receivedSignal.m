function x_filter = receivedSignal(sigen,config,CNo)


%% load configuration file
eval(config)

x_delay = sigen;
NsamplesData = length(x_delay);

% filter setting
order = 36;
fn = 2e6;
wn = pi*fn/(pi*fs/2);
h = fir1(order,wn);

% noise setting
% snr = 10^((CNo-10*log10(fn))/10);

%% memory allocation
% x = zeros(numSV,NsamplesData);

%% Add AWGN noise to the transmitted signals
% for kSV=1:numSV       
%     A = sqrt(10^(CNo(kSV)/10)/fs);
% 
%     x(kSV,:) = A*x_delay(kSV,:);
% 
% end
% % noise = sqrt(1/2)*randn(1,NsamplesData) + 1i*sqrt(1/2)*randn(1,NsamplesData);
% noise = 0;
% % noise0 = randn(1,NsamplesData);
% x_delay_noise = sum(x,1) + noise;
% x_delay_noise = filtfilt(h,1,x_delay_noise);
A = sqrt(10^(CNo/10)/fs);
noise = ( sqrt(1/2)*randn(1,NsamplesData) +1i* sqrt(1/2)*randn(1,NsamplesData));

x_delay = A * x_delay;
x_delay = x_delay + noise;

x_filter = filtfilt(h, 1, x_delay);

