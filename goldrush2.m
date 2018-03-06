% Gold Rush 2
% C. Hassall and O. Krigolson
% December, 2017    

% Participants choose locations at which to dig for gold. The likelihood of
% finding gold at a particular location is determined by an unseen
% probability distribution, which shrinks with each choice.

%% Standard Krigolson Lab pre-script code

close all; clear variables; clc; % Clear everything
rng('shuffle'); % Shuffle the random number generator
InitializePsychSound(); % Load PTB audio driver
ListenChar(0);

%% Run flags

justTesting = 0; % Testing mode - run in a smaller window
krigolsonLab = 1; % 1 if experiment is run in the Krigolson Lab, 0 otherwise (if 1, DataPIXX2 needed to send markers)

%% Define control keys

KbName('UnifyKeyNames'); % Ensure that key names are mostly cross-platform
ExitKey = KbName('ESCAPE'); % Exit program

%% Display properties (CHANGE THESE)

% Testing room (POOCHIE; 75 Hz, 2 ms response rate, 1920 by 1080 pixels, LG W2242TQ-GF, Seoul, South Korea)
viewingDistance = 620; % mm, approximately
screenWidth = 478; % mm
screenHeight = 268; % mm
horizontalResolution = 1920; % Pixels
verticalResolution = 1080; % Pixels

% Cam's laptop (BOB; Macbook Air)
% viewingDistance = 560; % mm, approximately
% screenWidth = 286; % mm
% screenHeight = 179; % mm
% horizontalResolution = 1440; % Pixels
% verticalResolution = 980; % Pixels

% Cam's office (MARGE; iMac)
% viewingDistance = 700; % mm, approximately
% screenWidth = 598; % mm
% screenHeight = 338; % mm
% horizontalResolution = 2560; % Pixels
% verticalResolution = 1440; % Pixels

horizontalPixelsPerMM = horizontalResolution/screenWidth;
verticalPixelsPerMM = verticalResolution/screenHeight;

%% Wacom settings (unused)

wacomHor = 462; % mm
wacomVer = 320; % mm
wcScale = [1 screenHeight/wacomVer];

%% Participant info and data

trialData = []; % Trial information
allMovementData = {}; % Cell array with each trial's movement data

if justTesting
    participantNum = '99';
    rundate = datestr(now, 'yyyymmdd-HHMMSS');
    trialDataFilename = strcat('goldrush2_', rundate, '_', participantNum, '.txt');
    movementFilename = strcat('goldrush2_xy_', rundate, '_', participantNum, '.mat');
    sex = 'M';
    age = '21';
    handedness = 'R';
else
    while 1
        clc;
        participantNum = input('Enter the participant number:\n','s');  % get the subject name/number
        rundate = datestr(now, 'yyyymmdd-HHMMSS');
        trialDataFilename = strcat('goldrush2_', rundate, '_', participantNum, '.txt');
        checker1 = ~exist(trialDataFilename,'file');
        checker2 = isnumeric(str2double(participantNum)) && ~isnan(str2double(participantNum));
        if checker1 && checker2
            break;
        else
            disp('Invalid number, or filename already exists.');
            WaitSecs(1);
        end
    end
    movementFilename = strcat('goldrush2 _xy_', rundate, '_', participantNum, '.mat');
    sex = input('Sex (M/F): ','s');
    age = input('Age: ');
    handedness = input('Handedness (L/R): ','s');
end

% Store important info for this participant
runLine = [num2str(participantNum) ', ' datestr(now) ', ' sex, ', ' handedness ', ' num2str(age)];
dlmwrite('participant_info.txt',runLine,'delimiter','', '-append');

%% Experiment Parameters

% Response information
usingWacom = 0; % Set to 1 if using the WACOM tablet (assume mouse otherwise)
speedThreshold = 0.03; % May need to change this depending on input device

% Map information
showMapAtEnd = 0; % 1 if we show thisMap at end of each block
% mapSize = [1080,1852]; % Map size (y,x)
mapSize = [800, 800];
dotSize = 2; % Size of dots when rendering maps (dotSize = 1 looks funny on some displays)
defaultColourMap = colormap; % For colouring the maps

