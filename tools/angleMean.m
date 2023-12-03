%% angleMean.m
% This function is used to calculate the mean value of 'two' angles.

% Input:
%        a: must be a vector;
%
% Optional input:
%        angleType: 'deg', degree;
%                   'rad', radians (default);
%        nanFlag: 0, 'omitnan' (default);
%                 1, 'includenan';

% Created by Xiang Zhang, Sept., 2023.

function am = angleMean(a, angleType, nanFlag)
    
    % verify inputs;
    if ~isvector(a), error ('The input angles must be a vector.'); end
    % if length(a) ~= 2, error('This function can only calulate the mean value of two angles'); end
    a = reshape(a, [],1);
    
    if nargin < 2, angleType = 'rad'; nanFlag = 0; end
    if nargin < 3, nanFlag = 0; end
    
    % verify angles in degrees or radians;
    switch angleType
        case 'deg', a = deg2rad(a);
        % case 'rad', a = a;
    end
    
    % transform angles to vectors;
    a_complex = exp(1i * a);
    
    % calculate the mean angle in vectors;
    switch nanFlag
        case 0, a_vector_mean = nansum(a_complex) / numel(a_complex); % omitnan;
        case 1, a_vector_mean = sum(a_complex) / numel(a_complex); % includenan;
    end
    
    % transform vectors to angles;
    am = angle(a_vector_mean);
    
    switch angleType
        case 'deg', am = mod(rad2deg(am), 360);
        case 'rad', am = mod(am, 2*pi);
    end
end