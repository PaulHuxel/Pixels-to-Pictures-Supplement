function img = imeffects( img, effect )

%IMEFFECTS Apply visual effects to an RGB image.
%   IMG = IMEFFECTS(IMG, EFFECT) applies the specified EFFECT to the input
%   RGB image and returns the processed image.
%
%   Inputs
%     IMG    - M-by-N-by-3-by-K uint8 array containing one or more RGB
%              frames. For single-frame operation K can be 1. Most effects
%              operate only on the most recent frame (first frame along the
%              4th dimension), while some effects use multiple frames to
%              produce temporal effects.
%
%     EFFECT - String specifying the effect to apply. Valid values are:
%              "none"         - no effect
%              "barrel"       - barrel distortion
%              "blur"         - pixel-scale blur
%              "edge"         - edge map (binary edges)
%              "ghost"        - temporal ghosting from multiple frames
%              "gotham"       - mask + color adjustments (uses face detection)
%              "grayscale"    - convert to grayscale
%              "hologram"     - red/cyan stereoscopic effect using motion
%              "kaleidoscope" - mirrored kaleidoscope with 6 sectors
%              "negative"     - color negative (complement)
%              "neon"         - morphological edge/neon effect
%              "pencil"       - pencil sketch
%              "pincushion"   - pincushion distortion
%              "pixelate"     - blocky pixelation
%              "quantize"     - color quantization
%              "rc-pop"       - selective color pop in red/cyan hues
%              "wave"         - sinusoidal horizontal warp
%
%   Output
%     IMG - M-by-N-by-3 uint8 image containing the processed frame. 

arguments
    img (:,:,3,:) uint8 % RGB image(s)
    effect {mustBeMember(effect,["none","barrel","blur","edge","ghost", ...
        "gotham","grayscale","hologram","kaleidoscope","negative","neon", ...
        "pencil","pincushion","pixelate","quantize","rc-pop","wave"])}
end

persistent faceDetector mask
if isempty( faceDetector )
    faceDetector = vision.CascadeObjectDetector();
    mask = load("masks.mat","batman");
    mask = mask.batman;
end

% Except for "ghost" and "hologram", effects are only applied to the first frame.
frames = img;
img = frames(:,:,:,1); % newest frame

switch effect
    case "none"
        % do nothing

    case "barrel"
        img = imdistort( img, 4.8 );

    case "blur"
        scale = 0.1;
        img = imresize( imresize( img, scale ), 1/scale );

    case "edge"
        img = repmat( uint8( 255*edge( im2gray( img ) ) ), [1 1 3] );

    case "ghost"
        img = frames(:,:,:,end); % oldest frame, first background
        n = size( frames, 4 );
        for k = ((n-1):-1:1) % end with newest frame as final foreground
            img = imblend( frames(:,:,:,k), img, ForegroundOpacity=0.7 );
        end

    case "gotham"
        % Requires Computer Vision Toolbox (face detection)
        bbox = faceDetector( img );  % bounding box: [x y height width]
        for k = 1:size(bbox,1)
            % Shift and scale mask by percentage of the face height/width
            x = 1.1;  % scale mask width as percentage of face width
            dx = (1-x)/2; % shift to center left/right on face
            scale = x*bbox(k,4)/size( mask, 2 ); % scale mask columns by face width
            bias = [-0.5 dx];  % shift up and use dx to center left/right
            loc = bbox(k,[2 1]) + bias.*bbox(k,3:4); % location: [row column]
            img = superImpose( img, imresize( mask, scale ), loc );
        end
        img = imadjust( img, [0.05 0.95], [0.2 1] );
        img = imadjust( img, [0.2 0 0.2; 0.8 0.8 1], [], 1.4);
        img = imnoise( img, "gaussian", 0, 0.0008 );

    case "grayscale"
        img = repmat( im2gray( img ), [1 1 3] );

    case "hologram"
        % 3D image for horizontal motion when wearing red-cyan glasses
        % (with red-cyan lens over left-right eyes respectively,
        % "cyan image" should appear to be left of "red image")
        [rows,cols] = size( frames, 1:2 );
        red  = newFilter(rows,cols,[255 0 0]);
        cyan = newFilter(rows,cols,[0 255 255]);
        img1 = frames(:,:,:,1);   % current frame
        img2 = frames(:,:,:,end); % older frame
        xdir = xmotion( img1, img2 );
        if (xdir < 0) % right to left motion
            % -> older frame should be red image (by subtracting cyan)
            img = (img2 - cyan) + (img1 - red);
        else  % left to right motion
            % -> current frame should be red image (by subtracting cyan)
            img = (img1 - cyan) + (img2 - red);
        end

    case "kaleidoscope"
        img = kaleidoscope( img, 6 );

    case "negative"
        img = imcomplement( img );

    case "neon"
        se = strel( "disk", 5 );
        img = imsubtract( imdilate( img, se ), imerode( img, se ) );

    case "pencil"
        h = ones( 6 );
        h(3:4,3:4) = -8;
        img = imfilter( im2gray( img ), h, "conv" );
        img = repmat( 255 - img, [1 1 3] );

    case "pincushion"
        img = imdistort( img, -1.28 );

    case "pixelate"
        [nrows,ncols] = size( img, 1:2 );
        scale = 96*[1 ncols/nrows];
        img = imresize( img, scale, "nearest" ); % "blocky" downsample
        img = imresize( img, [nrows,ncols], "nearest" ); % "blocky" upsample

    case "quantize"
        n = 8; % see also imsegkmeans
        thresh = multithresh( img, n );
        value = [0 thresh(2:end) 255];
        img = imquantize( img, thresh, value );

    case "rc-pop"
        % hue = (0:6)/6 = R-Y-G-C-B-M-R
        img = isocolor( img, [3.5 5.9]/6, 0.03 );

    case "wave" % sinusoidal
        [nrows,ncols] = size( img, 1:2 );
        a = ncols/12;
        ifcn = @(xy) [xy(:,1), xy(:,2) + a*sin(2*pi*xy(:,1)/nrows)];
        tform = geometricTransform2d(ifcn);
        oview = imref2d( [nrows,ncols] );
        img = imwarp( img, tform, OutputView=oview, FillValues=0 );

end

end

%% 
function xdir = xmotion( img1, img2 )

% Compare differences in images to determine horizontal motion
thresh = 170;
dI12 = imadjust( im2gray( imsubtract( img1, img2) ) );
dI21 = imadjust( im2gray( imsubtract( img2, img1) ) );

% Compute weighted mean to estimate x location of difference
npts12 = sum( dI12 > thresh, 1 ); % number of points per column
npts21 = sum( dI21 > thresh, 1 ); % number of points per column
x12 = sum( (1:numel(npts12)).*npts12 )/sum( npts12 );
x21 = sum( (1:numel(npts21)).*npts21 )/sum( npts21 );

if (x21 > x12)
    xdir = -1; % right to left motion
else
    xdir = 1;  % left to right motion
end

end