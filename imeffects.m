function img = imeffects( img, effect )

arguments
    img (:,:,3,:) uint8 % RGB image(s)
    effect {mustBeMember(effect,["none","barrel","blur","edge","ghost", ...
        "gotham","grayscale","hologram","negative","neon","pencil", ...
        "pincushion","pixelate","quantize","wave"])}
end

persistent faceDetector mask
if isempty( faceDetector )
    faceDetector = vision.CascadeObjectDetector();
    mask = load("masks.mat","batman");
    mask = mask.batman;
end

frames = img;
img = frames(:,:,:,end); % newest frame

switch effect
    case "none"
        % do nothing

    case "barrel"
        a = 0.00003;
        img = imdistort( img, a );

    case "blur"
        scale = 0.1;
        img = imresize( imresize( img, scale ), 1/scale );

    case "edge"
        img = repmat( uint8( 255*edge( im2gray( img ) ) ), [1 1 3] );

    case "ghost"
        img = frames(:,:,:,end); % oldest frame, first background
        n = size( frames, 4 );
        for k = ((n-1):-1:1) % end with newest frame as final foreground
            img = imblend( frames(:,:,:,k), img );
        end

    case "gotham"
        % Requires Computer Vision Toolbox (face detection)
        bbox = faceDetector( img );  % bounding box: [x y height width]
        if ~isempty( bbox )
            % Shift and scale mask by percentage of the face height/width
            x = 1.1;  % scale mask width as percentage of face width
            dx = (1-x)/2; % shift to center left/right on face
            scale = x*bbox(1,4)/size( mask, 2 ); % scale mask columns by face width
            bias = [-0.5 dx];  % shift up and use dx to center left/right
            loc = bbox(1,[2 1]) + bias.*bbox(1,3:4); % location: [row column]
            img = superImpose( img, imresize( mask, scale ), loc );
        end
        img = imadjust( img, [0.05 0.95], [0.2 1] );
        img = imadjust( img, [0.2 0 0.2; 0.8 0.8 1], [], 1.4);
        img = imnoise( img, "gaussian", 0, 0.0008 );

    case "grayscale"
        img = repmat( im2gray( img ), [1 1 3] );

    case "hologram"
        % 3D image for left to right motion when wearing red-cyan glasses
        % (with lens over the left and right eyes respectively)
        [rows,cols] = size( frames, 1:2 );
        red  = newFilter(rows,cols,[255 0 0]);
        cyan = newFilter(rows,cols,[0 255 255]);
        img = (frames(:,:,:,1) - cyan) + (frames(:,:,:,end) - red);

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
        a = -0.000008;
        img = imdistort( img, a );

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
        img = imwarp( img, tform, FillValues=0 );

end

end

%% 

function img = imdistort( img, a )

[nrows,ncols] = size( img, 1:2 );
[x,y] = meshgrid( 1:ncols, 1:nrows );
[theta,r] = cart2pol( x(:)-ncols/2, y(:)-nrows/2 );
s = r + a * r.^3;
[u,v] = pol2cart( theta, s );
u = reshape( u+ncols/2, [nrows, ncols] );
v = reshape( v+nrows/2, [nrows, ncols] );
tmap = cat( 3, u, v );
resamp = makeresampler( "linear", "fill" );
img = tformarray( img, [], resamp, [2 1], [1 2], [], tmap, 0.3 );

end