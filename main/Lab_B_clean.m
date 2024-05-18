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

samples = 100;
dimensions = 2;
goals = [1 6 20 2 10 10 8 20 1 0.67]; %  target values defined by context. optimisation should be less than these values.
goals2 = [zeros(1,12) ; [1 1] goals];
priorities = [1 4 4 3 2 3 2 2 3 4]; % higher is higher priority, 1 is hard constaint

O_rlh = rlh(samples,dimensions,0); % latin hypercube sample for 100 samples in 2 dimensions, with points at the centre of their grids
X_rlh = log(O_rlh+1); % take the log of the latin-hypercube sampled values, to increase density of sampling. add 1 to remove negative terms. max values limited to ln(2)

P = generatePopulation(X_rlh); % preprocesses input to evaluate for Z, changes gain margin unit to decibels, changes phase margin to distance from midpoint, appends inputs (for comparison)
P_start = P;
Phiq = mmphi(X_rlh, 1, 1)


for i = 1:10

    % Non-dominated sorting
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
    display("Iteration " + num2str(i) + " Complete")

end

display(P)

