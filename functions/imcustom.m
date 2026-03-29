function img = imcustom( img )

% Replace the code below to add your own
% custom effects to the Web Cam Pixelater app!

% You may want to test your code in the command
% window first, so it's easier to debug.
% >> img = imread( "peppers.png" );
% >> img = imcustom( img );
% >> imshow( img )

% You can start by replacing "bone" (without quotes) 
% in the code below with one these other color maps:
% https://www.mathworks.com/help/matlab/ref/colormap.html#buc3wsn-1-map
gry = im2gray( img );
img = ind2rgb( gry, bone );  % <-- you can change the colormap here
% img = ind2rgb( gry, hsv ); % <-- for example replace bone with hsv

% Or instead, you can isolate your favorite colors (divide by 6 to normalize)
% Hues: 0-Red, 1-Yellow, 2-Green, 3-Cyan, 4-Blue, 5-Magenta, 6-Red
% img = isocolor( img, [0.5 1.3]/6 ); % <-- for example orange and greenish

% You can delete the code below to remove the text
% (insertText require the Computer Vision Toolbox)
hasCompVision = license( "test", "video_and_image_blockset" );
if logical( hasCompVision )
    % Add the text "msg" above to the the center of the image
    msg = "Modify 'imcustom.m' to apply your own effect!" + newline ...
        + newline + ">> edit imcustom  % pause or close video first";
    cen = size( img, [2 1] )/2; % [width,height]/2 = [xc,yc]
    img = insertText( img, cen, msg, AnchorPoint="center", ...
        BoxOpacity=0.8, TextBoxColor="white", ...
        FontSize=round(size(img,2)/25), FontColor=[0.7 0.5 0] );
end

end % end of function (you can leave this here)