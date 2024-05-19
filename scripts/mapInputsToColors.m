function rgbColor = mapInputsToColors(x, y)
    % Calculate the green intensity as the average of x and y
    green = (x + y) / 2;
    
    % Red and blue intensities are proportional to x and y, respectively,
    % but decreased as green increases
    red = x * (1.5 - green);
    blue = y * (1.5 - green);
    
    % Combine into RGB vector
    rgbColor = [red, green, blue];
end
