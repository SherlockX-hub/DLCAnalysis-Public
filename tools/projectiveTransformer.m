%% projectiveTransformer.m
% This code is used to apply projective transformation to position data.
%
% Input:
%        image_original: scene of positions;
%        trackLength: a 1*2 matrix, the true length of position [width,
%                     height];
%        position_original: a n*2 matrix, original position data;
%        (Options)
%        position_plot: a m*1 cell consists n*2 matrixs, positions to plot
%                       when choose ROI;
%
% Output:
%        position_transformed: a n*2 matrix, transformed position data;
%
% Usage:
%        ptformer = projectiveTransformer(image_original, trackLength);
%        position_transformed = ptformer.applyTransformer(position_original);
%
% Created by Xiang Zhang, April, 2023.

classdef projectiveTransformer < handle
    
    properties
        image_original
        position_plot
        movingPoints % another form of ROI;
        trackLength
        tform % transformation;
    end
    
    methods
        function obj = projectiveTransformer(image_original, trackLength, varargin)
            
            inp = inputParser;
            addRequired(inp,'image_original'); % , @ismatrix
            addRequired(inp, 'trackLength', @isvector);
            addParameter(inp, 'position_plot', {}, @iscell);

            parse(inp, image_original, trackLength, varargin{:});
            obj.image_original = image_original;
            obj.trackLength = trackLength;
            obj.position_plot = inp.Results.position_plot;
            
            obj.movingPoints = defineROI(obj);
            fixedPoints = [0 0; 1 0; 1 1; 0 1];
            obj.tform = fitgeotrans(obj.movingPoints, fixedPoints, 'projective');
        end
        
        function movingPoints = defineROI(obj)
            imshow(obj.image_original);
            % plot trajectory;
            if ~isempty(obj.position_plot)
                hold on;
                for plot_i = 1:length(obj.position_plot)
                    plot(obj.position_plot{plot_i}(:,1), obj.position_plot{plot_i}(:,2));
                end
            end
            
            % ROI;
            disp('Draw polygonal ROI (up-left, up-right, down-right, down-left).');
            roi = drawpolygon; pause;
            movingPoints = roi.Position;
            close();
        end
        
        function position_transformed = applyTransformer(obj, position_original)
            position_transformation = transformPointsForward(obj.tform, position_original);
            
            position_transformed = position_transformation .* ...
                repmat(obj.trackLength, size(position_transformation,1), 1);
        end
    end
    
end