% boxCoverage.m
% Calculate the amount of the box the rat has covered

% input:
% boxType: 1, box;
%          2, round;
%          3, annular;
%          4, linear;

% v2.0: Oct., 2023.
% Add the limits of box and correct the code.
% And it could be better.

% Modified by Xiang Zhang, 2021.

function [coverage, coverageMap] = boxCoverage(posx, posy, binWidth, boxType, radiusRange, boxLimits)
    if nargin < 3, error('Inputs are not satisfied.'); end
    if nargin < 4, boxType = 1; radiusRange = []; boxLimits = []; end
    if nargin < 5, radiusRange = []; boxLimits = []; end
    if nargin < 6, boxLimits = []; end
    
    if boxType ~= 1 && isempty(radiusRange), error('Please check the input of ''radiusRange'''); end
    if boxType == 4, posy = ones(length(posx),1); end
    
    if isempty(boxLimits)
        minX = nanmin(posx); maxX = nanmax(posx);
        minY = nanmin(posy); maxY = nanmax(posy);
    else
        if boxType == 4
            minX = boxLimits(1); maxX = boxLimits(2);
            minY = nanmin(posy); maxY = nanmax(posy);
        else
            minX = boxLimits(1); maxX = boxLimits(2);
            minY = boxLimits(3); maxY = boxLimits(4);
        end
    end
    
    % Side lengths of the box
    xLength = maxX - minX;
    yLength = maxY - minY;
    
    % Number of bins in each direction
    colBins = ceil(xLength/binWidth);
    rowBins = ceil(yLength/binWidth);
    if colBins == 0, colBins = 1; end
    if rowBins == 0, rowBins = 1; end
    
    % Allocate memory for the coverage map
    coverageMap = zeros(rowBins, colBins);
    colAxis = zeros(colBins,1);
    rowAxis = zeros(rowBins,1);
    
    % Find start values that centre the map over the path
    xMapSize = colBins * binWidth;
    yMapSize = rowBins * binWidth;
    xOff = xMapSize - xLength;
    yOff = yMapSize - yLength;
    
    xStart = minX - xOff / 2;
    xStop = xStart + binWidth;
    
    for c = 1:colBins
        colAxis(c) = (xStart + xStop) / 2;
        ind = find(posx >= xStart & posx < xStop);
        yStart = minY - yOff / 2;
        yStop = yStart + binWidth;
        for r = 1:rowBins
            rowAxis(r) = (yStart + yStop) / 2;
            coverageMap(r,c) = length(find(posy(ind) > yStart & posy(ind) < yStop));
            yStart = yStart + binWidth;
            yStop = yStop + binWidth;
        end
        xStart = xStart + binWidth;
        xStop = xStop + binWidth;
    end
    
    switch boxType
        case 1
            coverage = length(find(coverageMap > 0)) / (colBins*rowBins) * 100;
        case 2
            fullMap = zeros(rowBins, colBins);
            for r = 1:rowBins
                for c = 1:colBins
                    dist = sqrt((colAxis(c) - (colAxis(1) + colAxis(end)) / 2)^2 + ...
                        (rowAxis(r) - (rowAxis(1) + rowAxis(end)) / 2)^2);
                    if dist > radiusRange
                        fullMap(r, c) = NaN;
                        coverageMap(r, c) = NaN;
                    end
                end
            end
            numBins = sum(sum(isfinite(fullMap)));
            coverage = (length(find(coverageMap > 0)) / numBins) * 100;
        case 3
            fullMap = zeros(rowBins, colBins);
            for r = 1:rowBins
                for c = 1:colBins
                    dist = sqrt((colAxis(c) - (colAxis(1) + colAxis(end)) / 2)^2 + ...
                        (rowAxis(r) - (rowAxis(1) + rowAxis(end)) / 2)^2);
                    if dist > radiusRange(2) || dist < radiusRange(1)
                        fullMap(r, c) = NaN;
                        coverageMap(r, c) = NaN;
                    end
                end
            end
            numBins = sum(sum(isfinite(fullMap)));
            coverage = (length(find(coverageMap > 0)) / numBins) * 100;
        case 4
            coverage = length(find(coverageMap > 0)) / (radiusRange / binWidth) * 100;
    end
end