rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(rootDir));

% 1. Test evalQuality
I_ref = im2double(imread('cameraman.tif'));
mask  = true(size(I_ref));
mask(1:20, :) = false;

qSame = evalQuality(I_ref, I_ref, mask);
assert(isinf(qSame.psnr) && abs(qSame.ssim - 1) < 1e-6, 'evalQuality fail tren anh giong nhau');

rng(2026, 'twister');
I_noisy = min(max(I_ref + 0.05 * randn(size(I_ref)), 0), 1);
qNoisy = evalQuality(I_noisy, I_ref, mask);
assert(qNoisy.psnr > 20 && qNoisy.psnr < 35 && qNoisy.ssim > 0 && qNoisy.ssim < 1, ...
    'evalQuality cho gia tri bat thuong tren anh nhieu');

% 2. Test postprocess tren anh van tay gia lap (song sin + vach dut)
[X, Y] = meshgrid(1:160, 1:160);
I_syn = 0.5 + 0.45 * cos(2 * pi * (1/9) * X);
I_syn(75:85, 70:90) = 0.95; % tao khe dut van gia lap dau van
maskSyn = true(size(I_syn));
postParams = struct('margin', 16, 'spurLen', 10);

[minu, skel] = postprocess(I_syn, maskSyn, postParams);
assert(islogical(skel) && isequal(size(skel), size(I_syn)), 'postprocess: skel sai kieu/kich thuoc');
assert(size(minu, 2) == 4 && size(minu, 1) >= 2, 'postprocess: khong trich duoc minutiae');
assert(all(minu(:,3) >= 0 & minu(:,3) < pi), 'postprocess: theta ngoai [0, pi)');
assert(all(ismember(minu(:,4), [1, 2])), 'postprocess: type khac 1 hoac 2');

% 3. Test matchMinutiae
matchParams = struct('dist', 14, 'angle', pi/9, 'useType', false);
minuRef  = [50, 60, 0.2, 1; 100, 100, 1.5, 2];
minuTest = [55, 63, 0.25, 1; 100, 100, 2.5, 2; 150, 150, 0.1, 1];
[P, R, F1, nMatch] = matchMinutiae(minuTest, minuRef, matchParams);
assert(nMatch == 1 && abs(P - 1/3) < 1e-6 && abs(R - 1/2) < 1e-6 && abs(F1 - 0.4) < 1e-6, ...
    'matchMinutiae tinh sai P/R/F1');

% 4. Test runNFIQ2 (chi kiem tra khong crash; neu chua cai NFIQ2 se tra ve NaN)
nfiqParams = struct('exe', '');
s = runNFIQ2(I_syn, nfiqParams);
assert(isnumeric(s) && isscalar(s), 'runNFIQ2 phai tra ve 1 so (hoac NaN)');

fprintf('PASS: test_eval (PSNR=%.2f dB, SSIM=%.4f, nMinu=%d, NFIQ2=%g)\n', ...
    qNoisy.psnr, qNoisy.ssim, size(minu, 1), s);
