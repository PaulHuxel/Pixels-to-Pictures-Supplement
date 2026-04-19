function img = comic( img, opts )

%COMIC Produce a cartoon-like, comic book style version of an RGB image.
%
%   IMG2 = COMIC(IMG) returns an 8-bit RGB image IMG2 produced by applying
%   edge-preserving bilateral filtering, soft luminance quantization, and
%   edge enhancement to the input RGB image IMG. The algorithm is based on
%   Winnemöller, Olsen, and Gooch, "Real-Time Video Abstraction" (SIGGRAPH,
%   2006) with edge detection parameters and integration inspired by
%   Douglas R. Lanman's implementation on File Exchange (ID: 12191).
%
%   IMG must be an M-by-N-by-3 uint8 RGB image. The output IMG2 is the same
%   size and class uint8.
%
%   IMG2 = COMIC( IMG, Abstraction=MODE, Iterations=N ) allows additional
%   options to control the abstraction effect:
%     Abstraction - where MODE is one of:
%                   "default"  : comic-like (Lanman) [default]
%                   "smooth"   : smooth/painting-like (Winnemöller)
%                   "moderate" : intermediate effect
%                   "sharp"    : detailed/sharp quantization
%     Iterations  - nonnegative integer specifying the number of
%                   bilateral filter iterations to apply (default 1).
%                   Winnemöller suggest ~3-4 iterations for stronger
%                   abstraction; each iteration increases smoothing.
%
%   Example:
%     I = imread("peppers.png");
%     J = comic(I, Abstraction="default", Iterations=2);
%     imshow(J)
%
%   References:
%     H. Winnemöller, S. C. Olsen, B. Gooch, "Real-Time Video Abstraction",
%     Proceedings of ACM SIGGRAPH, 2006.
%
% See also rgb2lab, lab2rgb, imbilatfilt, im2uint8

%   Reference Links:
%     Holger Winnemoller, Sven C. Olsen, and Bruce Gooch.
%     Real-Time Video Abstraction. In Proceedings of ACM SIGGRAPH, 2006.
%     https://www.researchgate.net/publication/220184181_Real-time_video_abstraction
%
%     Douglas R. Lanman's cartoon function:
%     https://www.mathworks.com/matlabcentral/fileexchange/12191-bilateral-filtering

arguments
    img (:,:,3) uint8
    opts.Abstraction {mustBeMember(opts.Abstraction, ...
        ["smooth","moderate","sharp","default"])} = "default"
    opts.Iterations (1,1) {mustBeNonnegative,mustBeInteger} = 1
end

% Set bilateral filter parameters [from Winnemoller, et al.]
% opts.Iterations = "nb", number of bilateral iterations ~ [3,4]
scale = diff( getrangefromclass( img ) )/255;
sigr = 4.25*scale;  % "small values of sigr preserve almost all contrasts"
sigd = 3*scale;     % "increasing sigd results in more blurring"

% Set edge detection parameters (from Lanman)
Gmax = 0.2;  % maximum gradient, set edges >= Gmax to black
Gmin = 0.3;  % minimum gradient, erase edges < Gmin

% Set image abstraction parameters (from Winnemoller, et al.)
% philim = soft quantization sharpness range, "[Lambda_phi Omega_phi]" = [3 14]
% q = number of quantization levels, "q" ~ [8,10]
switch opts.Abstraction
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
for k = 1:opts.Iterations
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