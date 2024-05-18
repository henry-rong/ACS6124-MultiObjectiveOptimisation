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

iterations = 150;
goals = [1 6 20 2 10 10 8 20 1 0.67]; %  target values defined by context. optimisation should be less than these values.
goals2 = [zeros(1,12) ; [1 1] goals];
priorities = [3 2 2 1 0 1 0 0 1 2];

%% own interpretation 

% iterations = 150;
% goals = [1 6 20 2 10 10 8 20 1 0.67]; %  target values defined by context. optimisation should be less than these values.
% goals2 = [zeros(1,12) ; [1 1] goals];
% priorities = [1 4 4 3 2 3 2 2 3 4];

O_rlh = rlh(samples,dimensions,0); % latin hypercube sample for 100 samples in 2 dimensions, with points at the centre of their grids
X_rlh = log(O_rlh+1); % take the log of the latin-hypercube sampled values, to increase density of sampling. add 1 to remove negative terms. max values limited to ln(2)
Phiq = mmphi(X_rlh, 1, 1)

% initialise population
P = generatePopulation(X_rlh); % preprocesses input to evaluate for Z, changes gain margin unit to decibels, changes phase margin to distance from midpoint, appends inputs (for comparison)
RankV_parents = samples - rank_prf(P(:,3:12),goals,priorities); % Rank 0 is best. Class contains highest value of priority that is violated. Satisfying points -1.
distances_parents = crowding(P,RankV_parents);
selectThese = btwr(RankV_parents,distances_parents,samples);
P = P(selectThese,:);
P_start = P;

% enter main loop of optimiser
for i = 1:iterations

    % evaluate fitness of parents
    parents = P;
    RankV_parents = samples - rank_prf(parents(:,3:12),goals,priorities); % Rank 0 is best. Class contains highest value of priority that is violated. Satisfying points -1.
    distances_parents = crowding(parents,RankV_parents);

    % produce offspring
    offspring = sbx(parents, goals2);
    postMute = polymut(offspring,goals2);
    X_children = postMute(:,1:2);
    P_children = generatePopulation(X_children);

    % evaluate fitness of children
    RankV_children = samples - rank_prf(P_children(:,3:12),goals,priorities); % Rank 0 is best. Class contains highest value of priority that is violated. Satisfying points -1.
    distances_children = crowding(P_children,RankV_children);

    % concatenate evaluated parents
    unifiedPop = [parents;children];
    ranks = [RankV_parents; RankV_children];
    crowdings = [distances_parents; distances_children];

    % evaluate fitnesses
    selectThese = btwr(ranks,crowdings,samples);
    unifiedPop = unifiedPop(selectThese,:);

    % selection-for-survival operator
    newPop = reducerNSGA_II(unifiedPop,ranks,crowdings);
    P = unifiedPop(newPop,:);
    % HV = Hypervolume_MEX()

    % visualise optimisation progress
    progress = i/iterations;
    waitbar(progress,f,"Iteration " + num2str(i) + " of " + num2str(iterations))
    % display("Iteration " + num2str(i) + " of " + num2str(iterations))
    scatter(P(:,1),P(:,2),"filled","black",'MarkerFaceAlpha',progress,'MarkerEdgeAlpha',progress)
    hold on
end

close(f)
delete(f)

finalRanks = ranks(newPop,:);

ylabel("$K_p$",'Interpreter','latex', 'FontSize',font_label)
xlabel("$K_i$",'Interpreter','latex', 'FontSize',font_label)

hold off
display(P)

figure(2)

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

% create a matrix of subplots of pareto plots for every objective combination 

figure(4)
hold on
tiledlayout(10,10, ...
    "TileSpacing","compact", ...
    "Padding","compact");

for objective_row = 1:10
    for objective_col = 1:objective_row
        tile_num = (objective_row-1)*10 + objective_col;
        nexttile(tile_num)
        if objective_col == 1
            ylabel(performance_criteria{2 + objective_row})
        elseif objective_row == 10
            xlabel(performance_criteria{2 + objective_col})
        end

        if objective_col == objective_row

            histogram(P(:,2 + objective_col))
        else

            scatter(P(:,2 + objective_col),P(:,2 + objective_row),'filled')
        end
    end
end

hold off