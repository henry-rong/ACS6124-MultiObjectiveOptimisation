function colors = colorvar(x, y)
    % Normalize x and y values
    x_norm = (x - min(x)) / (max(x) - min(x));
    y_norm = (y - min(y)) / (max(y) - min(y));
    
    % Initialize the color matrix
    colors = zeros(length(x), 3);
    
    % Assign colors based on normalized values using a continuous blend
    for i = 1:length(x)
        colors(i, :) = mapInputsToColors(x_norm(i), y_norm(i));
    end
end