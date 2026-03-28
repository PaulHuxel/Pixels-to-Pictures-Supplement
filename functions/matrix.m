function img = matrix( img )

% MATRIX Create a stylized green penciled rain effect from an RGB input.
%
%   IMG = MATRIX(IMG) takes an M-by-N-by-3 uint8 RGB image and returns a
%   modified M-by-N-by-3 uint8 image with a pixelated grayscale base,
%   transient "raining" bright pixels, and a pencil-like edge filter
%   applied to the green channel. The function maintains a persistent state 
%   for simulated raindrops so consecutive calls animate the falling pixels.
%
%   Usage:
%       out = matrix(in);
%
%   Input:
%       IMG - M-by-N-by-3 uint8 RGB image.
%
%   Output:
%       IMG - M-by-N-by-3 uint8 image containing the stylized effect.

arguments
    img (:,:,3) uint8 % RGB image
end

persistent rows cols drop pixi

% Setup "raining" pixel parameters
[nrows,ncols] = size( img, 1:2 );
if isempty( rows )
    n = ceil( ncols/10 ); % number of raining pixels
    rows = inf( 1, n );   % row location of raining pixel
    cols = zeros( 1, n ); % column location of raining pixel
    drop = zeros( 1, n ); % number of pixels to drop each frame
    pixi = zeros( 1, n ); % pixel intensity of each "raindrop"
end

% Initiate pixelation with a "blocky" downsample
gry = im2gray( img );
scale = round( 180*[1 ncols/nrows] );
gry = imresize( gry, scale, "nearest" );

% Resample if "rows" goes off bottom of image
rows = rows + drop;
idx = (rows > scale(1));
if any( idx )
    n = nnz( idx );
    rows(idx) = randi( round(scale(1)/4), [n,1] ); % start from top quarter
    cols(idx) = randi( scale(2), [n,1] );
    % Nominally travel frame height in 5 seconds (limitrate: 20 fps)
    drop(idx) = ceil( abs( scale(1)/20/5 + randn( n, 1 ) ) );
    pixi(idx)  = randi( 128, [n,1] ); 
end

% Add "raining" pixels to image
idx = sub2ind( scale, rows, cols );
rain = zeros( scale, "uint8" );
rain(idx) = pixi;
gry = gry + rain;

% Finalize pixelation with "blocky" upsample
gry = imresize( gry, [nrows,ncols], "nearest" );

% Apply "pencil" like edge filter
h = ones( 6 );
h(3:4,3:4) = -8;
img(:,:,2) = imfilter( gry, h, "conv" );
img(:,:,[1 3]) = 0;

end