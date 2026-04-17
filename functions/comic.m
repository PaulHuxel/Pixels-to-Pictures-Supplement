function img = comic( img, abstraction, nb )

% COMIC Image abstraction using bilateral filtering 
%    and soft luminance quantization.
%
%    img = comic(img,abstraction,nb) transforms the RGB color 
%    image to have a comic book-like appearance.
%
%    The optional abstraction parameter may be used to set the abstraction 
%    level to "smooth", "moderate", "sharp", or "default". The optional nb 
%    parameter sets the number of bilateral filtering iterations.
%
%    This function uses the abstraction method outlined in:
%      Holger Winnemoller, Sven C. Olsen, and Bruce Gooch.
%      Real-Time Video Abstraction. In Proceedings of ACM SIGGRAPH, 2006.
%      https://www.researchgate.net/publication/220184181_Real-time_video_abstraction
%
%    This function is a modified version of Douglas R. Lanman's cartoon function:
%      https://www.mathworks.com/matlabcentral/fileexchange/12191-bilateral-filtering

arguments
    img (:,:,3) uint8
    abstraction {mustBeMember(abstraction, ...
        ["smooth","moderate","sharp","default"])} = "default"
    nb (1,1) {mustBeNonnegative,mustBeInteger} = ceil(size(img,1)/512)
end

% Set bilateral filter parameters [from Winnemoller, et al.]
% nb = number of bilateral iterations, nb ~ [3,4]
scale = diff( getrangefromclass( img ) )/255;
sigr = 4.25*scale;  % "small values of sigr preserve almost all contrasts"
sigd = 3*scale;     % "increasing sigd results in more blurring"

% Set edge detection parameters (from Lanman)
Gmax = 0.2;  % maximum gradient, set edges >= Gmax to black
Gmin = 0.3;  % minimum gradient, erase edges < Gmin

% Set image abstraction parameters (from Winnemoller, et al.)
% philim = soft quantization sharpness range, "[Lambda_phi Omega_phi]" = [3 14]
% q = number of quantization levels, "q" ~ [8,10]
switch abstraction
    case "default" % more comic-like [Lanman]
        philim = [3 14];
        q = 8;
    case "smooth" % used with "coarse" edges, more painting-like [Winnemoller et al.]
        philim = [0.9 1.6];
        q = 10;
    case "moderate"
        philim = [2 8];
        q = 12;
    case "sharp" % "detailed" used with fine edges [Winnemoller et al.]
        philim = [3.4 10.6];
        q = 14;
end

% Apply bilateral filter to input image
% Note: DegreeOfSmoothing corresponds to the variance of the 
%       Range Gaussian kernel of the Bilateral Filter [Tomasi]
% imbilatfilt improved performance for single since R2022a
img = single( rgb2lab( img ) ); % transform sRGB image to CIELab color space
for k = 1:nb
    img = imbilatfilt( img, DegreeOfSmoothing=sigr^2, SpatialSigma=sigd );
end

% Create a simple edge map using the gradient magnitudes
[Gx,Gy] = gradient(img(:,:,1)/100); % gradient of normalized luminance
E = sqrt(Gx.^2 + Gy.^2);  % gradient magnitudes
E(E > Gmax) = Gmax;       % darken edges > Gmax
E = E/Gmax;               % normalize ~ [0 1]

% Determine per-pixel sharpness parameter (sharper near edges)
phiq = philim(1) + diff( philim )*E; % ~ [philim(1) philim(2)]

% Apply soft luminance quantization (cartoon effect)
dq = 100/(q-1);                  % bin width
qn = dq*round( img(:,:,1)/dq );  % "q_nearest"
img(:,:,1) = qn + (dq/2)*tanh( phiq.*(img(:,:,1) - qn) ); % "Eqn. (6)"
img = lab2rgb( img );  % transform back to sRGB color space

% Add gradient edges to quantized bilaterally-filtered image
E(E < Gmin) = 0;  % erase edges < Gmin
E = 1 - E;        % invert edge map matrix
img = im2uint8( repmat(E,[1 1 3]).*img );

end