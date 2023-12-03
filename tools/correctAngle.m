%% correctAngle.m
% This code is used to correct the angles of recording, which has been used
% in the DLC position data.
%
% Input:
%       angle_origial: the original data;
% Output:
%       angle_corrected: the corrected angle data;
%       angle_corrected2: the smoothed angle data of 'angle_corrected';
%
% Created by Xiang Zhang, 2021.

function [angle_corrected, angle_corrected2] = correctAngle(angle_origial)
    angle_corrected = angle_origial;
    
    % remove too fast rotation;
    LEDRotation = zeros(length(angle_corrected),1);
    for i = 2:length(angle_corrected)
        LEDRotation(i) = angleDiffer(angle_corrected(i), angle_corrected(i-1), 'deg');
    end
    plot(LEDRotation);
    headRotation_threshold = input('Enter a threshold for head direction rotation speed: ');
    close();
    if isempty(headRotation_threshold)
        headRotation_threshold = 80;
    end
    angle_corrected(LEDRotation > headRotation_threshold) = NaN;
    
    % remove wrong angles between nan values;
    ind = find(isnan(angle_corrected));
    ind2 = find(~isnan(angle_corrected));
    corredtedAngle1 = angle_corrected;
    corredtedAngle2 = angleSmooth(angle_corrected, 'deg', 'movmean', 5, 0);
    for ind_i = 1:length(ind) % fix small gaps (nan);
        previousNotNaN = ind2(find(ind2 < ind(ind_i), 1, 'last'));
        nextNotNaN = ind2(find(ind2 > ind(ind_i), 1));
        if isempty(previousNotNaN) || isempty(nextNotNaN) || ...
            previousNotNaN < 3 || nextNotNaN > size(angle_origial,1) - 2
            continue;
        end
        if nextNotNaN - previousNotNaN <= 5
            angleDifference = angleDiffer(angle_corrected(previousNotNaN), angle_corrected(nextNotNaN), 'deg');
            if angleDifference < headRotation_threshold
                corredtedAngle1(ind(ind_i)) = corredtedAngle2(ind(ind_i));
            end
        end
    end
    
    % delete a list of angles;
    ind = find(isnan(corredtedAngle1));
    ind2 = find(~isnan(corredtedAngle1));
    for ind_i = 1:length(ind) - 1
        if ind(ind_i) ~= 1 && ind(ind_i+1) - ind(ind_i) <= 30 && ind(ind_i+1) - ind(ind_i) > 1
            previousNotNaN = ind2(find(ind2 < ind(ind_i), 1, 'last'));
            nextNotNaN = ind2(find(ind2 > ind(ind_i), 1));
            if isempty(previousNotNaN) || isempty(nextNotNaN)
                continue;
            end
            if nextNotNaN - previousNotNaN <= headRotation_threshold / 2
                angleDifference = angleDiffer(angle_corrected(previousNotNaN), angle_corrected(nextNotNaN), 'deg');
                if angleDifference > headRotation_threshold
                    angle_corrected(ind(ind_i):ind(ind_i+1),:) = nan;
                    ind_i = ind_i+1; %#ok<FXSET>
                end
            end
        end
    end
    ind_all = sum(isnan(angle_corrected));
    
    % mean filter;
    disp(['The angles has ',num2str(ind_all),' nan values']);
    angle_corrected2 = angleSmooth(angle_corrected, 'deg', 'movmean', 15, 0);
    polarplot(angle_corrected2 * pi / 180,1:length(angle_corrected2));
    pause;
    close();
end