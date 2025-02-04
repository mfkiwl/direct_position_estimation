clear
close all
clc;


%% Load Settings
pth = cd;
addpath ([pth,'\Knife Edge']);
addpath ([pth,'\Parameter Files']);

%% Multipath Propogation Simulation
mulipath_error_candidates = 200;
nCandidates = length(mulipath_error_candidates);
% predefined parameter
% user parameters
X = 4777973.177; Y = 176346.307; Z = 4207663.62;
user_pos_ecef_initial = [X, Y, Z];
user_pos_lla_initial = ecef2lla(user_pos_ecef_initial);
user_clock_bias = 2e-8;
user_pos = user_pos_ecef_initial;
c = 299792458;
% receiver parameters
fs = 20.46e6;      % sampling frequency
ts = 1/fs;
duration = 6;  % sec
samplesPerCode = fs * 1e-3;
tc = 1/1.023e6; % period of one chip 
codeLength = 1023;
fb = 50;
tb = 1 / fb;
CN0 = 40;
snr = 10^((CN0-10*log10(fs))/10);
noise_power = 1;
signal_power = noise_power * snr;
alpha = sqrt(signal_power / 1);
% satellite parameters
sat_info = load("load_data/sat8_info_multipath_fix_pos.mat");
sat_info = sat_info.sat_info;

%% Generate LOS Delayed Signal 
% ---- gereate LOS signal ----
nEpoch = duration * 1e3;        % 1ms = 1 epoch
nSat = size(sat_info, 1);
user_pos_repmat = repmat(user_pos, nSat, 1);
% generate common index for C/A code sampling
codeValueIndex = ceil((ts * (1: samplesPerCode * nEpoch)) / tc);
codeValueIndex = rem(codeValueIndex, codeLength);
codeValueIndex(codeValueIndex==0) = codeLength;
% generate common bits for sampling
bitValueIndex = ceil((ts * (1: samplesPerCode * nEpoch)) / tb);
bit = sign(randn(1, nEpoch/20));
bitSample = bit(bitValueIndex);
% compute delay at each epoch for each satellite
LOSdelay = zeros(nSat, nEpoch);
for iEpoch = 1:nEpoch
sat_pos = sat_info(:,1:3,iEpoch); %iEpoch
LOSrange = vecnorm(sat_pos - user_pos_repmat, 2, 2);
LOSprange = LOSrange + c * user_clock_bias;
LOSdelay(:, iEpoch) = LOSprange / c;
end
% generate LOS signal for each satellite
LOSsignal = zeros(nSat, samplesPerCode * nEpoch);
for iSat = 1:nSat
    % --- generate common C/A code sampling -----
    sat_prn = sat_info(iSat, 9, 1);
    caCode = generateCAcode(sat_prn);
    LOSsignal(iSat,:) = caCode(codeValueIndex).* bitSample;
    % --- generate delayed LOS signal -----
    y_echo = 0;
    for iEpoch = 1: nEpoch
        delay = LOSdelay(iSat, iEpoch);
        delay_ind = rem(round(delay / ts), samplesPerCode);
        delay_loss = zeros(1, delay_ind + 1);
        delay_loss(delay_ind + 1) = 1;
        % generate delayed signal every 1ms, since delay is changing
        % for every 1ms
        step = samplesPerCode;
        y_total = cconv(LOSsignal(iSat, (iEpoch-1)*step + 1:iEpoch*step), delay_loss) ...
            + [y_echo, zeros(1,step+length(delay_loss)-length(y_echo)-1)];
        y_total(abs(y_total) < 1e-12) = 0;
        y_echo = y_total(step+1:end);
        LOSsignal(iSat, (iEpoch-1)*step + 1:iEpoch*step) = y_total(1:step);
    end
end

%% Experiments for Different Multipath Errors
for iCandidates = 1: nCandidates
    %% Generate LOS Signal 
    RxSignal_each_sat = zeros(nSat, samplesPerCode * nEpoch);
    delay_multipath = mulipath_error_candidates(iCandidates);      % multipath error in meter
    delay_multipath = delay_multipath / c;  % multipath error in second
    if delay_multipath == 0
        delay = 0;
    else
        delay = [0, delay_multipath];
    end
    delay_amplitude = alpha * [1, 0.5];
    delay_ind = rem(round(delay / ts), samplesPerCode);
    delay_loss = zeros(1, max(delay_ind) + 1);
    for iDelay = 1:length(delay)
        delay_loss(delay_ind(iDelay) + 1) = delay_amplitude(iDelay);
    end
    for iSat = 1:nSat
        % --- generate delayed signal with multipath -----
        y_echo = 0;
        if iSat > 4
            delay_loss = alpha;
        end
        % generate signal
        for iEpoch = 1: nEpoch
            % generate delayed signal every 1ms, since delay is changing
            % for every 1ms
            step = samplesPerCode;
            y_total = cconv(LOSsignal(iSat, (iEpoch-1)*step + 1:iEpoch*step), delay_loss) ...
                + [y_echo, zeros(1,step+length(delay_loss)-length(y_echo)-1)];
            y_total(abs(y_total) < 1e-10) = 0;
            y_echo = y_total(step+1:end);
            RxSignal_each_sat(iSat, (iEpoch-1)*step + 1:iEpoch*step) = y_total(1:step);
        end
    end
    RxSignal = sum(RxSignal_each_sat, 1);
    clear RxSignal_each_sat
    RxSignal_IQ = [real(RxSignal); imag(RxSignal)];
    %% Write data
    save_path_mat = sprintf("load_data/RxSignal_8sat_20_46MHz_multipath_error_%d_4sat.mat",...
        mulipath_error_candidates(iCandidates));
    save_path_dat = sprintf("load_data/RxSignal_8sat_20_46MHz_multipath_error_%d_4sat.dat",...
        mulipath_error_candidates(iCandidates));
    save(save_path_mat, 'RxSignal')
    pfid=fopen(save_path_dat,'wb');
    fwrite(pfid, RxSignal_IQ, 'float');
    fclose(pfid);
    clear RxSignal RxSignal_IQ
end
%% test
% load("result/navSolutions.mat")
% delay_est = navSolutions.channel.rawP(:,2:end)/c;
% figure;
% plot((LOSdelay(:,1:14996) - delay_est)')
% legend("1", "2", "3", "4", "5", "6")
% caCode = generateCAcode(10);
% local = caCode(codeValueIndex);
% local = local(1:10000);
% 
% start = 1*10000 + 4486 + 10000*(619-1)+2;
% 
% RxSignal_save = load('load_data/RxSignal_6sat_10MHz_LOS_naviBit.mat');
% RxSignal_save = RxSignal_save.RxSignal;
% 
% figure(1);
% z = abs(ifft(fft(RxSignal(1, start:start + 1e4 - 1)).*conj(fft(local))).^2);plot(z)
% hold on
% z = abs(ifft(fft(RxSignal_save(start:start + 1e4 - 1)).*conj(fft(local))).^2);plot(z)
% legend("running","saved")


