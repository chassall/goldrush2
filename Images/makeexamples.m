% Make Gold Rush maps of arbitrary size
% C. Hassall
% November, 2017


close all; clear all;

num_maps = 100;
% map_size = [1080,1852]; % In display coordinates (height, width)
map_size = [800,800];
isSparse = 0;

screenWidth = 478; % mm POOCHIE
screenHeight = 268; % mm POOCHIE

% Display properties (W,H)
% 1920 X 1080
% 478 mm by 268 mm
% 4.0167 px/mm and 4.0229 px/mm

% WACOM
% 462 mm wide by 320 mm high

xMid = map_size(2)/2;
yMid = map_size(1)/2;
hz = 80/2; % 80 by 80 pixels
% homeZone =  [(xMid - hz) (map_size(1) - hz*2) (xMid + hz)  map_size(1)]; % "Home Zone" in display coordinates
homeZone =  [(xMid - hz) (yMid - hz) (xMid + hz)  yMid+hz]; % "Home Zone" in display coordinates
all_maps = [];
all_means = [];

for map_counter = 1:num_maps
    
    my_map = makemap(map_size, isSparse, homeZone);
    all_means = [all_means mean(mean(my_map))];
    all_maps{map_counter} = my_map;

    % Plot map (map coordinates)
    h = surf(my_map,'EdgeColor','interp');
    view(2);
    axis equal tight;
    axis off;
    caxis([0 100]);
%     drawnow();
%     pause();
    
    % Save figure
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 map_size(2)/100 map_size(1)/100])
    set( gca, 'Units', 'normalized', 'Position', [0 0 1 1] );
    saveas(h,['map_' num2str(map_counter) '.jpg']);
   
    % Open and resize
    temp_image = imread(['map_' num2str(map_counter) '.jpg']);
    temp_image = imresize(temp_image,map_size);
    imwrite(temp_image,['map_' num2str(map_counter) '.jpg']);
end

save('all_maps.mat','all_maps');