close all
clear all
clc

font_label = 14;

addpath("..\scripts\");
addpath("..\scripts\EA Toolbox");
addpath("..\scripts\evaluation\");
addpath("..\scripts\Hypervolume");
addpath("..\scripts\Mex files");
addpath("..\scripts\sampling");
rng(2024, "twister");

%% 4.1 - generate sampling plans

% full factorial
X_ff = log(fullfactorial([10 10],0)+1);

% latin hypercube
X_rlh = log(rlh(100,2,0)+1);

% Initialize the color matrices
c_ff = colorvar(X_ff(:,1),X_ff(:,2));
c_rlh = colorvar(X_rlh(:,1),X_rlh(:,2));

figure(1)
scatter(X_ff(:,1),X_ff(:,2),20,c_ff, 'filled')
ylabel("$K_p$",'Interpreter','latex', 'FontSize',font_label)
xlabel("$K_i$",'Interpreter','latex', 'FontSize',font_label)
grid on
figure(2)
scatter(X_rlh(:,1),X_rlh(:,2),20,c_rlh, 'filled')
ylabel("$K_p$",'Interpreter','latex', 'FontSize',font_label)
xlabel("$K_i$",'Interpreter','latex', 'FontSize',font_label)
grid on

% logarithmic

%% 4.2 - assess sampling plan
Phiq_ff = mmphi(X_ff, 1, 1)
Phiq_rlh = mmphi(X_rlh, 1, 1)

P_ff = evaluateControlSystem(X_ff);
P_rlh = evaluateControlSystem(X_rlh);

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
'max closed-loop pole',
'gain margin',
'phase margin',
'10-90% rise time (s)',
'peak time (s)',
'overshoot (% points)',
'undershoot (% points)',
'2% settling time (s)',
'steady-state error (% points))',
'aggregate control input (MJ)}'};


% preprocess gain margin and phase margins
P_ff = generatePopulation(X_ff);
P_rlh = generatePopulation(X_rlh);

% create tables for parallelplots
tab_ff = sortrows(array2table(P_ff, 'VariableNames', performance_criteria),1);
tab_rlh = sortrows(array2table(P_rlh, 'VariableNames', performance_criteria),1);


%% Plot the parallel coordinates with custom colors for each group
figure(3)
% subplot(1,13,[1:12])
p1 = parallelplot(tab_ff, 'GroupVariable', "Kp", 'Color', sortrows(c_ff,3),'DataNormalization','range');
p1.LegendVisible = 'off';
xlabel('Dimensions');
ylabel('Values');
grid on;

% subplot(1,13,13)
% [B,I_ff] = sort(sum(c_ff,2))
% sorted_c_ff = c_ff(I_ff,:)
% ncolors = size(sorted_c_ff, 1);
% image(1, linspace(0,1,ncolors), (1:ncolors)'); axis xy
% colormap(sorted_c_ff);

figure(4)
% subplot(1,13,[1:12])
p2 = parallelplot(tab_rlh, 'GroupVariable', "Kp", 'Color', sortrows(c_rlh,3),'DataNormalization','range');
p2.LegendVisible = 'off';
xlabel('Dimensions');
ylabel('Values');
grid on;

% subplot(1,13,13)
% [B,I_rlh] = sort(sum(c_rlh,2))
% sorted_c_rlh = c_rlh(I_rlh,:)
% ncolors = size(sorted_c_rlh, 1);
% image(1, linspace(0,1,ncolors), (1:ncolors)'); axis xy
% colormap(sorted_c_ff);
