%% system
clc; clear; close all;
function test_addNoise()
%TEST_ADDNOISE Kiem thu addNoise va ve pho 2D (anh sach tam).
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src', 'noise'));

% Anh sach tam: van song sin xoay (giong vung van tay), nen 0.5
[X, Y] = meshgrid(1:256);
th = pi/6; f0 = 1/9;
clean = 0.5 + 0.3 * sin(2*pi*f0*(X*cos(th) + Y*sin(th)));
mid   = 0.5 * ones(256);                 % dung de kiem tra thong ke

% 1. Dinh dang dau ra
for t = {'awgn','speckle','saltpepper'}
    out = addNoise(clean, t{1}, 0.05, 1);
    assert(isa(out,'double') && isequal(size(out), size(clean)));
    assert(all(out(:) >= 0 & out(:) <= 1), 'Ngoai [0,1]: %s', t{1});
end

% 2. Tai lap theo seed, khac seed thi khac
a = addNoise(clean, 'awgn', 0.05, 7);
b = addNoise(clean, 'awgn', 0.05, 7);
c = addNoise(clean, 'awgn', 0.05, 8);
assert(isequal(a, b), 'Cung seed phai cho cung ket qua');
assert(~isequal(a, c), 'Khac seed phai khac ket qua');
assert(isequal(noiseSeed('a.png','awgn',0.05), noiseSeed('a.png','awgn',0.05)));
assert(noiseSeed('a.png','awgn',0.05) ~= noiseSeed('b.png','awgn',0.05));

% 3. AWGN: std(noisy - I) ~ sigma
sigma = 0.05;
n = addNoise(mid, 'awgn', sigma, 1) - mid;
assert(abs(std(n(:)) - sigma) < 0.05*sigma, 'AWGN sai sigma');
assert(abs(mean(n(:))) < 0.002, 'AWGN lech trung binh');

% 4. Speckle: n = (In - I)/I co std ~ sigma
n = (addNoise(mid, 'speckle', sigma, 1) - mid) ./ mid;
assert(abs(std(n(:)) - sigma) < 0.05*sigma, 'Speckle sai sigma');

% 5. Salt & pepper: chi 0/1 tai pixel bi thay, ty le ~ d
d  = 0.10;
sp = addNoise(mid, 'saltpepper', d, 1);
hit = (sp ~= mid);
assert(all(sp(hit) == 0 | sp(hit) == 1));
assert(abs(mean(hit(:)) - d) < 0.005, 'Mat do S&P sai');
assert(abs(mean(sp(hit)) - 0.5) < 0.03, 'Salt/pepper khong can bang');

% 6. Khong lam hong anh goc va trang thai RNG
c0 = clean; rng(123); r1 = rand;
rng(123); addNoise(clean, 'awgn', 0.05, 5); r2 = rand;
assert(isequal(c0, clean) && r1 == r2, 'RNG/anh goc bi thay doi');

% 7. Loai nhieu sai phai bao loi
assert(throws(@() addNoise(clean, 'abc', 0.1, 1)));

% 8. Ve pho bien do 2D: anh sach vs 3 loai nhieu
names = {'Sach','AWGN \sigma=0.1','Speckle \sigma=0.3','Salt&pepper d=0.1'};
imgs  = {clean, ...
    addNoise(clean,'awgn',0.1,noiseSeed('synthetic','awgn',0.1)), ...
    addNoise(clean,'speckle',0.3,noiseSeed('synthetic','speckle',0.3)), ...
    addNoise(clean,'saltpepper',0.1,noiseSeed('synthetic','saltpepper',0.1))};
fig = figure('Name','Pho bien do 2D','Position',[100 100 1000 600]);
for k = 1:4
    subplot(2,4,k);   imshow(imgs{k}); title(names{k});
    subplot(2,4,k+4); spectrum2D(imgs{k}, 'Title', ['Pho: ' names{k}]);
end
outDir = fullfile(fileparts(mfilename('fullpath')), '..', 'results', 'figures');
if ~exist(outDir, 'dir'), mkdir(outDir); end
exportgraphics(fig, fullfile(outDir, 'noise_spectrum_demo.png'), 'Resolution', 200);
% 9. Pho bien do 2D tren 2 anh van tay sach that
files = {'van01.png', 'van02.png'};          % <-- doi thanh anh cua ban
dataDir = fullfile(fileparts(mfilename('fullpath')), '..', 'data');
fig2 = figure('Name','Pho 2 anh sach','Position',[100 100 800 700]);
for k = 1:numel(files)
    I = im2double(imread(fullfile(dataDir, files{k})));
    if size(I,3) == 3, I = rgb2gray(I); end
    subplot(2,2,2*k-1); imshow(I);
    title(files{k}, 'Interpreter', 'none');
    subplot(2,2,2*k);   spectrum2D(I, 'Title', ['Pho: ' files{k}]);
end
saveas(fig2, fullfile(outDir, 'clean_spectrum_2imgs.png'));
disp('test_addNoise: TAT CA DEU DAT');
end

function tf = throws(fn)
try, fn(); tf = false; catch, tf = true; end
end
