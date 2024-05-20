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

criteria_latex = {
'$K_p$',
'$K_i$',
'$|P_{CL}|$',
'$GM (dB)$',
'$PM (^o)$',
'$t_{10-90\%} \ (s)$',
'$t_{peak} \ (s)$',
'$\Delta_{over} \ (\%)$',
'$\Delta_{under} \ (\%)$',
'$t_{2\%} (s)$',
'$e_{ss} (\%)$',
'$E \ (MJ)$'};

samples = 100;
dimensions = 2;
font_label = 12;


% f = waitbar(0,'1','Name','Running iterations',...
%     'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');

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

%% 5.2.3 - match full range of preferences.

% iterations = 20;
% offset = 0.2*iterations;
% goals = [1 6 20 2 10 10 8 20 1 0.67]; %  target values defined by context. optimisation should be less than these values.
% bounds = [0 0 ; 1 1];
% priorities = [4 3 3 2 1 2 1 1 2 3];

%% sustainability case

iterations = 20;
offset = 0.2*iterations;
goals = [1 6 20 2 10 10 8 20 1 0.63]; %  target values defined by context. optimisation should be less than these values.
bounds = [0 0 ; 1 1];
priorities = [4 3 3 2 1 2 1 1 2 3];


X = net(sobolset(dimensions),samples);

% X = rlh(samples,dimensions,0);

% initialise population
P = generatePopulation(X);
P_start = P;

% enter main loop of optimiser
for i = 1:iterations

    % Step 1: Non-dominated sorting of parents
    ranks = rank_prf(P(:,3:12),goals,priorities); % Rank 0 is best. Class contains highest value of priority that is violated. Satisfying points -1.
    distances = crowding(P(:,3:12),ranks);

    % Step 2: Selection-for-variation operator: generate mating pool
    selectThese = btwr([ranks distances],samples);
    parents = P(selectThese,:);

    % Step 3: Produce offspring using variation operators
    postCross = sbx(parents(:,1:2), bounds);
    postMute = polymut(postCross,bounds);
    Q = generatePopulation(postCross);

    % Step 4: Selection-for-survival operator
    unifiedPop = [P;Q];
    ranks = rank_prf(unifiedPop(:,3:12),goals,priorities);
    distances = crowding(unifiedPop(:,3:12),ranks);
    newPop = reducerNSGA_II(unifiedPop(:,1:2),ranks,distances);
    P = unifiedPop(newPop,:);


    HV = Hypervolume_MEX(P(:,3:12),goals)

    % Visualise optimisation progress
    progress = (i+offset)/(iterations+offset);
    % waitbar(progress,f,"Iteration " + num2str(i) + " of " + num2str(iterations))
    display("Iteration " + num2str(i) + " of " + num2str(iterations))
    scatter(P(:,1),P(:,2),"filled","black",'MarkerFaceAlpha',progress,'MarkerEdgeAlpha',progress)
    hold on
end

% close(f)
% delete(f)

% invert gain margin for correct sign
P(:,4) = -P(:,4);

finalRanks = ranks(newPop,:);

xlim([0 1])
ylim([0 1])

xlabel("$K_p$",'Interpreter','latex', 'FontSize',font_label)
ylabel("$K_i$",'Interpreter','latex', 'FontSize',font_label)

hold off
%% k-means clustering
[idx,C] = kmeans(P(:,1:2),3);

distancesFromOrigin = sqrt(C(:, 1) .^ 2 + C(:, 2) .^2);
[sortedDistances, sortOrder] = sort(distancesFromOrigin, 'ascend')
newClassNumbers = zeros(length(idx), 1);
for k = 1 : size(C, 1)
    currentClassLocations = idx == k;
    newClassNumber = find(k == sortOrder);
    newClassNumbers(currentClassLocations) = newClassNumber;
end
idx = newClassNumbers;

figure(2)
set(gcf,'Position',[100 100 500 300])
plot(P(idx==1,1),P(idx==1,2),'r.','MarkerSize',12)
hold on
plot(P(idx==2,1),P(idx==2,2),'g*','MarkerSize',12)
plot(P(idx==3,1),P(idx==3,2),'bx','MarkerSize',12)
xlim([0 1])
ylim([0 1])
xlabel("$K_p$",'Interpreter','latex', 'FontSize',font_label)
ylabel("$K_i$",'Interpreter','latex', 'FontSize',font_label)
grid on

hold off


c_idx = zeros(samples,3);

for id = 1:length(idx)
    if idx(id) == 1
        red = 1;
        green = 0;
        blue = 0;
    end
    if idx(id) == 2
        red = 0;
        green = 1;
        blue = 0;
    end
    if idx(id) == 3
        red = 0;
        green = 0;
        blue = 1;
    end
    c_idx(id,:) = [red, green, blue];
end


%%
display(P)

figure(3)
set(gcf,'Position',[100 100 1000 400])
tab_rlh = array2table(P,'VariableNames',performance_criteria);
[B,I] = sortrows(idx,'descend');
p2 = parallelplot(tab_rlh,'GroupVariable','Kp','Color',c_idx);
p2.LegendVisible = 'off';
% S2 = struct(p2);
% S2.Axes.TickLabelInterpreter='latex';
% S2.Axes.XTickLabel = criteria_latex;

figure(4)
P_100 = P(finalRanks == min(finalRanks),:)
scatter3(P(:,1),P(:,2),finalRanks,'filled')
xlabel("$K_p$",'Interpreter','latex', 'FontSize',font_label)
ylabel("$K_i$",'Interpreter','latex', 'FontSize',font_label)
xlim([0 1])
ylim([0 1])
zlabel("$Rank$",'Interpreter','latex', 'FontSize',font_label)
hold on
scatter3(P_100(:,1),P_100(:,2),finalRanks(finalRanks ==  min(finalRanks)),'filled','r')
legend("Dominated Solutions","Pareto Front")

% create a matrix of subplots of pareto plots for every objective combination 

figure(5)
set(gcf,'Position',[100 100 1000 800])
tiledlayout(10,10, ...
    "TileSpacing","compact", ...
    "Padding","compact");

for objective_row = 1:10
    for objective_col = 1:objective_row
        tile_num = (objective_row-1)*10 + objective_col;
        nexttile(tile_num)

        hold on

        if objective_col ~= 1
            set(gca, "YTickLabel", []);
        else
            ylabel(criteria_latex{2 + objective_row},"Interpreter","latex",'FontSize',font_label)
            set(get(gca,'YLabel'),'Rotation',90)
        end
        if objective_row ~= 10
            set(gca, "XTickLabel", []);
        else
            xlabel(criteria_latex{2 + objective_col},"Interpreter","latex",'FontSize',font_label)
        end

        if objective_col == objective_row
            [f,xi] = ksdensity(P(:,2 + objective_col));
            plot(xi,f,'LineWidth',2)
        else
            g = gscatter(P(:,2 + objective_col),P(:,2 + objective_row),idx,'rgb','o*x',4,'off');
            yline(goals(objective_row),':')
            xline(goals(objective_col),':')
            
            xrange = [goals(objective_col); P(:,2 + objective_col)];
            xmin = min(xrange);
            xmax = max(xrange);

            yrange = [goals(objective_row); P(:,2 + objective_row)];
            ymin = min(yrange);
            ymax = max(yrange);

            xlim([0.9*xmin xmax*1.1])
            ylim([0.9*ymin ymax*1.1])
        end

        hold on

    end
end

hold off