%% ms = msGenerateVideoObj_TwoPhoton(dir_name)
% This code is used to generate the basic information of videos.
% This version is used for two photon data.

% Created by Xiang Zhang, 2022.

function ms = msGenerateVideoObj_TwoPhoton(dir_name)
    videoFiles = dir([dir_name filesep 'CH*.avi']);
    
    ms.dirName = dir_name;
    ms.numFiles = 0;
    ms.numFrames = 0;
    ms.vidNum = [];
    ms.frameNum = [];
    ms.maxFramesPerFile = 0;
    
    ms.numFiles = length(videoFiles);
    
    for i = 1:ms.numFiles
        ms.vidName{i} = videoFiles(i).name;
        ms.vidObj{i} = VideoReader([dir_name filesep videoFiles(i).name]); %#ok<TNMLP>
        ms.vidNum = [ms.vidNum i*ones(1,ms.vidObj{i}.NumberOfFrames)];
        ms.frameNum = [ms.frameNum 1:ms.vidObj{i}.NumberOfFrames];
        
        ms.numFrames = ms.numFrames + ms.vidObj{i}.NumberOfFrames;
        ms.maxFramesPerFile = max(ms.maxFramesPerFile, ms.vidObj{i}.NumberOfFrames);
    end
    
    ms.height = ms.vidObj{1}.Height;
    ms.width = ms.vidObj{1}.Width;
    
    % time;
    sIdx = strfind(dir_name, filesep);
    timestamp_file = [dir_name(1:sIdx(end)-1), '\MiceVideo_Info.tdms'];
    ConvertedData = convertTDMS(0, timestamp_file);
    timestamps = ConvertedData.Data.MeasuredData(4).Data;
    
    t = datetime(timestamps, 'InputFormat','yyyy-MM-dd HH-mm-ss.SSS');
    ms.timestamps = t;
    ms.time = seconds(t - t(1));
end

