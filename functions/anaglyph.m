function img = anaglyph( img1, img2, opts )

%ANAGLYPH Create an RGB anaglyph image from two input images.
%   IMG = ANAGLYPH(IMG1, IMG2) combines two input images IMG1 and IMG2 into
%   a single anaglyph image suitable for viewing with red/cyan (default)
%   glasses. IMG1 is treated as the left-eye view and IMG2 as the
%   right-eye view. Input images must have the same size and data type.
%
%   IMG = ANAGLYPH(IMG1, IMG2, Name,Value, ...) specifies optional name
%   value pair arguments using one or more of the following:
%
%   'Colors'  - 2x3 matrix specifying the color filters applied to the
%              left and right images, respectively. Each row is an RGB
%              triplet with values in the range [0,1]. Default:
%              [1 0 0; 0 1 1] (red for left eye lens, cyan for right eye lens).
%
%   'Motion'  - logical flag (true/false). When true, the function will
%              attempt to detect horizontal foreground motion between
%              the two images and, if necessary, swap the images so the
%              perceived motion matches left-to-right convention.
%              Default: false.

arguments
    img1 (:,:,:) {mustBeNumeric}
    img2 {mustBeSame(img1,img2)}
    % Colors: [left lens; right lens]
    opts.Colors (2,3) {mustBeBetween(opts.Colors,0,1)} = [1 0 0; 0 1 1]
    opts.Motion (1,1) logical = false
end

[rows,cols,chans] = size( img1 );
if (chans == 1)
    img1 = repmat( img1, [1,1,3] );
    img2 = repmat( img2, [1,1,3] );
end

if opts.Motion
    xdir = xmotion( img1, img2 );
    if (xdir > 0) % left to right motion
        % swamp images
        temp = img1;
        img1 = img2;
        img2 = temp;
    end
end

% img1: visible with left eye (subtract right lens filter)
% img2: visible with right eye (subtract left lens filter)
left  = newFilter( rows, cols, 255*opts.Colors(1,:) );
right = newFilter( rows, cols, 255*opts.Colors(2,:) );
img = (img1 - right) + (img2 - left);

end

%% Custom validation function
function mustBeSame(img1,img2)
if ~isequal(size(img1),size(img2)) || ~isequal(class(img1),class(img2))
    error("Images must be of the same size and data type.")
end
end

%% Detect horizontal foreground motion direction (for fixed background)
function xdir = xmotion( img1, img2 )
% xdir > 0 : left to right motion in foreground
% xdir < 0 : right to left motion in foreground

% Compare differences in images to determine relative x position
dI12 = imadjust( im2gray( imsubtract( img1, img2) ) );
dI21 = imadjust( im2gray( imsubtract( img2, img1) ) );

% Compute weighted mean to estimate x location of difference
thresh = 170; % count up bright pixels
n12 = sum( dI12 > thresh, 1 ); % number per column
n21 = sum( dI21 > thresh, 1 ); % number per column
x12 = sum( (1:numel(n12)).*n12 )/sum( n12 );
x21 = sum( (1:numel(n21)).*n21 )/sum( n21 );
xdir = sign( x12 - x21 ); % return estimated x direction

end
