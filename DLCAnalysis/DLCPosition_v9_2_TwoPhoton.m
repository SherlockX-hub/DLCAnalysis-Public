%% DLCPosition_v9_TwoPhoton.m;
% V4 veision: create behav.mat if it is not exist; modify the calculaion
% method of speed; modify the filter method of median filter; delete the
% csv output.

% V5 version can select threshold of behavior speed; modified the filter
% method.

% V6 version is created to collecting position data from DLC, the data has
% the information of RED and Green LED, it adds the function to correct the
% head direction.The head direction is from RED to GREEN.
% Add box coverage function.

% 'QT' version modified the way that approach position data file.
% 'FFMPEG' version adds the way that read videos through FFMPEG.

% V7 version: load preexist %behav.mat and DLCposition.mat other than create
% them de novo. Show LED in jet_r color, and one should draw direction in
% jet direction. Add smoothing LED direction part. Change the method of
% speed calculation.
% change the method of drawing roi; show the hdDir plot; change the
% Ledrotation threshold to 60. % 80

% V8 version: Use function correctPosition.m and correctAngle.m.
% DLC version.
% Add annular arena. All are two dimensions.
% Change the annular position smooth method.
% This version is used for DLC data from two photon recording.
% NOT SURE IT IS COMPLETED.

% V9 version: updates.
% Choose points to analyze.
% If head direction calculation is needed, you should choose two points for
% one animal, single point can't calculate the head direction. The first
% point will represent the position of the animal.
% If head direction calculation is not needed, one point for one animal is
% enough.
% Save both smoothed and unsmoothed position data and angle data.
% Improvements.
% Separate head direction calulation and correction into two choice.
% Set alpha value to trajectory in 'ROI' sessioin.
% V9_2 version: add projective transformation of position.

% Created by Xiang Zhang, 2020.

clear;

%% code path;
% addpath();

%% parameters;
dir_name = 'G:\ZX\Data_temp\40-20221204-1\MiceVideo2\MiceVideo'; %pwd; % input('Enter the path of data: ', 's');
% 'I:\YYR\SampleData\Paired_Calcium2Channels_BehavVideo\56 ActiveTestInHC\MiceVideo2\MiceVideo';
sInd = strfind(dir_name, filesep);
session_name = dir_name(1:sInd(end-1)-1);

% cd(dir_name);
disp(['Start session: ',session_name]);

%% creat behav file;
if exist([dir_name filesep 'behav.mat'],'file')
    load([dir_name filesep 'behav.mat']);
else
    behav = msGenerateVideoObj_TwoPhoton(dir_name);
end

%% collect all csv files;
csvFiles = dir([dir_name filesep '*filtered.csv']);
if isempty(csvFiles)
    try
        load([dir_name filesep 'DLCposition.mat']);
        disp('Loading DLC data...');
    catch
        error('It seems that no DeepLabCut data in this folder.');
    end
else
    DLCposition = [];
    
    for i = 1:length(behav.vidName)
        [~, file_name_temp] = fileparts(behav.vidName{i});
        csvFiles = dir([behav.dirName, filesep, file_name_temp, '*filtered.csv']);
        if length(csvFiles) > 1
            DLC_pos_temp = [];
            for csv_i = 1:length(csvFiles)
                csvFiles_temp = dir([behav.dirName, filesep, file_name_temp, '*mouse', num2str(csv_i), '*filtered.csv']);
                if isempty(csvFiles_temp), error('Files are not found, please check the name of DLC files.'); end
                DLC_pos_temp_temp = xlsread([dir_name filesep csvFiles_temp(1).name]);
                if csv_i > 1, DLC_pos_temp = [DLC_pos_temp, DLC_pos_temp_temp(:,2:end)]; %#ok<AGROW>
                elseif csv_i == 1, DLC_pos_temp = DLC_pos_temp_temp; end
            end
        else
            csvFiles_temp = dir([behav.dirName, filesep, file_name_temp, '*filtered.csv']);
            DLC_pos_temp = xlsread([dir_name filesep csvFiles_temp(1).name]);
        end
        DLCposition = [DLCposition; DLC_pos_temp]; %#ok<AGROW>
    end
    
    save([dir_name filesep 'DLCposition.mat'], 'DLCposition');
    disp('Original position data is collected and saved.');
end

%% select DLC labels;
frameIdx = round(behav.numFrames/2);
vidNum = behav.vidNum(frameIdx);
vidFrameNum = behav.frameNum(frameIdx);
frame = behav.vidObj{vidNum}.read(vidFrameNum);

