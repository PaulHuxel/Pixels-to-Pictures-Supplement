function img = kaleidoscope( img, nweds )

%KALEIDOSCOPE Create a kaleidoscope effect by mirroring a wedge of an image.
%
%   IMG = KALEIDOSCOPE(IMG) returns an RGB image the same size as IMG with a
%   kaleidoscope effect created by dividing the image into three mirrored
%   wedges (default).
%
%   IMG = KALEIDOSCOPE(IMG, NWEDS) specifies the number of wedges (NWEDS).
%   NWEDS must be a positive integer. The function extracts a single wedge
%   centered on the image, mirrors it, and replicates it around the image
%   center to produce the kaleidoscope pattern.
%
%   Inputs
%     IMG   - M-by-N-by-3 uint8 RGB image.
%     NWEDS - Scalar positive integer specifying number of wedges around
%             the center (default = 6).
%
%   Output
%     IMG   - M-by-N-by-3 uint8 RGB image with kaleidoscope effect applied.

arguments
    img (:,:,3) uint8 % RGB image
    nweds (1,1) {mustBePositive,mustBeInteger} = 6 % # of wedges
end

% See: https://www.mathworks.com/
% help/images/image-coordinate-systems.html

% Find center of image
[nrows,ncols] = size( img, 1:2 );
xc = (ncols + 1)/2; % columns
yc = (nrows + 1)/2; % rows

% Create grid of pixel points relative to center
[X,Y] = meshgrid( 1:ncols, 1:nrows );
dX = X - xc;
dY = Y - yc;

% Convert grid to polar coordinates about center
rho = hypot( dX, dY );    % could add scaling here
theta = atan2d( dY, dX ); % [-180, 180] deg

% Modify theta to extract wedge to be replicated
% (map theta values to the range [-wedge/2 +wedge/2])
wedge = 360/nweds;
theta = mod( theta + wedge/2, wedge) - wedge/2;

% Mirror within wedge (reflects bottom half 
% because positive theta is clockwise)
theta = abs( theta );

% Map back to pixel coordinates
X = xc + rho.*cosd( theta );
Y = yc + rho.*sind( theta );

% Clip coordinates to image size
X = min( max( round(X), 1), ncols );
Y = min( max( round(Y), 1), nrows );

% Convert intrinsic coordinates to indices
idx = sub2ind( [nrows,ncols], Y, X );
for c = 1:3
    chan = img(:,:,c);
    img(:,:,c) = chan(idx);
end

end