function frames = makeHyperspace( opts )

%MAKEHYPERSPACE Generate a looping "hyperspace" starfield animation.
%
%   FRAMES = MAKEHYPERSPACE creates a sequence of RGB image frames that
%   depict a radial starfield (hyperspace) animation. The returned array
%   FRAMES is of size [Height x Width x 3 x NumFrames] of class uint8.
%
%   FRAMES = MAKEHYPERSPACE(OPT) allows customization using name-value
%   options specified in the structure OPT or as a arguments block input.
%   Available options (and defaults) are:
%       File       - (string) Output filename. Supported extensions:
%                    ".gif" to write an animated GIF, ".mat" to save the
%                    frames variable, or "" (default) to display the
%                    animation when no output is requested.
%                    Default: ""
%       Size       - (1x2 double) [Height Width] of output frames in
%                    pixels. Both values must be positive integers.
%                    Default: [480 640]
%       Frames     - (double) Number of frames in the looped animation.
%                    Must be a positive integer.
%                    Default: 30
%       FrameRate  - (double) Playback frame rate (frames per second).
%                    Must be a positive integer. Used when writing GIF
%                    or displaying animation.
%                    Default: 20
%       Lines      - (double) Number of radial star lines to draw.
%                    Must be a positive integer.
%                    Default: 1080
%       Length     - (double) Normalized radial length of each star line
%                    in the range (0,1]. Determines how long each streak
%                    is relative to the radius.
%                    Default: 0.4
%       Width      - (double) Maximum line width (in pixels) for outer
%                    streaks. Inner streaks are thinner.
%                    Default: 3
%       Color      - (1x3 double) RGB triplet with values in [0 1] that
%                    defines the base color of the star lines.
%                    Default: [0.5 1 1]
%       Intensity  - (double) Exponent controlling brightness falloff
%                    toward the center. 1 yields linear scaling.
%                    Default: 1.3
%
%   Examples:
%       >> makeHyperspace( File="hyperspace.mat", Intensity=2.5 );
%       >> makeHyperspace( File="hyperspace.gif" ); 
%
%   Requires Computer Vision Toolbox (insertShape)

arguments
    opts.File (1,1) string = ""
    opts.Size (1,2) double {mustBePositive,mustBeInteger} = [480 640]
    opts.Frames (1,1) double {mustBePositive,mustBeInteger} = 30
    opts.FrameRate (1,1) double {mustBePositive,mustBeInteger} = 20
    opts.Lines (1,1) double {mustBePositive,mustBeInteger} = 1080
    opts.Length (1,1) double {mustBeBetween(opts.Length,0,1,"open")} = 0.4
    opts.Width (1,1) double {mustBePositive} = 3 % max line width
    opts.Color (1,3) double {mustBeBetween(opts.Color,0,1)} = [0.5 1 1]
    opts.Intensity (1,1) double = 1.3 % 1 -> linear change with radius
end

% Extract parameters
m = opts.Lines;    % number of star lines
n = opts.Frames;   % number of frames
h = opts.Size(1);  % frame height
w = opts.Size(2);  % frame width

% Determine square side (s = 2*r) such that hyperspace radius (r) 
% fills the requested frame size ([h w]) when cropped out
s = 2*ceil( sqrt( (w/2)^2 + (h/2)^2 ) );
rect = [(s-w)/2, (s-h)/2, w, h]; % cropping rectangle

% Generate random angular locations and starting radius for each star line
angs = 360*rand(m,1) - 180;  % [-180 180]
r0 = rand(m,1);  % normalized [0 1]

% Compute center of star field lines (c) and precompute (u,v) 
% components to convert from polar coordinates to pixel coordinates
c = (s + 1)/2;
u = (s/2)*cosd( angs );
v = (s/2)*sind( angs );

frames = zeros( h, w, 3, n, "uint8" ); % initialize frames
[~,~,ext] = fileparts( opts.File );
for k = 1:n
    % Use "mod" of radii to create a seamless loop
    r1 = mod( r0 + (k-1)/n, 1.0 );     % radius at start of star line
    r2 = min( 1.0, r1 + opts.Length ); % radius at end of star line

    % Convert from polar (radius/angle) to pixel (x/y) coordinates
    points = c + [r1.*u, r1.*v, r2.*u, r2.*v]; % [x1,y1,x2,y2]

    % Set line width and line color to be thinner/darker 
    % near the center and thicker/brighter at the edges
    lineWidth = ceil( opts.Width*r2 );
    lineColor = (r1.^opts.Intensity)*opts.Color;

    % Loop on unique widths since insertShape only accepts scalar LineWidth
    widths = unique( lineWidth );
    frame = zeros(s,s,3,"uint8");
    for j = 1:numel(widths)
        idx = (lineWidth == widths(j));
        frame = insertShape( frame, "line", points(idx,:), ...
            LineWidth=widths(j), ShapeColor=lineColor(idx,:) );
    end

    % Crop requested size out of circular hyperspace
    % (imcrop can be off by a pixel, so resize to ensure proper size)
    frames(:,:,:,k) = imresize( imcrop( frame, rect ), [h w] );

    if (ext == ".gif")
        % Create .gif file
        [img,map] = rgb2ind( frames(:,:,:,k), 256 );
        if (k == 1)
            delayTime = 1/opts.FrameRate;
            imwrite( img, map, opts.File, "gif", LoopCount=Inf, DelayTime=delayTime );
        else
            imwrite( img, map, opts.File, "gif", WriteMode="append", DelayTime=delayTime );
        end
    end
end

if (ext == ".mat")
    % Save .mat file
    save( opts.File, "frames" )

elseif ((ext == "") && (nargout == 0))
    % Display looping frames until figure is closed
    fig = figure;
    k = 1;
    hImage = imshow( frames(:,:,:,k) );
    disableDefaultInteractivity( hImage.Parent )
    hImage.Parent.Toolbar.Visible = "off";
    delayTime = 1/opts.FrameRate;
    while isvalid( fig )
        k = k + 1;
        if (k > n)
            k = 1;
        end
        hImage.CData = frames(:,:,:,k);
        pause( delayTime )
    end
end

end