DLC_part_num = floor(size(DLCposition,2)/3);
imshow(frame,'InitialMagnification','fit');
hold on;
scatter(DLCposition(frameIdx, 2:3:size(DLCposition,2)), ...
    DLCposition(frameIdx, 3:3:size(DLCposition,2)), [], 1:DLC_part_num, 'filled');
text(DLCposition(frameIdx, 2:3:size(DLCposition,2)), ...
    DLCposition(frameIdx, 3:3:size(DLCposition,2)), string(1:DLC_part_num), 'Color','w');
colormap jet;
colorbar;
DLC_part = input('Enter the number of body part you want to choose (i.e. [2,1,3], details in V9 description): ');
if isempty(DLC_part), DLC_part = 1:DLC_part_num; end
close();

%% projective transformation;
behav.trackLength = input('Enter the size (length or diameter) of experimental area: ');
if length(behav.trackLength) == 1, behav.trackLength = [behav.trackLength behav.trackLength]; end

plot_i = 1;
position_plot = {};
for m = 2:3:size(DLCposition,2)
    position_plot{plot_i,1} = DLCposition(:,m:m+1); %#ok<SAGROW>
    plot_i = plot_i+1;
end
ptformer = projectiveTransformer(frame, behav.trackLength, 'position_plot',position_plot);
for m = 2:3:size(DLCposition,2)
    DLCposition(:,m:m+1) = ptformer.applyTransformer(DLCposition(:,m:m+1));
end
behav.ptformer = ptformer;

%% ROI;
behav.ROI = [0 0 behav.trackLength(1) behav.trackLength(2)];

%% correct LED direction;
LEDDir = input('Need calculate direction? (Y/N) ', 's');
LEDDir = strcmpi(LEDDir, 'Y');
if LEDDir
    dotNum = length(DLC_part);
    behav.correctionAngle = cell(floor(dotNum / 2),1);
    
    LEDDir_correct = input('Need correct LED direction? (Y/N) ', 's');
    LEDDir_correct = strcmpi(LEDDir_correct, 'Y');
    if ~LEDDir_correct
        for unit_i = 1:floor(dotNum / 2)
            behav.correctionAngle{unit_i,1} = 0;
        end
    else
        jet_color = flipud(jet);
        for unit_i = 1:floor(dotNum / 2)
            DLC_idx_1 = DLC_part(unit_i);
            DLC_idx_2 = DLC_part(unit_i + 1);
            frameIdx = 1;
            userInput = 'Y';
            while(strcmpi(userInput, 'Y'))
                frameIdx = frameIdx + 500;
                vidNum = behav.vidNum(frameIdx);
                vidFrameNum = behav.frameNum(frameIdx);
                frame = behav.vidObj{vidNum}.read(vidFrameNum);
                if size(frame,3) == 4, frame = frame(:,:,1:3); end
                
                imshow(frame,'InitialMagnification','fit');
                hold on;
                scatter(DLCposition(frameIdx,3*DLC_idx_1-1), DLCposition(frameIdx,3*DLC_idx_1), 100,jet_color(1,:),'filled');
                scatter(DLCposition(frameIdx,3*DLC_idx_2-1), DLCposition(frameIdx,3*DLC_idx_2), 100,jet_color(end,:),'filled');
                hold off;
                figure(1);
                userInput = upper(input('Need another frame? (Y/N) ','s'));
            end
            
            % draw lines;
            disp('Draw a line of LED (red to blue direction)');
            lineLED = drawline;
            pause;
            vectorLED = diff(lineLED.Position);
            
            disp('Draw a line of mouse direction');
            lineMouse = drawline;
            pause;
            vectorMouse = diff(lineMouse.Position);
            
            hold off;
            close();
            
            behav.correctionAngle{unit_i,1} = mod(atan2d(det([vectorLED;vectorMouse]),dot(vectorLED,vectorMouse)),360);
        end
    end
end

%% parameters;
behav.shape = input('Enter the shape of experimental area (1: box, 2: round, 3: annular): ');
switch behav.shape
    case 1
        behav.radiusRange = [];
    case 2
        behav.radiusRange = behav.trackLength / 2;
    case 3
        innerLength = input('Enter the diameter of the inner experimental area: ');
        behav.radiusRange = [innerLength / 2 behav.trackLength / 2];
end

% behav = rmfield(behav,'vidObj');
save([behav.dirName filesep 'behav.mat'],'behav');
disp('behav.mat is created.');

