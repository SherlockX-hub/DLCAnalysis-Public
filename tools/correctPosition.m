%% correctPosition.m
% This code is used to correct the position of recording, which has been
% used in the DLC position data.
%
% Input:
%       pos_origial: the original data;
%       behav: the behav struct data;
% Output:
%       pos: the corrected position data;
%       pos2: the filtered position data of 'pos';
%       roi: the region of position;
%
% Created by Xiang Zhang, 2021.

function [pos, pos2, roi] = correctPosition(pos_original, behav)
    
    if size(pos_original,2) ~= 2
        error('Wrong input of position data.');
    end
    
    % roi;
    if ~isfield(behav, 'ROI')
        if isfield(behav, 'vidObj')
            frame = behav.vidObj{1}.read(1);
            if size(frame,3) == 4, frame = frame(:,:,1:3); end
            imshow(frame,'InitialMagnification','fit');
        end
        hold on;
        plot(pos_original(:,1),pos_original(:,2));
        hold off;
        axis equal;
        roi = drawrectangle;
        pause;
        roi = roi.Position;
        behav.ROI = roi;
        close();
    else
        roi = behav.ROI;
    end
    
    % position correction;
    if length(behav.trackLength) == 1, behav.trackLength = [behav.trackLength behav.trackLength]; end
    pos_original(:,1) = (pos_original(:,1) - behav.ROI(1)) / behav.ROI(3) * behav.trackLength(1);
    pos_original(:,2) = (pos_original(:,2) - behav.ROI(2)) / behav.ROI(4) * behav.trackLength(2);
    
    pos = pos_original;
    pos_center = [behav.trackLength(1) / 2, behav.trackLength(2) / 2];
    
    % remove the position out of boundary;
    for i = 1:size(pos,1)
        if pos(i,1) < -0.5 || pos(i,1) > behav.trackLength(1) + 0.5 || ...
                pos(i,2) < -0.5 || pos(i,2) > behav.trackLength(2) + 0.5 % boundary;
            pos(i,:) = NaN;
        end
        
        switch behav.shape
            case 2
                if norm(pos(i,:) - pos_center) > behav.trackLength(1) / 2 + 2.5 % circular boundary;
                    pos(i,:) = NaN;
                end
            case 3
                if norm(pos(i,:) - pos_center) < behav.radiusRange(1) || ...
                        norm(pos(i,:) - pos_center) > behav.radiusRange(2) % annular boundary;
                    pos(i,:) = NaN;
                end
        end
    end
    
    % remove too fast speed;
    figure;
    hold on;
    if ~isfield(behav, 'time')
        speed = speed2D(pos(:,1), pos(:,2), 1:size(pos,1));
    else
        speed = speed2D(pos(:,1), pos(:,2), behav.time);
    end
    plot(speed);
    
    threshold = input('Enter the threshold of speed threshold: ');
    if isempty(threshold)
        threshold = 0.1;
    end
    close all;
    pos((speed > threshold),:) = NaN;
    
    % remove wrong position between nan values;
    ind = find(isnan(pos(:,1)));
    ind2 = find(~isnan(pos(:,1)));
    pos1 = pos;
    for ind_i = 1:length(ind) % fix small gaps (nan);
        previousNotNaN = ind2(find(ind2 < ind(ind_i), 1, 'last'));
        nextNotNaN = ind2(find(ind2 > ind(ind_i), 1));
        if isempty(previousNotNaN) || isempty(nextNotNaN) || ...
                previousNotNaN < 3 || nextNotNaN > size(pos,1) - 2
            continue;
        end
        if nextNotNaN - previousNotNaN <= 5
            if abs(pos(previousNotNaN,1) - pos(nextNotNaN,1)) < 25 && ...
                    abs(pos(previousNotNaN,2) - pos(nextNotNaN,2)) < 25
                pos1(ind(ind_i),:) = nanmean(pos(ind(ind_i)-2: ind(ind_i)+2,:));
            end
        end
    end
    
    % delete a list of positions;
    ind = find(isnan(pos1(:,1)));
    ind2 = find(~isnan(pos1(:,1)));
    for ind_i = 1:length(ind) - 1
        if ind(ind_i) ~= 1 && ind(ind_i+1) - ind(ind_i) <= 30 && ind(ind_i+1) - ind(ind_i) > 1
            previousNotNaN = ind2(find(ind2 < ind(ind_i), 1, 'last'));
            nextNotNaN = ind2(find(ind2 > ind(ind_i+1), 1));
            if isempty(previousNotNaN) || isempty(nextNotNaN)
                continue;
            end
            if nextNotNaN - previousNotNaN <= 30
                if (abs(pos(previousNotNaN,1) - pos(ind(ind_i)+1,1)) > 25 || ...
                        abs(pos(previousNotNaN,2) - pos(ind(ind_i)+1,2)) > 25) && ...
                        (abs(pos(nextNotNaN,1) - pos(ind(ind_i+1)-1,1)) > 25 || ...
                        abs(pos(nextNotNaN,2) - pos(ind(ind_i+1)-1,2)) > 25)
                    pos(ind(ind_i):ind(ind_i+1),:) = nan;
                    ind_i = ind_i+1; %#ok<FXSET>
                end
            end
        end
    end
    ind_all = sum(isnan(pos(:,1)));
    
    % mean filter;
    if  behav.shape == 3 % annular;
        pos2 = smoothCircPos(pos, behav.trackLength(1));
        
        % set too fast point to nan;
        speed = speed2D(pos2(:,1), pos2(:,2), behav.time);
        pos2((speed > 0.7),:) = NaN;
    else
        pos2 = smoothdata(pos,'movmean',15,'omitnan');
    end
    
    plot(pos2(:,1),pos2(:,2));
    axis equal;
    
    disp(['The trajectory has ',num2str(ind_all),' nan values']);
    pause;
    close all;
end

%% functions;
function pos = smoothCircPos(pos, diameter)
    pos_distance = sqrt(sum((pos - diameter / 2).^2,2));
    pos_angle = atan2(pos(:,2) - diameter / 2, pos(:,1) - diameter / 2);
    
    pos_distance = smoothdata(pos_distance, 'movmean', 15, 'omitnan');
    pos_angle_rotation = zeros(length(pos_angle),1);
    for i = 2:length(pos_angle)
        pos_angle_rotation(i) = angleDiffer(pos_angle(i), pos_angle(i-1), 'rad');
    end
    LEDRotation_threshold = 30 * pi / 180;
    pos_angle(pos_angle_rotation > LEDRotation_threshold) = NaN;
    pos_angle = angleSmooth(pos_angle, 'rad', 'movmean', 15, 0);
    
    pos(:,1) = diameter / 2 + pos_distance .* cos(pos_angle);
    pos(:,2) = diameter / 2 + pos_distance .* sin(pos_angle);
end