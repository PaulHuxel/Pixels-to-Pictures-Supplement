function img = gotham( img )

%GOTHAM Apply a "Gotham" style effect to an RGB image.
%   IMG = GOTHAM(IMG) applies a stylized "Gotham" effect to the input RGB
%   image IMG and returns the processed image. The function detects faces
%   in the image and superimposes a Batman-style mask (loaded from
%   'masks.mat') over each detected face. It then adjusts contrast,
%   darkens mid-tones, and adds subtle Gaussian noise to create a gritty
%   cinematic look.
%
%   Input:
%     IMG  - MxNx3 uint8 RGB image.
%
%   Output:
%     IMG  - Processed MxNx3 uint8 RGB image with the Gotham effect applied.

arguments
    img (:,:,3) uint8 % RGB image
end

% Requires Computer Vision Toolbox (face detection)
persistent faceDetector mask
if isempty( faceDetector )
    faceDetector = vision.CascadeObjectDetector();
    mask = load( "masks.mat", "batman" );
    mask = mask.batman;
end

% Detect face(s) and super impose mask
bbox = faceDetector( img ); % bounding box: [x y height width]
for k = 1:size(bbox,1)
    % Shift and scale mask by percentage of the face height/width
    x = 1.1;  % scale mask width as percentage of face width
    dx = (1-x)/2; % shift to center left/right on face
    scale = x*bbox(k,4)/size( mask, 2 ); % scale mask columns by face width
    bias = [-0.5 dx];  % shift up and use dx to center left/right
    loc = bbox(k,[2 1]) + bias.*bbox(k,3:4); % location: [row column]
    img = superImpose( img, imresize( mask, scale ), loc );
end

% Increase contrast and lift darkest values
img = imadjust( img, [0.05 0.95], [0.2 1] );

% Darken mid-tone RGB values
img = imadjust( img, [0.2 0 0.2; 0.8 0.8 1], [], 1.5 );

% Add noise to the image to make the scene "gritty"
img = imnoise( img, "gaussian", 0, 0.0008 );

end