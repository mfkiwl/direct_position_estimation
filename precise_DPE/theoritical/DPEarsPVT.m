function [PosErrDPE,CBErrDPE,PosEstDPE] = DPEarsPVT(x_delay_noise,config,caCode_filt,CNo_idx)

%% load configuration file
eval(config)
dmax = Dmax(CNo_idx);
dmin = Dmin(CNo_idx);
dmax_clk = Dmax_clk(CNo_idx);
dmin_clk = Dmin_clk(CNo_idx);
%% memory allocation
position_est = zeros(Niter,3);
cb_est = zeros(Niter,1);
%% compute the cost function of est_gamma
% here we only consider gamma = (x,y,z,deltaT)
% the other parameters are fixed
gamma.UserPosition  = param.UserPosition;
gamma.UserPosition(1,3) = param.UserPosition(1,3);
gamma.deltaT = param.deltaT; % + 1e-8*rand;
gamma.UserVelocity = param.UserVelocity;
gamma.deltaTdot = param.deltaTdot;

Local0 = signalGen(config,caCode_filt,gamma);
r = correlateSignal0(Local0,config,x_delay_noise);
J_ant = sum(r,1);

%% ARS Algorithm
% compare the cost value of est_gamma and random moved gamma
d = dmax;
d_clk=dmax_clk;
position_est(1,:) = gamma.UserPosition;
cb_est(1,:) = gamma.deltaT;

% ARS algorithm iterations
for it = 1:Niter-1            
    % draw a random movement
    rand_position = position_est(it,:) + d*(2*rand(3,1)-1)';
%     rand_position(1,3) = param.UserPosition(1,3);
    rand_cb = cb_est(it,:) + d_clk*(2*rand-1);
%     rand_cb = param.deltaT;
    % compute cost of the random point
    gamma.UserPosition = rand_position;
    gamma.deltaT = rand_cb;
    Local = signalGen(config,caCode_filt,gamma);
    r = correlateSignal0(Local,config,x_delay_noise);
    J = sum(r,1);

    % test
%     norm(rand_position - param.UserPosition) < norm(position_est(it,:)- param.UserPosition)
%     J > J_ant
%     rand_position - position_est(it,:)

    % select or discard the point
    if J > J_ant
        position_est(it+1,:) = rand_position;
        cb_est(it+1,:)=rand_cb;
        J_ant = J;
        d = dmax;
        d_clk=dmax_clk;
    else
        position_est(it+1,:) = position_est(it,:);
        cb_est(it+1,:)=cb_est(it,:);
        d = d/contraction;
        d_clk=d_clk/contraction;
    end
    if d < dmin
        d = dmax;
    end     
    if d_clk < dmin_clk
        d_clk = dmax_clk;
    end
%     if mod(it,100) == 0
%         fprintf('ARS iteration #%d \n', it)
%     end
end

% DPE position estimation
PosErrDPE=norm(position_est(it+1,:)- param.UserPosition);
CBErrDPE = cb_est(it+1,:) - param.deltaT;
PosEstDPE = position_est(it+1,:);
%% visualization
% figure,
% plot((1:1:Niter),position_est(:,1)-param.UserPosition(1),"r")
% hold on
% plot((1:1:Niter),zeros(1,Niter),"b")
% figure,
% plot((1:1:Niter),cb_est(:,1),"r")
% hold on
% plot((1:1:Niter),param.deltaT(1,1)*ones(1,Niter),"b")