%% angleSmooth.m
% This function is used to smooth a list of angles.

% Input:
%        a: must be a vector;
%
% Optional input:
%        angleType: 'deg', degree;
%                   'rad', radians (default);
%        smoothMethod: the method of function 'smoothdata', default is
%                      'movmean';
%        smoothWindow: the window of function 'smoothdata', default is 15;
%        nanFlag: 0, 'omitnan' (default);
%                 1, 'includenan';

% Created by Xiang Zhang, 2021.
%
% v2.0: Sept., 2023.
% Modifications.

function am = angleSmooth(a, angleType, smoothMethod, smoothWindow, nanFlag)
    
    % verify inputs;
    if length(a) < 5, error('The size of input angles is too small.'); end
    if ~isvector(a), error ('The input angles must be a vector.'); end
    a = reshape(a, [],1);
    
    if nargin < 2, angleType = 'rad'; smoothMethod = 'movmean'; smoothWindow = 15; nanFlag = 0; end
    if nargin < 3, smoothMethod = 'movmean'; smoothWindow = 15; nanFlag = 0; end
    if nargin < 4, smoothWindow = 15; nanFlag = 0; end
    if nargin < 5, nanFlag = 0; end
    
    % verify angles in degrees or radians;
    switch angleType
        case 'deg', a = deg2rad(a);
        % case 'rad', a = a;
    end
    
    % verify input of smooth;
    if isempty(smoothMethod), smoothMethod = 'movmean'; end
    if isempty(smoothWindow), smoothWindow = 15; end
    switch nanFlag
        case 0, nanFlag = 'omitnan';
        case 1, nanFlag = 'includenan';
    end
    
    % transform angles to vectors;
    a_vector = [cos(a), sin(a)];
    
    % smooth angles in vectors;
    a_vector_smooth = nan(size(a_vector));
    a_vector_smooth(:,1) = smoothdata(a_vector(:,1), smoothMethod, smoothWindow, nanFlag);
    a_vector_smooth(:,2) = smoothdata(a_vector(:,2), smoothMethod, smoothWindow, nanFlag);
    
    % transform vectors to angles;
    am = atan2(a_vector_smooth(:,2), a_vector_smooth(:,1));
    
    switch angleType
        case 'deg', am = mod(rad2deg(am), 360);
        case 'rad', am = mod(am, 2*pi);
    end
end