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
img = ind2rgb8( gry, bone );  % <-- you can change the colormap here
% img = ind2rgb8( gry, hsv ); % <-- for example replace bone with hsv

% You can delete the code below to remove the text
% (or change the "msg" variable to add your own text)
msg = "Modify 'imcustom.m' to apply your own effect!" + newline ...
    + newline + ">> edit imcustom  % pause or close video first";

% Add the text "msg" above to the the center of the image
cen = size( img, [2 1] )/2; % [width,height]/2 = [xc,yc]
img = insertText( img, cen, msg, AnchorPoint="center", ...
    BoxOpacity=0.8, TextBoxColor="white", ...
    FontSize=round(size(img,2)/25), FontColor=[0.7 0.5 0] );

end % end of function (you can leave this here)