% Dig information
useMeanP = 1; % True if success is based on the mean probability within the dig area (as opposed to a single pixel)
digRadius = 40; % Size of area to dig (half-width of dig circle)
digAmount = .20; % Amount to drop probability by after each dig

% Blocks and trials
% Note: each trial takes around 4.5 seconds, so in an hour participants can
% do 60*60/4.5 = 800 trials, or 20 blocks of 40 trials each
best_block = 0;
nExperimentBlocks = 20; % Should be double the number of maps of each type.
if justTesting
    numTrials = 4;
else
    numTrials = 40;
end
nPracticeBlocks = 2; % Should be a multiple of 2
nMaps = (nExperimentBlocks + nPracticeBlocks)/2; % How many maps of each type?
blockAdaptive = 1; % True if task adapts based on block performance
aBlockExp = 1;
sBlockExp = 1;

% Visual properties
bgColour = [0 0 0]; % Background colour (black)
textColour = [255 255 255]; % Text colour (white)
homeColour = [0 0 0]; % Colour of home zone (black)
homeOutline = [255 255 255]; % Colour of home zone outline (white)
homeSize = 40; % Half-width of home square
mapOutlineColour = [255 255 255]; % Map outline colour (white)
markerColour = [255 255 255]; % Previous dig location colour (white)
markerSize = 3; % Half-width of previous dig markers, in pixels

% Load images
sparseImage = imread('./Images/sparse.jpg');
abundantImage = imread('./Images/abundant.jpg');
[mineImage,mineMap,mineAlpha] = imread('./Images/mine-145631_1280.png');
[fb1, map1, alpha1] = imread('./Images/gold.png');
[fb2, map2, alpha2] = imread('./Images/stone.png');
[v1,h1,~] = size(fb1);
[v2,h2,~] = size(fb2);
fbRatios = [v1/h1,v2/h2];
fb1(:,:,4) = alpha1;
fb2(:,:,4) = alpha2;
mineImage(:,:,4) = mineAlpha;


%% Experiment

