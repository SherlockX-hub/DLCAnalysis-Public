%% moveDLCFiles.m
% This code is used to move files generated from DeepLabCut to a single
% folder.

% Created by Xiang Zhang, April 2021.

if ~exist('trajectory', 'dir'), mkdir('trajectory'); end
currenttime =strcat(datestr(now,29),'_', num2str(hour(now)),'-',num2str(minute(now)),'-',num2str(floor(second(now))));
mkdir(strcat('trajectory\',currenttime));
behavCamFiles = dir('behavCam*');
csvFiles = dir('*.csv');
h5Files = dir('*.h5');
mp4Files = dir('*.mp4');
pickleFiles = dir('*.pickle');

for i = 1:length(csvFiles)  
    if csvFiles(i).name == "timeStamps.csv", continue; end
    movefile(csvFiles(i).name,strcat('trajectory\',currenttime,'\',csvFiles(i).name));
end

for i = 1:length(h5Files)
    movefile(h5Files(i).name,strcat('trajectory\',currenttime,'\',h5Files(i).name));
end

for i = 1:length(mp4Files)
    movefile(mp4Files(i).name,strcat('trajectory\',currenttime,'\',mp4Files(i).name));
end

for i = 1:length(pickleFiles)
    movefile(pickleFiles(i).name,strcat('trajectory\',currenttime,'\',pickleFiles(i).name));
end

if exist('plot-poses', 'dir'), movefile('plot-poses\',strcat('trajectory\',currenttime)); end
if exist('DLCposition.mat','file'), copyfile('DLCposition.mat',strcat('trajectory\',currenttime)); end
if exist('DLCposition_corrected.mat','file'), copyfile('DLCposition_corrected.mat\',strcat('trajectory\',currenttime)); end