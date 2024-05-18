close all
clear all
clc

addpath("sampling")
rng(2024, "twister");

%% 4.1 - generate sampling plan
X_ff = log(fullfactorial([10 10],0)+1);
X_rlh = log(rlh(100,2,0)+1);

figure(1)
scatter(X_ff(:,1),X_ff(:,2))
hold;
scatter(X_rlh(:,1),X_rlh(:,2))
xlabel("K1")
ylabel("K2")
grid on
legend("Full Factorial","Latin Hypercube")

% logarithmic

%% 4.2 - assess sampling plan
Phiq_ff = mmphi(X_ff, 1, 1)
Phiq_rlh = mmphi(X_rlh, 1, 1)

Z_ff = evaluateControlSystem(X_ff);
Z_rlh = evaluateControlSystem(X_rlh);

% drop rows with inf
% Z_ff_inf = isinf(Z_ff);
% Z_ff(any(Z_ff_inf,2),:) = [];
% X_ff(any(Z_ff_inf,2),:) = [];
% 
% Z_rlh_inf = isinf(Z_rlh);
% Z_rlh(any(Z_rlh_inf,2),:) = [];
% X_rlh(any(Z_rlh_inf,2),:) = [];

performance_criteria = {
'Kp',
'Ki',
'maximum closed-loop pole magnitude',
'gain margin',
'phase margin',
'10-90% rise time',
'peak time',
'overshoot (% points)',
'undershoot (% points)',
'2% settling time',
'steady-state error (% points))',
'aggregate control input (MJ)}'};


% gain margin conversion to decibels


% create tables for parallelplots

tab_ff_val = [X_ff,Z_ff];
tab_ff = array2table(tab_ff_val,'VariableNames',performance_criteria);

tab_rlh_val = [X_rlh,Z_rlh];
tab_rlh = array2table(tab_rlh_val,'VariableNames',performance_criteria);

figure(2)
p1 = parallelplot(tab_ff)

figure(3)
p2 = parallelplot(tab_rlh)