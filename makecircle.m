function [ circle ] = makecircle( imageDim, x, y, radius )
%MAKECIRCLE Makes a circle of value 1 at x,y
%   Detailed explanation goes here

    circle = zeros(imageDim);
    % X coordinate
    for i = 1:imageDim(1)
        % Y coordinate
        for j = 1:imageDim(2)
            
            thisDistance = sqrt((i - y)^2 + (j - x)^2);
            if thisDistance <= radius
               circle(i,j) = 1; 
            end
        end
        
    end

end

