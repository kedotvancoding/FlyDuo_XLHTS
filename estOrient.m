function [theta, coh] = estOrient(I, mask, blockSize, sigmaSmooth)
% ESTORIENT Ước lượng bản đồ hướng vân cục bộ và độ tin cậy (coherence) - Mốc M1
if nargin < 2 || isempty(mask)
    mask = true(size(I));
else
    mask = logical(mask);
end
if nargin < 3 || isempty(blockSize)
    blockSize = 16;
end
if nargin < 4 || isempty(sigmaSmooth)
    sigmaSmooth = 1.5;
end

I = double(I);


hPre = gaussianKernel2D(5, 1.0);
I_smooth = conv2(I, hPre, 'same');


sobelX = [-1 0 1; -2 0 2; -1 0 1] / 8;
sobelY = [-1 -2 -1; 0 0 0; 1 2 1] / 8;
Gx = conv2(I_smooth, sobelX, 'same');
Gy = conv2(I_smooth, sobelY, 'same');


hBlock = gaussianKernel2D(blockSize, blockSize / 3);
Gxx = conv2(Gx.^2, hBlock, 'same');
Gyy = conv2(Gy.^2, hBlock, 'same');
Gxy = conv2(Gx .* Gy, hBlock, 'same');


sin2Phi = 2 * Gxy;
cos2Phi = Gxx - Gyy;

kSize = 2 * ceil(3 * sigmaSmooth) + 1;
hSmooth = gaussianKernel2D(kSize, sigmaSmooth * (blockSize / 2));
sin2Phi_s = conv2(sin2Phi, hSmooth, 'same');
cos2Phi_s = conv2(cos2Phi, hSmooth, 'same');


thetaGrad = 0.5 * atan2(sin2Phi_s, cos2Phi_s);
theta = mod(thetaGrad + pi/2, pi);


denom = conv2(Gxx + Gyy, hBlock, 'same') + eps;
num = sqrt(sin2Phi_s.^2 + cos2Phi_s.^2);
coh = min(max(num ./ denom, 0), 1);

theta(~mask) = 0;
coh(~mask) = 0;
end

function h = gaussianKernel2D(kSize, sigma)
half = floor(kSize / 2);
[x, y] = meshgrid(-half:half, -half:half);
h = exp(-(x.^2 + y.^2) / (2 * sigma^2));
h = h / sum(h(:));
end