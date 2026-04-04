function img = imeffects( img, effect )

%IMEFFECTS Apply visual effects to RGB image(s).
%   IMG = IMEFFECTS(IMG, EFFECT) applies the specified EFFECT 
%     to the RGB image and returns the processed image IMG.
%
%   Supported EFFECT values:
%     "none"        - return the input unchanged
%     "barrel"      - barrel lens distortion
%     "blur"        - coarse blur via down/up sampling
%     "edge"        - Canny edge (grayscale) rendered as white on black
%     "gotham"      - stylized "Gotham" filter (requires CV Toolbox)
%     "grayscale"   - convert to grayscale (replicated across 3 channels)
%     "kaleidoscope"- kaleidoscope tiling
%     "negative"    - color negative
%     "neon"        - difference of dilated/eroded image (outline)
%     "matrix"      - "Matrix" style effect
%     "pencil"      - pencil sketch effect
%     "pincushion"  - pincushion lens distortion
%     "pixelate"    - blocky pixelation
%     "quantize"    - color quantization (k = 8)
%     "thermal"     - thermal colormap rendering
%     "wave"        - horizontal sinusoidal warp
%     "custom"      - user-supplied custom filter via IMCUSTOM

arguments
    img (:,:,3) uint8 % RGB image(s)
    effect {mustBeMember(effect,["none","barrel","blur", ...
        "edge","gotham","grayscale","kaleidoscope", ...
        "negative","neon","matrix","pencil","pincushion","pixelate", ...
        "quantize","rc-pop","thermal","wave","custom"])}
end

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

    case "gotham"
        % Requires Computer Vision Toolbox (face detection)
        img = gotham( img );

    case "grayscale"
        img = repmat( im2gray( img ), [1 1 3] );

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