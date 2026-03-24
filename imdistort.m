function img = imdistort( img, amp )

%IMDISTORT Apply radial barrel or pincushion distortion to an RGB image.
%
%   IMG2 = IMDISTORT(IMG, AMP) returns a distorted version of the RGB image IMG.
%   The scalar parameter AMP controls the amount and type of distortion:
%       AMP > 0  produces barrel distortion (image bulges outward).
%       AMP < 0  produces pincushion distortion (image is pinched inward).
%
%   Inputs:
%     IMG - M-by-N-by-3 uint8 RGB image.
%     AMP - scalar numeric distortion coefficient.
%
%   Output:
%     IMG - distorted M-by-N-by-3 uint8 RGB image.

arguments
    img (:,:,3) uint8 % RGB image
    amp (1,1) {mustBeNumeric} % > 0 for barrel, < 0 pincushion
end

% see also: https://www.mathworks.com/help/images/
% creating-a-gallery-of-transformed-images.html

% Create arrays of x/y coordinates of each pixel
% with origin in upper-left corner of image
[nrows,ncols] = size( img, 1:2 );
[x,y] = meshgrid( 1:ncols, 1:nrows );

% Shift origin to center of image and convert from
% Cartesian x/y to cylindrical angle/radius (theta/r)
x = x - ncols/2;
y = y - nrows/2;
[theta,r] = cart2pol( x, y );

% Distort r nonlinearly with distance from center pixel
rmax = max( r(:) );
s = r + amp*(r.^3)/(rmax^2);

% Convert back to Cartesian coordinates and 
% shift origin back to upper-right corner of image
[u,v] = pol2cart( theta, s );
u = u + ncols/2;
v = v + nrows/2;

tmap = cat( 3, u, v );
resamp = makeresampler( "linear", "fill" );
img = tformarray( img, [], resamp, [2 1], [1 2], [], tmap, 0.3 );

% Above is much faster than geometricTransform2d with imwarp...
% func = @(c) [u(:) v(:)];
% tform = geometricTransform2d( func );
% img = imwarp( img, tform );

end