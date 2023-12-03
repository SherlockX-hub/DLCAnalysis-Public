%% angleDiffer.m
% This function is used to calculate the absolute difference of two angles.

% Input: angleType: 'deg', degree;
%                   'rad', radians (default);

% Created by Xiang Zhang, 2021.

function ad = angleDiffer(a1, a2, angleType)
    if nargin < 3, angleType = 'rad'; end
    if isempty(angleType), angleType = 'rad'; end
    
    a1 = reshape(a1, [],1);
    a2 = reshape(a2, [],1);
    if length(a1) ~= length(a2), error('Input angles must have the same length.'); end
    
    switch angleType
        case 'rad'
            ad = min([abs(a1 - a2 - 2 * pi), ...
                abs(a1 - a2 + 2 * pi), ...
                abs(a1 - a2)], [], 2);
        case 'deg'
            ad = min([abs(a1 - a2 - 360), ...
                abs(a1 - a2 + 360), ...
                abs(a1 - a2)], [], 2);
    end
end