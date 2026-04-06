function img = addAnimation( img, fileName, opts )

%ADDANIMATION Overlay a looping animation onto an image
%
%   IMG = ADDANIMATION(IMG) overlays frames from a persistent animation onto
%   the input image IMG. The animation is loaded from a file on the first
%   call and is reused on subsequent calls.
%
%   IMG = ADDANIMATION(IMG, FILENAME) specifies the animation file to load
%   on the first call. FILENAME may be:
%       - A .mat file containing a variable named "frames" (HxWx3xN uint8)
%       - A .gif file (any indexed or truecolor GIF)
%   If FILENAME is empty or omitted on subsequent calls, the previously
%   loaded animation is reused.
%
%   IMG = ADDANIMATION(..., 'Intensity', I) scales the animation frames by
%   the scalar intensity I before adding them to IMG. I must be in [0,1].
%   Default is 1.
%
%   Inputs
%     IMG       - HxWx3 uint8 RGB image to which the animation is added.
%     FILENAME  - (optional) string path to .mat or .gif animation file.
%
%   Name-Value
%     'Intensity' - scalar in [0,1]. Default: 1.
%
%   Output
%     IMG - HxWx3 uint8 RGB image with the current animation frame added.

arguments
    img (:,:,:) uint8
    fileName string {mustBeFile,mustBeScalarOrEmpty} = []
    % second input only required on first function call
    opts.Intensity (1,1) {mustBeBetween(opts.Intensity,0,1)} = 1
end

persistent frames k

if isempty( frames )
    k = 0;
    [~,~,ext] = fileparts( fileName );
    switch ext
        case ".mat"
            load( fileName, "frames" )

        case ".gif"
            [gif,cmap] = imread( fileName, Frames="all" );
            frameSize = size( gif );
            frameSize(3) = 3; % RGB
            frames = zeros( frameSize, "uint8" );
            for k = 1:frameSize(4)
                frames(:,:,:,k) = im2uint8( ind2rgb( gif(:,:,:,k), cmap ) );
            end

        otherwise
            error( "Animation file type must be .mat or .gif" )
    end
    frames = imresize( frames, size( img, 1:2 ) );
end

k = k + 1;
if (k > size( frames, 4 ) )
    k = 1;
end
img = img + opts.Intensity*frames(:,:,:,k);

end