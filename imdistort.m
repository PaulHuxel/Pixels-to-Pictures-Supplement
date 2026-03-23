function img = imdistort( img, a )

%IMDISTORT Apply radial barrel or pincushion distortion to an RGB image.
%
%   IMG2 = IMDISTORT(IMG, A) returns a distorted version of the RGB image IMG.
%   The scalar parameter A controls the amount and type of distortion:
%       A > 0  produces barrel distortion (image bulges outward).
%       A < 0  produces pincushion distortion (image is pinched inward).
%
%   Inputs:
%     IMG - M-by-N-by-3 uint8 RGB image.
%     A   - scalar numeric distortion coefficient.
%
%   Output:
%     IMG - distorted M-by-N-by-3 uint8 RGB image.

arguments
    img (:,:,3) uint8 % RGB image
    a (1,1) {mustBeNumeric} % > 0 for barrel, < 0 pincushion
end

% see also: https://www.mathworks.com/help/images/
% creating-a-gallery-of-transformed-images.html

[nrows,ncols] = size( img, 1:2 );

[x,y] = meshgrid( 1:ncols, 1:nrows );
[theta,r] = cart2pol( x(:)-ncols/2, y(:)-nrows/2 );
s = r + (a/1e4)*(r.^3);

[u,v] = pol2cart( theta, s );
u = reshape( u+ncols/2, [nrows, ncols] );
v = reshape( v+nrows/2, [nrows, ncols] );

tmap = cat( 3, u, v );
resamp = makeresampler( "linear", "fill" );
img = tformarray( img, [], resamp, [2 1], [1 2], [], tmap, 0.3 );

% Above is much faster than geometricTransform2d with imwarp...
% func = @(c) [u(:) v(:)];
% tform = geometricTransform2d( func );
% img = imwarp( img, tform );

end