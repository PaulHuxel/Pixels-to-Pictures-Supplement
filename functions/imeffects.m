function img = imeffects( img, effect )

%IMEFFECTS Apply named visual effects to an RGB image.
%
%   IMG = IMEFFECTS(IMG, EFFECT) applies the specified EFFECT to the RGB
%   image IMG and returns the resulting image. IMG must be an M-by-N-by-3
%   uint8 image. EFFECT is one of the following strings:
%
%       "none"         - Return the input image unchanged.
%       "barrel"       - Barrel distortion.
%       "blur"         - Simple blur via down/up sampling.
%       "comic"        - Comic book cartoon-like effect.
%       "edge"         - Edge map (grayscale edges replicated across channels).
%       "gotham"       - Gotham-style effect (requires Computer Vision Toolbox).
%       "grayscale"    - Convert to grayscale (replicated to three channels).
%       "hyperspace"   - Add hyperspace animation overlay.
%       "kaleidoscope" - Kaleidoscope effect.
%       "matrix"       - Matrix-style effect.
%       "negative"     - Photonegative (color complement).
%       "neon"         - Neon/outline effect using morphological operations.
%       "pencil"       - Pencil-sketch style.
%       "pincushion"   - Pincushion distortion.
%       "pixelate"     - Pixelation (blocky down/up sampling).
%       "quantize"     - Color quantization to a small palette.
%       "thermal"      - Thermal colormap mapping of grayscale.
%       "wave"         - Sinusoidal geometric warp (wave).
%       "custom"       - Call user-defined IMCUSTOM to perform custom processing.

arguments
    img (:,:,3) uint8 % RGB image(s)
    effect {mustBeMember(effect,["none","barrel","blur","comic","edge","gotham", ...
        "grayscale","hyperspace","kaleidoscope","matrix","negative","neon", ...
        "pencil","pincushion","pixelate","quantize","thermal","wave","custom"])}
end

switch effect
    case "none"
        % do nothing

    case "barrel"
        img = imdistort( img, 4.8 );

    case "blur"
        scale = 0.1;
        img = imresize( imresize( img, scale ), 1/scale );

    case "comic"
        img = comic( img, Abstraction="smooth", Iterations=1  );

    case "edge"
        img = repmat( uint8( 255*edge( im2gray( img ) ) ), [1 1 3] );

    case "gotham"
        % Requires Computer Vision Toolbox (face detection)
        img = gotham( img );

    case "grayscale"
        img = repmat( im2gray( img ), [1 1 3] );

    case "hyperspace"
        img = addAnimation( img, which( "hyperspace.mat" ) );

    case "kaleidoscope"
        img = kaleidoscope( img, 6 );

    case "matrix"
        img = matrix( img );

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

    case "thermal"
        img = ind2rgb( im2gray( img ), thermal );

    case "wave" % sinusoidal
        [nrows,ncols] = size( img, 1:2 );
        a = ncols/12;
        ifcn = @(xy) [xy(:,1), xy(:,2) + a*sin(2*pi*xy(:,1)/nrows)];
        tform = geometricTransform2d(ifcn);
        oview = imref2d( [nrows,ncols] );
        img = imwarp( img, tform, OutputView=oview, FillValues=0 );

    case "custom"
        sz = size( img, 1:2 );
        img = imcustom( img );
        
        % Ensure proper size and type
        if ~isequal( size(img,1:2), sz )
            img = imresize( img, sz );
        end
        if (size(img,3) == 1)
            img = repmat( img, [1 1 3] );
        end
        if (class(img) ~= "uint8")
            img = im2uint8( img );
        end

end

end