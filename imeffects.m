function img = imeffects( img, effect )

%IMEFFECTS Apply stylized effects to an RGB image or sequence of RGB images.
%   IMG = IMEFFECTS(IMG, EFFECT) applies the specified EFFECT to the input
%   image or image sequence IMG and returns the resulting image IMG.
%
%   Inputs
%     IMG    - M-by-N-by-3-by-K uint8 array containing one or more RGB
%              frames. Effects (except for "ghost" and "hologram") are
%              applied only to the first frame. For sequence-aware effects,
%              multiple frames may be used.
%     EFFECT - A string specifying the effect to apply. Valid values are:
%              "none", "barrel", "blur", "edge", "ghost", "gotham",
%              "grayscale", "hologram", "kaleidoscope", "negative",
%              "neon", "pencil", "pincushion", "pixelate", "quantize",
%              "wave".
%
%   Output
%     IMG    - M-by-N-by-3 uint8 RGB image with the chosen effect applied.
%
%   Description of selected effects
%     "none"        - Return the input frame unchanged.
%     "barrel"      - Apply a barrel (fisheye) distortion.
%     "pincushion"  - Apply pincushion distortion (negative barrel).
%     "blur"        - Fast box down/up sampling to simulate blur.
%     "edge"        - Canny-like edge map rendered as a 3-channel image.
%     "ghost"       - Blend multiple frames to create a ghosting trail.
%     "gotham"      - Superimpose a mask on detected faces and apply color
%                     grading/noise (requires Computer Vision Toolbox).
%     "grayscale"   - Convert to luminance and replicate to RGB.
%     "hologram"    - Create a red/cyan stereoscopic composite from first
%                     and last frames.
%     "kaleidoscope" - Create a kaleidoscopic tiling of the image.
%     "negative"    - Photonegative of the image.
%     "neon"        - Morphological edge extraction for a neon-like effect.
%     "pencil"      - Pencil-sketch style rendering.
%     "pixelate"    - Blocky pixelation using nearest-neighbor resampling.
%     "quantize"    - Color-quantize the image into a small number of levels.
%     "wave"        - Sinusoidal geometric warp.

arguments
    img (:,:,3,:) uint8 % RGB image(s)
    effect {mustBeMember(effect,["none","barrel","blur","edge","ghost", ...
        "gotham","grayscale","hologram","kaleidoscope","negative","neon", ...
        "pencil","pincushion","pixelate","quantize","wave"])}
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
        img = imdistort( img, 0.3 );

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
        img = imdistort( img, -0.08 );

    case "pixelate"
        [nrows,ncols] = size( img, 1:2 );
        scale = 64*[1 ncols/nrows];
        img = imresize( img, scale, "nearest" ); % "blocky" downsample
        img = imresize( img, [nrows,ncols], "nearest" ); % "blocky" upsample

    case "quantize"
        n = 8; % see also imsegkmeans
        thresh = multithresh( img, n );
        value = [0 thresh(2:end) 255];
        img = imquantize( img, thresh, value );

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