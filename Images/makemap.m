function map_out = makemap( map_size, is_sparse, homeZone )
%MAKEMAP Summary of this function goes here
%   Creates a map for underground gold
%   C. Hassall
%   January, 2015

if is_sparse
    sf = 50000; % May need to change this depending on map size
else
    sf = 10000;
end

% "Home Zone" in map coordinates
homeZoneX = homeZone(1):homeZone(3);
homeZoneY = (map_size(1)-homeZone(4)+1):(map_size(1)-homeZone(2)+1);

% How many peaks for this map?
if is_sparse
    num_peaks = 1;
else
    num_peaks = 3 + randi(3);
end

[X1,X2] = meshgrid(linspace(1,map_size(2),map_size(2))', linspace(1,map_size(1),map_size(1))');
X = [X1(:) X2(:)];

% Come up with locations - exclude "home zone" pixels
for i = 1:num_peaks
    inHomeZone = 1;
    while inHomeZone
        location_x(i) = randi([1 map_size(2)]);
        location_y(i) = randi([1 map_size(1)]);
        % inHomeZone = location_x(i) > homeZone(1) && location_x(i) < homeZone(3) && location_y(i) > homeZone(2) && location_y(i) < homeZone(4);
        inHomeZone = ismember(location_x(i),homeZoneX) || ismember(location_y(i),homeZoneY);
    end
end

% Come up with payouts
if is_sparse
    maxes = 100;
else
    temp = 49 + randperm(51); % Range 50 - 100
    maxes = temp(1:num_peaks);
    maxes = 100 * maxes ./ max(maxes);
end

thisMean = 0;
% Require that mean map value is between 10 and 20%
while thisMean < 10 || thisMean > 20
    
    map_out = zeros(map_size(1),map_size(2)); % Initialize output
    
    for counter = 1:num_peaks
        mu = [location_x(counter) location_y(counter)];
        % thisOffDiagonal = 2*rand;
        thisOffDiagonal = 2*(rand-0.5);
        thisTL = rand;
        thisBR = rand;
        thisSigma = sf*[thisTL thisOffDiagonal; thisOffDiagonal thisBR];
        [~,p] = chol(thisSigma);
        
        % Produce a pos def matrix for the pdf function
        while p>0
            % Come up with locations - exclude "home zone" pixels
            for i = 1:num_peaks
                inHomeZone = 1;
                while inHomeZone
                    location_x(i) = randi([1 map_size(2)]);
                    location_y(i) = randi([1 map_size(1)]);
                    %inHomeZone = location_x(i) > homeZone(1) && location_x(i) < homeZone(3) && location_y(i) > homeZone(2) && location_y(i) < homeZone(4);
                    inHomeZone = ismember(location_x(i),homeZoneX) || ismember(location_y(i),homeZoneY);
                end
            end
            
            %             thisRand = randn;
            %             rand1 = randn;
            %             rand2 = randn;
            %             disp([rand1 thisRand; thisRand rand2]);
            thisTL = rand;
            thisBR = rand;
            thisOffDiagonal = 2*(rand-0.5);
            thisSigma = sf*[thisTL thisOffDiagonal; thisOffDiagonal thisBR];
            [~,p] = chol(thisSigma);
        end
        
        % thisSigma = [10000 9000; 9000 10000];
        reward = mvnpdf(X,mu,thisSigma);
        reward = reshape(reward,map_size(1),map_size(2));
        
        % Normalize rewards
        z_max = max(max(reward));
        reward = reward ./ z_max;
        
        % Scale so that rewards go from 1 to 100;
        reward = reward .* maxes(counter);
        
        % Set home zone to zero
        reward(homeZoneY,homeZoneX) = 0;
        
        map_out = map_out + reward;
    end
    
    % Scale map so that 100 is the max
    map_out = 100*map_out ./max(max(map_out));
    thisMean = mean(mean(map_out))
end

end

