function P = generatePopulation(X)

    % X should be a N x 2 matrix, where each row corresponds to 
    % ki and kp and N equals the budget size of candidate designs

    Z_0 = evaluateControlSystem(X); % gives you a N x 10 matrix
    
    % convert gain margins to decibels, and invert it for minimisation
    Z_0(:,2) = -20*log(Z_0(:,2));

    % convert phase margin into a range
    Z_0(:,3) = abs(50 - Z_0(:,3));

    % append input gains to evaluated metrics

    P = [X,Z_0];


end