%% system
clc; clear; close all;
function noisy = addNoise(clean, type, level, seed)
%ADDNOISE Them nhieu nhan tao vao anh sach.
%   noisy = addNoise(clean, type, level, seed)
%
%   clean : anh double [0,1], 2D
%   type  : 'awgn' | 'speckle' | 'saltpepper'
%   level : AWGN, speckle -> do lech chuan sigma cua n (n ~ N(0, sigma^2))
%           saltpepper    -> mat do nhieu d (ty le pixel bi thay, 0..1)
%   seed  : (tuy chon) seed co dinh; rong -> khong dat seed.
%           Nen tao bang noiseSeed(tenAnh, type, level).
%
%   AWGN       : In = I + n
%   Speckle    : In = I .* (1 + n)
%   Salt&pepper: thay pixel ngau nhien bang 0 hoac 1 (moi loai d/2)
%   Ket qua duoc cat ve [0,1] theo quy uoc chung.

validateattributes(clean, {'double'}, {'2d', 'nonempty', '>=', 0, '<=', 1}, ...
    mfilename, 'clean');
validateattributes(level, {'numeric'}, {'scalar', 'nonnegative'}, ...
    mfilename, 'level');

% Dat seed nhung khong lam hong trang thai RNG cua noi goi
if nargin >= 4 && ~isempty(seed)
    prev = rng;
    rng(seed, 'twister');
    restoreRng = onCleanup(@() rng(prev));
end

switch lower(type)
    case 'awgn'
        n = level * randn(size(clean));
        noisy = clean + n;

    case 'speckle'
        n = level * randn(size(clean));
        noisy = clean .* (1 + n);

    case {'saltpepper', 'salt_pepper', 'sp'}
        assert(level <= 1, 'addNoise:level', 'Mat do salt&pepper phai <= 1.');
        u = rand(size(clean));
        noisy = clean;
        noisy(u <  level/2)                 = 0;   % pepper
        noisy(u >= level/2 & u < level)     = 1;   % salt

    otherwise
        error('addNoise:type', ...
            'Loai nhieu khong hop le: "%s" (awgn|speckle|saltpepper).', type);
end

noisy = min(max(noisy, 0), 1);
end
