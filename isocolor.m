function iso = isocolor( img, hue, tol )

%ISOCOLOR Isolate specified hues in an RGB image
%   ISO = ISOCOLOR(IMG, HUE) returns an image ISO where pixels in IMG whose
%   hue lies within a small tolerance of the values in HUE retain their
%   original color; all other pixels are converted to grayscale. IMG is an
%   MxNx3 uint8 RGB image. HUE is a scalar or vector of values in the
%   range [0,1] corresponding to positions on the HSV hue wheel (0 and 1
%   both represent red). By default a tolerance of 0.05 is used.
%
%   ISO = ISOCOLOR(IMG, HUE, TOL) uses the tolerance TOL. TOL may be a scalar
%   or a vector with the same length as HUE. A pixel is considered matching 
%   hue H if the circular distance between the pixel hue and H is <= TOL.

arguments
    img (:,:,3) uint8 % hue = (0:6)/6 = R-Y-G-C-B-M-R
    hue double {mustBeVector,mustBeBetween(hue,0,1)} % [0 1]
    tol double {mustBeVector,mustBeBetween(tol,0,1)} = 0.05
end

% Replicate tolerance for each color (if vector not provided)
n = numel( hue );
if ( (n > 1) && isscalar( tol ) )
    tol = repmat( tol, 1, n );
end

% Initial image is grayscale before color isolation
iso = repmat( im2gray( img ), [1 1 3] );
hsv = rgb2hsv( img ); % extract hue
for k = 1:n
    % Use mod to handle wrap around between 0 and 1
    dhue = mod(hsv(:,:,1) - hue(k) + 0.5, 1 ) - 0.5;
    idx = (abs( dhue ) <= tol(k) );

    % Use indices to transfer image color to grayscale image
    idx = repmat( idx, [1 1 3] ); % apply to all 3 channels
    iso(idx) = img(idx);
end

end