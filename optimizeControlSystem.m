function [RankV,ClassV] = optimizeControlSystem(population,goal,priority)
    % it is assumed all goals are to be minimised
    % goals, priority

    % non-dominated sorting
    [RankV, ClassV] = rank_prf(population,goal,priority);
    % Z = ranked_nds_P;
end