function mask = colorMask( img, hue, opts )

%COLORMASK  Create a mask of pixels matching specified hues.
%   MASK = COLORMASK(IMG, HUE) returns a logical mask of the same height and
%   width as the truecolor image IMG (MxNx3 uint8) where pixels have hue
%   values matching HUE. HUE is specified in normalized units in [0,1],
%   where 0 and 1 represent red, 1/6 yellow, 2/6 green, 3/6 cyan,
%   4/6 blue, and 5/6 magenta.

arguments
    img (:,:,3) uint8 % hue = (0:6)/6 = R-Y-G-C-B-M-R
    hue double {mustBeVector,mustBeBetween(hue,0,1)} % [0 1]
    opts.HueTol double {mustBeVector,mustBeBetween(opts.HueTol,0,0.5)} = 0.1
    opts.SatValLim double {mustBeVector,mustBeBetween(opts.SatValLim,0,1)} = 0.2
end

% Replicate tolerance for each color (if vector not provided)
n = numel( hue ); % number of hues specified
tol = opts.HueTol;
if ( (n > 1) && isscalar( tol ) )
    tol = repmat( tol, 1, n );
end

% Extract hue-saturation-value (HSV) from red-green-blue (RGB) image
hsv = rgb2hsv( img );

% Create mask combining specified hues
mask = false( size( img, 1:2 ) );
for k = 1:n
    % Use mod to handle wrap around between 0 and 1
    dhue = mod( hsv(:,:,1) - hue(k) + 0.5, 1 ) - 0.5;
    mask = mask | (abs( dhue ) <= tol(k) );
end

% Remove very light (saturation < lim) and very dark shades (value < lim)
lim = opts.SatValLim;
mask = mask & (hsv(:,:,2) >= lim(1)) & (hsv(:,:,3) >= lim(end));

end