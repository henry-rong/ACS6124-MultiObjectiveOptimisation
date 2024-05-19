function colors = colorvar(x,y)

    % Normalize x and y values
    x_norm = (x - min(x)) / (max(x) - min(x));
    y_norm = (y - min(y)) / (max(y) - min(y));
    
    % Initialize the color matrix
    colors = zeros(length(x), 3);
    
    % Assign colors based on normalized values using a continuous blend
    for i = 1:length(x)
        red = x_norm(i);     % Red intensity proportional to normalized x value
        blue = y_norm(i);    % Blue intensity proportional to normalized y value
        green = 0;           % No green component
        colors(i, :) = [red, green, blue];
    end

end