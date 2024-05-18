clear all; close all; 

addpath("..\scripts\");
addpath("..\scripts\EA Toolbox");
addpath("..\scripts\evaluation\");
addpath("..\scripts\Hypervolume");
addpath("..\scripts\Mex files");
addpath("..\scripts\sampling");
rng(2024, "twister");

performance_criteria = {
'Kp',
'Ki',
'max closed-loop pole magnitude',
'gain margin',
'phase margin',
'10-90% rise time',
'peak time',
'overshoot (% points)',
'undershoot (% points)',
'2% settling time',
'steady-state error (% points))',
'aggregate control input (MJ)'};

samples = 100;
dimensions = 2;
font_label = 14;

f = waitbar(0,'1','Name','Running iterations',...
    'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');

%% 5.2.1 - only largest closed-loop pole priority level 1

% iterations = 50;
% goals = [1 -inf -inf -inf -inf -inf -inf -inf -inf -inf]; %  target values defined by context. optimisation should be less than these values.
% goals2 = [zeros(1,12) ; [1 1] goals];
% priorities = [1 0 0 0 0 0 0 0 0 0];

%% 5.2.2 - 100 iterations. closed loop at 2. other stability criteria and control effort at 1

% iterations = 100;
% goals = [1 6 20 -inf -inf -inf -inf -inf -inf 0.67];
% goals2 = [zeros(1,12) ; [1 1] goals];
% priorities = [2 1 1 0 0 0 0 0 0 1];

%% 5.2.3 - 150 iterations. match full range of preferences.

% iterations = 150;
% goals = [1 6 20 2 10 10 8 20 1 0.67]; %  target values defined by context. optimisation should be less than these values.
% goals2 = [zeros(1,12) ; [1 1] goals];
% priorities = [3 2 2 1 0 1 0 0 1 2];

%% own interpretation 

iterations = 250;
goals = [1 6 20 2 10 10 8 20 1 0.67]; %  target values defined by context. optimisation should be less than these values.
goals2 = [zeros(1,12) ; [1 1] goals];
priorities = [1 4 4 3 2 3 2 2 3 4];



O_rlh = rlh(samples,dimensions,0); % latin hypercube sample for 100 samples in 2 dimensions, with points at the centre of their grids
X_rlh = log(O_rlh+1); % take the log of the latin-hypercube sampled values, to increase density of sampling. add 1 to remove negative terms. max values limited to ln(2)

P = generatePopulation(X_rlh); % preprocesses input to evaluate for Z, changes gain margin unit to decibels, changes phase margin to distance from midpoint, appends inputs (for comparison)
P_start = P;
Phiq = mmphi(X_rlh, 1, 1)


for i = 1:iterations
    [RankV_parents,ClassV] = optimizeControlSystem(P(:,3:12),goals,priorities); % Rank 0 is best. Class contains highest value of priority that is violated. Satisfying points -1.
    RankV_parents = samples - RankV_parents;
    distances_parents = crowding(P,RankV_parents);
    selectThese = btwr(RankV_parents,distances_parents,samples);
    parents = P(selectThese,:);
    offspring = sbx(parents, goals2);
    postMute = polymut(offspring,goals2);
    X_children = postMute(:,1:2);
    P_children = generatePopulation(X_children);
    [RankV_children,ClassV] = optimizeControlSystem(P_children(:,3:12),goals,priorities); % Rank 0 is best. Class contains highest value of priority that is violated. Satisfying points -1.
    RankV_children = samples - RankV_children;
    distances_children = crowding(P,RankV_children);
    selectThese = btwr(RankV_children,distances_children,samples);
    children = P_children(selectThese,:);
    unifiedPop = [parents;children];
    ranks = [RankV_parents; RankV_children];
    crowdings = [distances_parents; distances_children];
    newPop = reducerNSGA_II(unifiedPop,ranks,crowdings);
    P = unifiedPop(newPop,:);
    % HV = Hypervolume_MEX()
    progress = i/iterations;
    waitbar(progress,f,"Iteration " + num2str(i) + " of " + num2str(iterations))
    scatter(P(:,1),P(:,2),"filled","black",'MarkerFaceAlpha',progress,'MarkerEdgeAlpha',progress)
    hold on
end

finalRanks = ranks(newPop,:);

ylabel("$K_p$",'Interpreter','latex', 'FontSize',font_label)
xlabel("$K_i$",'Interpreter','latex', 'FontSize',font_label)

display(P)

figure(2)
hold off
tab_rlh = array2table(P,'VariableNames',performance_criteria);
p2 = parallelplot(tab_rlh)

figure(3)
P_100 = P(finalRanks == 100,:)
scatter3(P(:,1),P(:,2),finalRanks,'filled')
ylabel("$K_p$",'Interpreter','latex', 'FontSize',font_label)
xlabel("$K_i$",'Interpreter','latex', 'FontSize',font_label)
zlabel("$Rank$",'Interpreter','latex', 'FontSize',font_label)
hold on
scatter3(P_100(:,1),P_100(:,2),finalRanks(finalRanks == 100),'filled','r')
legend("Dominated Solutions","Pareto Front")

for par = 4:12

    figure(par)
    scatter(P(:,par-1),P(:,par))
    hold on
    scatter(P_100(:,par-1),P_100(:,par),'filled','r')
    legend("Dominated Solutions","Pareto Front")
    xlabel(performance_criteria{par-1})
    ylabel(performance_criteria{par})
    xline(goals(par-1-2))
    yline(goals(par-2))

end