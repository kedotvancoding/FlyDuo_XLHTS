%% system
clc; clear; close all;
function [S, fx, fy] = spectrum2D(img, varargin)
%SPECTRUM2D Pho bien do 2D (thang log) cua anh.
%   [S, fx, fy] = spectrum2D(img)
%   [S, fx, fy] = spectrum2D(img, 'Window', true, 'Plot', true, 'Title', 'ten')
%
%   S      : log(1 + |FFT2|) da fftshift, dong/cot cung kich thuoc anh
%   fx, fy : truc tan so (chu ky/pixel), tu -0.5 den ~0.5
%   Window : nhan cua so Hann 2D truoc FFT de giam ro ri pho (mac dinh true)
%   Plot   : ve hinh (mac dinh true)

p = inputParser;
addParameter(p, 'Window', true, @islogical);
addParameter(p, 'Plot',   true, @islogical);
addParameter(p, 'Title',  '',   @(x) ischar(x) || isstring(x));
parse(p, varargin{:});

validateattributes(img, {'double'}, {'2d', 'nonempty'}, mfilename, 'img');
[M, N] = size(img);

x = img - mean(img(:));                 % bo thanh phan DC cho pho de nhin
if p.Results.Window
    wy = 0.5 * (1 - cos(2*pi*(0:M-1)'/max(M-1,1)));
    wx = 0.5 * (1 - cos(2*pi*(0:N-1) /max(N-1,1)));
    x  = x .* (wy * wx);
end

F = fftshift(fft2(x));
S = log1p(abs(F));

fx = ((0:N-1) - floor(N/2)) / N;        % chu ky/pixel
fy = ((0:M-1) - floor(M/2)) / M;

if p.Results.Plot
    imagesc(fx, fy, S); axis image; colormap(gca, gray); colorbar;
    xlabel('f_x (chu ky/pixel)'); ylabel('f_y (chu ky/pixel)');
    title(char(p.Results.Title));
end
end