try
        
    % Try to ensure participants see a proper arrow cursor
    ShowCursor('Arrow');
    
    % Make window
    if justTesting
        Screen('Preference', 'SkipSyncTests', 1); % Comment out, if possible
        [win, rec] = Screen('OpenWindow', 0, bgColour,[0 0 900 900], 32, 2);
    else
        Screen('Preference', 'SkipSyncTests', 1); % Comment out, if possible
        [win, rec] = Screen('OpenWindow', 0, bgColour);
    end
    Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    % Window properties
    horRes = rec(3);
    verRes = rec(4);
    xmid = round(rec(3)/2);
    ymid = round(rec(4)/2);
    xOffset = (horRes-mapSize(2))/2; % Images are shorter than display by 68 pixels
    yOffset = (verRes-mapSize(1))/2;

    % Map outline
    mapOutlineRect = [xmid-mapSize(2)/2 ymid-mapSize(1)/2 xmid+mapSize(2)/2 ymid+mapSize(1)/2];
    
    % Home position outline
    % homeRect = [(xOffset+(mapSize(2)/2)-homeSize)
    % (yOffset+(mapSize(1))-homeSize*2) (xOffset+(mapSize(2)/2)+homeSize) (yOffset+(mapSize(1)))]; bottom of display
    homeRect = [(xOffset+(mapSize(2)/2)-homeSize) (yOffset+(mapSize(1)/2)-homeSize) (xOffset+(mapSize(2)/2)+homeSize) (yOffset+(mapSize(1)/2) +homeSize)]; % Middle of display

    % Make screen textures
    sTexture = Screen('MakeTexture', win, sparseImage);
    aTexture = Screen('MakeTexture', win, abundantImage);
    win_texture = Screen('MakeTexture', win, fb1);
    loss_texture = Screen('MakeTexture', win, fb2);
    mineTexture = Screen('MakeTexture',win,mineImage);
    
    % Display "loading maps"
    Screen('DrawTexture', win, mineTexture);
    Screen(win,'TextFont','Arial');
    Screen(win,'TextSize',20);
    DrawFormattedText(win,'loading maps','center','center',textColour);
    Screen('Flip',win);
    
    % Load maps
    aMapOrder = randperm(100,nMaps); % Pick from among the 100 potential maps
    sMapOrder = randperm(100,nMaps); % Pick from among the 100 potential maps
    aMaps = {};
    sMaps = {};
    for m = 1:nMaps
        load(['./Images/Abundant/' num2str(aMapOrder(m),'%0.3d') '.mat']);
        aMaps{m} = thisMap;
        load(['./Images/Sparse/' num2str(sMapOrder(m),'%0.3d') '.mat']);
        sMaps{m} = thisMap;
    end
     
    % Feedback visual properties
    fbDegrees = 2; % Feedback width, in degrees
    fbHMMs = 2 * viewingDistance *tand(fbDegrees/2); % Feedback width, in mms
    fbVMMs =  fbRatios .* fbHMMs; % Feedback height, in mms
    fbHorizontalPixels = horizontalPixelsPerMM * fbHMMs;
    fbVerticalPixels = verticalPixelsPerMM * fbVMMs;
    feedback_rect = [xmid - fbHorizontalPixels/2 ymid - fbVerticalPixels(1)/2 xmid + fbHorizontalPixels/2 ymid + fbVerticalPixels(1)/2;...
        xmid - fbHorizontalPixels/2 ymid - fbVerticalPixels(2)/2 xmid + fbHorizontalPixels/2 ymid + fbVerticalPixels(2)/2];
    
    % Practice rounds
    numPracticeMaps = nPracticeBlocks / 2;
    
    is_sparse_practice = mod(randperm(nPracticeBlocks),2);
    is_sparse_regular = mod(randperm(nExperimentBlocks),2);
    isSparse = [is_sparse_practice is_sparse_regular];
    aCount = 0;
    sCount = 0;
    
    % Instructions
    instructions{1} = 'GOLD RUSH\nIn this experiment you will select locations at which to dig for gold\nYour goal is to find as much gold as possible, while avoiding rocks\nSome locations are more likely to yield gold than others\nThe more you dig at a location the less likely you are to find gold there in the future\n(press any key to continue)';
    instructions{2} = 'TWO ENVIRONMENTS\nYou will dig in two environments\nPrior to each round, you will see a cue indicating the environment\nIn one environment (bottom left), gold is distributed across many locations\nIn the other environment (bottom right), gold is located at one location only\nThe total amount of gold in each type of environment is the same\nThe actual gold locations are randomly generated for each round\n(press any key to continue)';
    instructions{3} = 'HOW TO DIG\nStart with the cursor in the home position (square at center of display)\nWhen you hear a beep, move the cursor as quickly as you can to the desired location\n(If the cursor slows down too much, the computer will assume you have chosen a dig location)\n\n\n\n\n\nTo see what you dug up, bring the cursor back to the home position\nYou will then be shown what you found (gold or rock)\n(press any key to continue)';
    instructions{4} = 'EEG QUALITY\nPlease try to minimize all head and eye movements\nKeep your gaze within the square at the center of the display at all times\n(Try not to follow the cursor position with your eyes)\nWait until you hear a "beep" to respond\nYou will be given regular rest breaks - please take this opportunity to close your eyes or blink as needed\n(press any key to continue)';
    instructions{5} = 'SUMMARY\nTry to find as much gold as possible\nGold runs out! The more you dig in one spot, the less gold you will find there in the future\nGold is either spread out or in one spot (pay attention to the cue before each round)\n(press any key to continue)';
    instructions{6} = 'PRACTICE\nYou will now do some practice rounds\nDuring the practice rounds, you will be shown the underlyng gold locations\n(The gold locations will be hidden during the actual game)\nNotice that digging reduces the amount of gold at the dig location\n(press any key to begin practice)';
    for i = 1:length(instructions)
        Screen(win,'TextFont','Arial');
        Screen(win,'TextSize',24);
        Screen('DrawTexture', win, mineTexture);
        DrawFormattedText(win,instructions{i},'center','center',textColour);
        switch i
            case 2
                Screen('DrawTexture', win, aTexture,[],[xmid-500 ymid+200 xmid-300 ymid+400]);
                Screen('DrawTexture', win, sTexture,[],[xmid+300 ymid+200 xmid+500 ymid+400]);
            case 3
                Screen('FillRect',win,homeColour,homeRect);
                Screen('FrameRect',win,homeOutline,homeRect);
        end
        Screen('Flip',win);
        KbReleaseWait();
        KbPressWait();
    end

    % Block variable (across block)
    lastABlockPerformance = 0.5; % Previous abundant block's accuracy
    lastSBlockPerformance = 0.5; % Previous sparse block's accuracy
    
    % Main block loop
    for blockCounter = 1:nExperimentBlocks+nPracticeBlocks
        
        % Block variables (within block)
        stillPracticing = blockCounter <= nPracticeBlocks; % Practice round?
        guesses = [];
        % trialSoFar = 0;
        thisBlockReward = 0; % Total number of wins within a block
        
        % Get approprate map
        if isSparse(blockCounter)
            sCount = sCount + 1;
            mapIndex = sMapOrder(sCount);
            thisMap = double(sMaps{sCount});
            thisBlockTexture = sTexture;
            blockMarker = 1;
            preMovementMarker = 2;
            goMarker = 3;
            responseMarker = 4;
            preFeedbackMarker = 5;
            loseMarker = 6;
            winMarker = 7;
        else
            aCount = aCount + 1;
            mapIndex = aMapOrder(aCount);
            thisMap = double(aMaps{aCount});
            thisBlockTexture = aTexture;
            blockMarker = 11;
            preMovementMarker = 12;
            goMarker = 13;
            responseMarker = 14;
            preFeedbackMarker = 15;
            loseMarker = 16;
            winMarker = 17;
        end
        
        % Convert map (1-100) to probabilities (0-1) and get map size
        thisPMap = thisMap./100;
        [maxY,maxX] = size(thisMap);
        
        % Adjust probability map as needed (regular rounds only)
        if blockAdaptive && ~stillPracticing
            if isSparse(blockCounter)
                if lastSBlockPerformance < 0.5 && sBlockExp ~= 0.1
                    sBlockExp = sBlockExp - 0.1;
                elseif lastSBlockPerformance > 0.5 && sBlockExp ~= 2
                    sBlockExp = sBlockExp + 0.1;
                end
                thisPMap = thisPMap .^ sBlockExp; % Adjust probabilities
            else
                if lastABlockPerformance < 0.5 && aBlockExp ~= 0.1
                    aBlockExp = aBlockExp - 0.1;
                elseif lastABlockPerformance > 0.5 && aBlockExp ~= 2
                    aBlockExp = aBlockExp + 0.1;
                end
                thisPMap = thisPMap .^ aBlockExp; % Adjust probabilities
            end
        end
        
        % Draw block cue for two seconds
        Screen('DrawTexture', win, thisBlockTexture);
        if krigolsonLab
            flipandmark(win,blockMarker);
        else
            Screen('Flip',win);
            % TODO: send blockMarker
        end
        WaitSecs(2);
        
        tic;
        % Trial loop
        for trialCounter = 1:numTrials
            
            %% Trial variables
            movementData = []; % time, x, y during movement
            speed = Inf; % End point reached whenever this drops below a threshold
            rawX = NaN;
            rawY = NaN;
            mapX = NaN;
            mapY = NaN;
            
            %% Fixation (Pre-Response Period)
            
            % Prepare trial marker
            if isSparse(blockCounter)
                trialMarker = trialCounter; % Markers: 1-numTrials , e.g. 1-50
            else 
                trialMarker = 100 + trialCounter; % Markers: 100-100+numTrials, e.g. 101-150
            end
            
            % Display map and previous dig locations during testing and practice
            if justTesting || stillPracticing
                [i,j,~] = find(thisPMap >= 0);
                thisMap64 = ceil(thisPMap(:)'*64);
                thisMap64(thisMap64==0) = 1; % Ensure that we have pos index
                thisMap64(thisMap64>64) = 64; % Ensure that we don't go beyond 64
                thisColourMap = defaultColourMap(thisMap64,:)';
                thisMapXY = [xOffset + j';yOffset + maxY - i' + 1];
                Screen('DrawDots',win,thisMapXY,dotSize,ceil(255*thisColourMap));
                if justTesting
                    Screen(win,'TextFont','Courier');
                    Screen(win,'TextSize',12);
                    DrawFormattedText(win,['\nraw position: ' num2str([rawX rawY]) '\nmap position: ' num2str([mapX, mapY]) '\nthisBlockReward: ' num2str(thisBlockReward)],[],[],textColour);
                end
            end
            
            % Map boundaries
            Screen('FrameRect',win,mapOutlineColour,mapOutlineRect);
            
            % Home Zone
            Screen('FillRect',win,homeColour,homeRect);
            Screen('FrameRect',win,homeOutline,homeRect);
            
            % Previous dig locations
            if trialCounter > 1
                rectXs = xOffset + guesses(:,1);
                rectYs = yOffset + mapSize(1) - guesses(:,2);
                theRects = [rectXs-markerSize rectYs-markerSize rectXs + markerSize rectYs + markerSize];
                Screen('FillRect',win,markerColour,theRects');
            end
            if krigolsonLab
                flipandmark(win,preMovementMarker);
            else
                Screen('Flip',win);
                % TODO: send preMovementMarker
            end
            
            %% Pre-Response
            
            % Do not proceed until cursor is in home position
            [currentX, currentY, ~] = GetMouse; % Should work for a mouse or tablet
            inTheZone = currentX > homeRect(1) && currentX < homeRect(3) && currentY > homeRect(2) && currentY < homeRect(4);
            targetTimeInZone = .600 + rand*.400; % Wait 600-1000 ms before go cue
            zoneStartTime = GetSecs();
            timeInZone = 0;
            % Loop until cursor has been in the home position for some time
            while ~inTheZone || timeInZone < targetTimeInZone
                [currentX, currentY, ~] = GetMouse;
                inTheZone = currentX > homeRect(1) && currentX < homeRect(3) && currentY > homeRect(2) && currentY < homeRect(4);
                if inTheZone
                    timeInZone = GetSecs() - zoneStartTime;
                else
                    zoneStartTime = GetSecs();
                end
            end
            if krigolsonLab
                sendmarker(goMarker)
            else
                % TODO: send goMarker
            end
            Beeper(400,0.4,0.05); % Go cue: 400 Hz sine tone for 50 ms
            
            %% Response
            
            startTime = GetSecs();
            while 1
                % Get cursor position in display coordinates; origin is top left of display
                [rawX, rawY, buttons] = GetMouse;
                
                % Check if the cursor is still in the home position
                % Note that homeRect is in display coordinates
                inTheZone = rawX > homeRect(1) && rawX < homeRect(3) && rawY > homeRect(2) && rawY < homeRect(4);
                
                % Get time
                thisTime = GetSecs() - startTime;
                
                % Transform cursor position to map coordinates; origin is lower left of image
                mapX = round(rawX) - xOffset;
                mapY = round(rawY) - yOffset;
                mapY = mapSize(1) - mapY; % Flip y to match the image
                
                % Bound the map coordinates
                if mapX <= 0
                    mapX = 1;
                elseif mapX > maxX
                    mapX = maxX;
                end
                if mapY <= 0
                    mapY = 1;
                elseif mapY > maxY
                    mapY = maxY;
                end
                
                movementData = [movementData; thisTime mapX mapY]; % Note that there will be many duplicates here - can be filtered later
                         
                % Compute current speed
                if length(movementData) > 1000
                    xyspeed = movementData(end-999:end,2:3) - movementData(end-1000:end-1,2:3);
                    speed = mean(sqrt(sum((xyspeed .* xyspeed),2)));
                end
                
                % Check to see if the movement has been completed (excluding home position)
                % OR if a mouse button has been pressed
                if ~inTheZone && (speed < speedThreshold || (~usingWacom && any(buttons)))
                    if krigolsonLab
                        sendmarker(responseMarker);
                    else
                        % TODO: send responseMarker
                    end
                    movementTime = GetSecs() - startTime;
                    clickedMouse = any(buttons);
                    guesses(trialCounter,:) = [mapX, mapY];
                    break;
                end
                
                % Check for exit key
                [~, ~, keyCode] = KbCheck();
                if keyCode(ExitKey)
                    ME = MException('goldrush2:escapekeypressed','Exiting script');
                    throw(ME);
                end
            end
            
            % Record movement data
            if ~stillPracticing
                allMovementData{blockCounter,trialCounter} = movementData;
            end
            
            %% Fixation (Pre-Feedback)
            
            % Display map and previous dig locations during testing and practice
            if justTesting || stillPracticing
                [i,j,v] = find(thisPMap >= 0);
                thisMap64 = ceil(thisPMap(:)'*64);
                thisMap64(thisMap64==0) = 1; % Ensure that we have pos index
                thisMap64(thisMap64>64) = 64; % Ensure that we don't go beyond 64
                thisColourMap = defaultColourMap(thisMap64,:)';
                thisMapXY = [xOffset + j';yOffset + maxY - i' + 1];
                Screen('DrawDots',win,thisMapXY,dotSize,ceil(255*thisColourMap));
                if justTesting
                    Screen(win,'TextFont','Courier');
                    Screen(win,'TextSize',12);
                    DrawFormattedText(win,['\nraw position: ' num2str([rawX rawY]) '\nmap position: ' num2str([mapX, mapY]) '\nthisBlockReward: ' num2str(thisBlockReward) ],[],[],textColour);
                end
            end
            
            % Map boundaries
            Screen('FrameRect',win,mapOutlineColour,mapOutlineRect);
            
            % Home Zone
            Screen('FillRect',win,homeColour,homeRect);
            Screen('FrameRect',win,homeOutline,homeRect);
            
            % Previous choices
            rectXs = xOffset + guesses(:,1);
            rectYs = yOffset + mapSize(1) - guesses(:,2);
            theRects = [rectXs-markerSize rectYs-markerSize rectXs + markerSize rectYs + markerSize];
            Screen('FillRect',win,markerColour,theRects');
            if krigolsonLab
                flipandmark(win,preFeedbackMarker);
            else
                Screen('Flip',win);
                % TODO: send preFeedbackMarker
            end
            
            %% Feedback
            
            % Retrieve all probabilities that are within digRadius of this dig location
            allPs = [];
            for yi = mapY-digRadius:mapY+digRadius
                for xi = mapX-digRadius:mapX+digRadius
                    % Check if xi, yi are within the thisMap
                    if yi > 0 && xi > 0 && yi <= mapSize(1) && xi <= mapSize(2)
                        % if xi, yi are within the dig radius, include their probability
                        if sqrt((yi-mapY)^2 + (xi-mapX)^2) <= digRadius
                            allPs = [allPs thisPMap(yi,xi)];
                            temp(yi,xi) = thisPMap(yi,xi);
                        end
                    end
                end
            end
            
            if useMeanP
                thisP = mean(allPs); % Mean within digRadius of dig location
            else
                thisP = thisPMap(mapY,mapX); % Point probability at dig location
            end
            
            % Determine outcome (1 = win, 0 = loss)
            if rand < thisP
                thisTrialReward = 1;
            else
                thisTrialReward = 0;
            end
            
            if ~stillPracticing
                thisBlockReward = thisBlockReward + thisTrialReward;
            end
            
             % Display map and previous dig locations during testing and practice
            if justTesting || stillPracticing
                [i,j,~] = find(thisPMap >= 0);
                thisMap64 = ceil(thisPMap(:)'*64);
                thisMap64(thisMap64==0) = 1; % Ensure that we have pos index
                thisMap64(thisMap64>64) = 64; % Ensure that we don't go beyond 64
                thisColourMap = defaultColourMap(thisMap64,:)';
                thisMapXY = [xOffset + j';yOffset + maxY - i' + 1];
                Screen('DrawDots',win,thisMapXY,dotSize,ceil(255*thisColourMap));                
                if justTesting
                    Screen(win,'TextFont','Courier');
                    Screen(win,'TextSize',12); 
                    DrawFormattedText(win,['\nraw position: ' num2str([rawX rawY]) '\nmap position: ' num2str([mapX, mapY]) '\nthisBlockReward: ' num2str(thisBlockReward) '\nthisP = ' num2str(thisPMap(mapY,mapX)) '\nmeanP = ' num2str(mean(allPs))],[],[],textColour);
                end
            end
            
            % Map boundaries
            Screen('FrameRect',win,mapOutlineColour,mapOutlineRect);
            
            % Home Zone
            Screen('FillRect',win,homeColour,homeRect);
            Screen('FrameRect',win,homeOutline,homeRect);
            
            % Previous dig sites
            rectXs = xOffset + guesses(:,1);
            rectYs = yOffset + mapSize(1) - guesses(:,2);
            theRects = [rectXs-markerSize rectYs-markerSize rectXs + markerSize rectYs + markerSize];
            Screen('FillRect',win,markerColour,theRects');
            
            % Do not proceed until cursor is in home position
            [currentX, currentY, ~] = GetMouse;
            inTheZone = currentX > homeRect(1) && currentX < homeRect(3) && currentY > homeRect(2) && currentY < homeRect(4);
            while ~inTheZone
                [currentX, currentY, ~] = GetMouse;
                inTheZone = currentX > homeRect(1) && currentX < homeRect(3) && currentY > homeRect(2) && currentY < homeRect(4);
            end
            
            % Hide cursor prior to feedback
            HideCursor();
            
            % Fixation
            fix_time = rand*0.4+0.6;
            WaitSecs(fix_time);
            
            % Display map and previous dig locations during testing and practice
            if justTesting || stillPracticing
                [i,j,~] = find(thisPMap >= 0);
                thisMap64 = ceil(thisPMap(:)'*64);
                thisMap64(thisMap64==0) = 1; % Ensure that we have pos index
                thisMap64(thisMap64>64) = 64; % Ensure that we don't go beyond 64
                thisColourMap = defaultColourMap(thisMap64,:)';
                thisMapXY = [xOffset + j';yOffset + maxY - i' + 1];
                Screen('DrawDots',win,thisMapXY,dotSize,ceil(255*thisColourMap));
                if justTesting
                    Screen(win,'TextFont','Courier');
                    Screen(win,'TextSize',12);  
                    DrawFormattedText(win,['\nraw position: ' num2str([rawX rawY]) '\nmap position: ' num2str([mapX, mapY]) '\nthisBlockReward: ' num2str(thisBlockReward) '\nthisP = ' num2str(thisPMap(mapY,mapX)) '\nmeanP = ' num2str(mean(allPs))],[],[],textColour);
                end
            end
            
            % Map boundaries
            Screen('FrameRect',win,mapOutlineColour,mapOutlineRect);
            
            % Home zone
            Screen('FillRect',win,homeColour,homeRect);
            Screen('FrameRect',win,homeOutline,homeRect);
            
            % Previous dig locations
            rectXs = xOffset + guesses(:,1);
            rectYs = yOffset + mapSize(1) - guesses(:,2);
            theRects = [rectXs-markerSize rectYs-markerSize rectXs + markerSize rectYs + markerSize];
            Screen('FillRect',win,markerColour,theRects');
            
            % Feedback for 1000 ms
            if thisTrialReward
                Screen('DrawTexture', win, win_texture, [], feedback_rect(1,:));
                if krigolsonLab
                    flipandmark(win,winMarker);
                else
                    Screen('Flip',win);
                    % TODO: send winMarker
                end
            else
                Screen('DrawTexture', win, loss_texture, [], feedback_rect(2,:));
                if krigolsonLab
                    flipandmark(win,loseMarker);
                else
                    Screen('Flip',win);
                    % TODO: send loseMarker
                end
            end
            WaitSecs(1);
            
            % Show cursor
            ShowCursor();
            
            %% Trial End
            
            % Save movement and trial data
            if ~stillPracticing
                save(movementFilename,'allMovementData','isSparse');
                this_data_line = [str2num(participantNum) blockCounter-nPracticeBlocks trialCounter isSparse(blockCounter) mapIndex lastABlockPerformance lastSBlockPerformance aBlockExp sBlockExp rawX rawY mapX mapY movementTime clickedMouse thisTrialReward];
                dlmwrite(trialDataFilename,this_data_line,'delimiter', '\t', '-append');
                trialData = [trialData; this_data_line]; % Not necessary, just an extra copy of the data
            end
            
            % Modify thisMap for next trial (for trial-to-trial adjustments)
            mapChange = makecircle([maxY maxX],guesses(end,1),guesses(end,2),digRadius);
            thisPMap = thisPMap - digAmount*mapChange;
            thisPMap(thisPMap < 0) = 0; % Lower probability bound
            
            if ~stillPracticing && trialCounter == numTrials
                if isSparse(blockCounter)
                    lastSBlockPerformance = thisBlockReward/numTrials;
                else
                    lastABlockPerformance = thisBlockReward/numTrials;
                end
            end
            
            [~, ~, keyCode] = KbCheck();
            if keyCode(ExitKey)
                ME = MException('goldrush2:escapekeypressed','Exiting script');
                throw(ME);
            end
        end
        
        %% End of Block
        
        if showMapAtEnd || stillPracticing
            [i,j,~] = find(thisPMap >= 0);
            thisMap64 = ceil(thisPMap(:)'*64);
            thisMap64(thisMap64==0) = 1; % Ensure that we have pos index
            thisMap64(thisMap64>64) = 64; % Ensure that we don't go beyond 64
            thisColourMap = defaultColourMap(thisMap64,:)';
            thisMapXY = [xOffset + j';yOffset + maxY - i' + 1];
            
            % Draw map
            Screen('DrawDots',win,thisMapXY,dotSize,ceil(255*thisColourMap));
            
            % Display testing information
            if justTesting
                Screen(win,'TextFont','Courier');
                Screen(win,'TextSize',12);
                DrawFormattedText(win,['raw position: ' num2str([rawX rawY]) '\nmap position: ' num2str([mapX, mapY]) '\nthisP = ' num2str(thisPMap(mapY,mapX)) '\nmeanP = ' num2str(mean(allPs)) '\nthisBlockReward: ' num2str(thisBlockReward)],[],[],textColour);
            end
            
            % Home Zone
            Screen('FillRect',win,homeColour,homeRect);
            Screen('FrameRect',win,homeOutline,homeRect);
            
            % End of block message
            Screen(win,'TextFont','Arial');
            Screen(win,'TextSize',24);
            DrawFormattedText(win,'(end of round - press any key to proceed)','center','center');
            Screen('Flip',win);
            
            % Wait for key press
            KbReleaseWait();
            KbPressWait();
        end
        
        if ~stillPracticing && thisBlockReward > best_block
            best_block = thisBlockReward;
        end
        
        % End of block message
        if stillPracticing
            if blockCounter == nPracticeBlocks
                blockMessage = '(end of practice - press any key to begin experiment)';
            else
                blockMessage = '(press any key to continue practicing)';
            end
        else
            blockMessage = ['rest break - you have completed ' num2str(blockCounter-nPracticeBlocks) ' of ' num2str(nExperimentBlocks) ' blocks\n' ...
                'this block you found: ' num2str(thisBlockReward) ' gold\n' ...
                'best block: ' num2str(best_block) ' gold\n' ...
                '(press any key to continue)'];
        end
        Screen(win,'TextFont','Arial');
        Screen(win,'TextSize',24);
        DrawFormattedText(win,blockMessage,'center','center');
        Screen('Flip',win);
        KbReleaseWait();
        KbPressWait();
        
    end
    
    %% End of Experiment
    
    Screen(win,'TextFont','Arial');
    Screen(win,'TextSize',24);
    DrawFormattedText(win,'end of experiment - thank you','center','center',textColour);
    Screen('Flip',win);
    WaitSecs(2);
        
    % Close the Psychtoolbox window and bring back the cursor and keyboard
    Screen('CloseAll');
    ListenChar(1);
    
catch e
    Screen('CloseAll');
    ListenChar(1);
    rethrow(e);
end