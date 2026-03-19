function img = imeffects( img, effect )

arguments
    img (:,:,3) uint8 % RGB image
    effect {mustBeMember(effect,["none","barrel","blur","edge","grayscale", ...
        "negative","neon","pencil","pincushion","pixelate","quantize","wave"])}
end

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

    case "grayscale"
        img = repmat( im2gray( img ), [1 1 3] );

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