%% correct DLC position;
if behav.numFrames ~= size(DLCposition,1), error('Frames error, and analysis is not finished.'); end

disp('DLCposition file is saved and start correction.');

% position correction;
% DLCposition_corrected = DLCposition(:,[1, reshape([3*DLC_part-2, 3*DLC_part-1, 3*DLC_part],1,[])]);
DLCposition_corrected = DLCposition(:,[1, cell2mat(arrayfun(@(x) (3*x-1:3*x+1), DLC_part, 'UniformOutput',false))]);
DLCposition_corrected(:,1) = behav.time;

for m = 2:3:size(DLCposition_corrected,2)
    n = m+1;
    
    % position correction;
    DLCposition_corrected(:,m:n) = correctPosition(DLCposition_corrected(:, m:n), behav);
end

save([behav.dirName filesep 'DLCposition_corrected.mat'],'DLCposition_corrected');

if LEDDir
    % head direction correction;
    unitNum = ceil(length(DLC_part) / 2);
    for unit_i = 1:unitNum
        pos = DLCposition_corrected(:,6*unit_i-4:6*unit_i-3);
        behav.position{unit_i,1} = pos;
        behav.position_smooth{unit_i,1} = smoothdata(pos,'movmean',15,'omitnan');
        behav.speed{unit_i,1} = speed2D(pos(:,1), pos(:,2), behav.time);
        
        % coverage;
        behav.coverage{unit_i,1} = boxCoverage(pos(:,1), pos(:,2), 2, behav.shape, behav.radiusRange);
        
        % head direction calculation;
        if unit_i > floor(dotNum / 2), break; end
        hdDir = atan2(DLCposition(:, 3*DLC_part(2*unit_i)) - DLCposition(:, 3*DLC_part(2*unit_i-1)), ...
            DLCposition(:, 3*DLC_part(2*unit_i)-1) - DLCposition(:, 3*DLC_part(2*unit_i-1)-1));
        hdDir = mod(360 * hdDir / (2*pi) + behav.correctionAngle{unit_i}, 360);
        [behav.originalAngle{unit_i,1}, corredtedAngle] = deal(hdDir);
        
        % remove too long LED bar;
        LEDBar = vecnorm(DLCposition(:, 3*DLC_part(2*unit_i-1)-1 : 3*DLC_part(2*unit_i-1)) - ...
            DLCposition(:, 3*DLC_part(2*unit_i)-1 : 3*DLC_part(2*unit_i)), 2, 2);
        plot(LEDBar);
        LEDBar_threshold = input('Enter a threshold for LED bar length: ');
        close();
        if isempty(LEDBar_threshold), LEDBar_threshold = 30; end
        corredtedAngle(LEDBar > LEDBar_threshold) = NaN;
        
        behav.hdDir{unit_i,1} = correctAngle(corredtedAngle);
        behav.hdDir_smooth{unit_i,1} = angleSmooth(behav.hdDir{unit_i,1}, 'deg', 'movmean', 15, 0);
    end
else
    % just position;
    unitNum = length(DLC_part);
    for unit_i = 1:unitNum
        pos = DLCposition_corrected(:,3*unit_i-1:3*unit_i);
        behav.position{unit_i,1} = pos;
        behav.position_smooth{unit_i,1} = smoothdata(pos,'movmean',15,'omitnan');
        behav.speed{unit_i,1} = speed2D(pos(:,1), pos(:,2), behav.time);
        
        % coverage;
        behav.coverage{unit_i,1} = boxCoverage(pos(:,1), pos(:,2), 2, behav.shape, behav.radiusRange);
    end
end

%% save figures and files;
figure;
for fig_i = 1:length(behav.position)
    subplot(1, length(behav.position), fig_i);
    plot(behav.position{fig_i}(:,1), behav.position{fig_i}(:,2));
    axis equal;
    axis([0 behav.trackLength(1) 0 behav.trackLength(2)]);
end
saveas(gcf, [behav.dirName filesep 'behav_position.png']);
close all;

behav = rmfield(behav, 'vidObj');
save([behav.dirName filesep 'behav.mat'], 'behav');
save([session_name filesep 'behav.mat'], 'behav');

% collect files;
if ~isempty(csvFiles)
    currentFolder = pwd;
    cd(dir_name);
    moveFiles_dlc;
    cd(currentFolder);
end

fprintf('%s All data are corrected and saved.\n\n', dir_name);
