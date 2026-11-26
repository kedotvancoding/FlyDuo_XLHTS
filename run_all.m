%% system
clc; clear; close all;

%% run_all.m — Chạy toàn bộ pipeline FlyDuo (A1)
%   >> run_all                    % stage 'M1' (mặc định)
%   >> stage = 'M2'; run_all      % hoặc 'FINAL' (chỉ sau khi đóng băng config)
%
% Chuỗi: ảnh sạch → ROI → nhiễu (seed cố định) → hướng/tần số → lọc →
%        hậu xử lý → đánh giá → bảng kết quả.
% Đầu ra trong results/<stage>/: raw_results.csv, baseline_table.csv (M1) hoặc
% summary_table.csv, run_log.txt.
%
% STUB: mỗi hàm trong CONVENTIONS mục 3 có stub nội bộ (hàm stub_* ở cuối file).
% Có file thật trong src/ (đúng tên) thì run_all tự dùng file thật, ngược lại dùng stub.

if ~exist('stage', 'var') || isempty(stage), stage = 'M1'; end
clearvars -except stage; clc; close all;

%% 0. Khởi tạo
rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(rootDir, 'src')));
addpath(fullfile(rootDir, 'config'));
cfg = config(stage);

outDir = cfg.run.outDir;
if ~exist(outDir, 'dir'), mkdir(outDir); end
logFile = fullfile(outDir, 'run_log.txt');
if exist(logFile, 'file'), delete(logFile); end
diary(logFile);
diaryGuard = onCleanup(@() diary('off'));
tStart = tic;

fprintf('=== FlyDuo run_all | stage %s | %s ===\n', stage, datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('MATLAB %s | seed %d | tập ảnh: %s\n', version, cfg.seed, cfg.run.imageSet);

% Gắn từng mô-đun: file thật nếu có, không thì stub
M.prepImage     = pick('prepImage',     @stub_prepImage);
M.roiMask       = pick('roiMask',       @stub_roiMask);
M.addNoise      = pick('addNoise',      @stub_addNoise);
M.estOrient     = pick('estOrient',     @stub_estOrient);
M.estFreq       = pick('estFreq',       @stub_estFreq);
M.postprocess   = pick('postprocess',   @stub_postprocess);
M.matchMinutiae = pick('matchMinutiae', @stub_matchMinutiae);
M.evalQuality   = pick('evalQuality',   @stub_evalQuality);
M.runNFIQ2      = pick('runNFIQ2',      @stub_runNFIQ2);
fmap = filterMap();

fprintf('\n--- Trạng thái mô-đun (STUB = chưa có file thật trong src/) ---\n');
mods = [fieldnames(M); cellfun(@(n) ['filter:' n], cfg.run.filters(:), 'UniformOutput', false)];
for k = 1:numel(mods)
    if startsWith(mods{k}, 'filter:')
        nm = mods{k}(8:end);  isS = strcmp(func2str(fmap.(nm)), 'stub_filter');
    else
        nm = mods{k};         isS = startsWith(func2str(M.(nm)), 'stub_');
    end
    if isS, st = 'STUB'; else, st = 'ok'; end
    fprintf('  %-20s %s\n', mods{k}, st);
end

%% 1. Ảnh sạch
imgs = loadImageList(cfg, M.prepImage);
nImg = numel(imgs);
fprintf('\nSố ảnh: %d | loại nhiễu: %s | bộ lọc: none + %s\n', nImg, ...
    strjoin(cfg.run.noiseTypes, ','), strjoin(cfg.run.filters, ','));

%% 2. Vòng lặp chính: ảnh × nhiễu × mức × bộ lọc
noiseTypes  = cfg.run.noiseTypes;
filterNames = ['none', cfg.run.filters];     % 'none' = mốc không lọc
nLv = cfg.noise.nLevels;
mI = cfg.eval.match; mI.useType = false;     % khớp bỏ qua loại minutiae
mT = cfg.eval.match; mT.useType = true;      % khớp có xét loại

rec = struct('image',{}, 'noise',{}, 'level',{}, 'filter',{}, 'psnr',{}, 'ssim',{}, ...
             'P',{}, 'R',{}, 'F1',{}, 'F1type',{}, 'nfiq2',{}, 'time',{});

for i = 1:nImg
    clean = imgs(i).I;
    mask  = M.roiMask(clean, cfg.mask);
    minuRef = M.postprocess(clean, mask, cfg.post);
    if cfg.run.oracleOrient
        thetaOr = M.estOrient(clean, mask, cfg.orient);
        freqOr  = M.estFreq(clean, mask, thetaOr, cfg.freq);
    end
    fprintf('[%d/%d] %s\n', i, nImg, imgs(i).name);

    for t = 1:numel(noiseTypes)
        ntype   = noiseTypes{t};
        typeIdx = find(strcmp(cfg.noise.typesAll, ntype), 1);
        for lv = 1:nLv
            noisy = M.addNoise(clean, ntype, lv, cfg.seedFor(i, typeIdx, lv));
            if cfg.run.oracleOrient
                theta = thetaOr;  freq = freqOr;
            else
                theta = M.estOrient(noisy, mask, cfg.orient);
                freq  = M.estFreq(noisy, mask, theta, cfg.freq);
            end

            for f = 1:numel(filterNames)
                fname = filterNames{f};
                if strcmp(fname, 'none')
                    tic; Ienh = noisy; dt = toc;
                else
                    fh = fmap.(fname);
                    tic; Ienh = fh(noisy, mask, theta, freq, cfg.filters.(fname)); dt = toc;
                end
                Ienh = checkOutput(Ienh, noisy, fname);

                q = M.evalQuality(Ienh, clean, mask);
                minuEnh = M.postprocess(Ienh, mask, cfg.post);
                [P, R, F1]  = M.matchMinutiae(minuEnh, minuRef, mI);
                [~, ~, F1t] = M.matchMinutiae(minuEnh, minuRef, mT);
                nf = NaN;
                if cfg.eval.useNFIQ2, nf = M.runNFIQ2(Ienh, cfg.eval.nfiq2); end

                rec(end+1) = struct('image', imgs(i).name, 'noise', ntype, 'level', lv, ...
                    'filter', fname, 'psnr', q.psnr, 'ssim', q.ssim, 'P', P, 'R', R, ...
                    'F1', F1, 'F1type', F1t, 'nfiq2', nf, 'time', dt); %#ok<SAGROW>
            end
        end
    end
end

%% 3. Bảng kết quả
T = struct2table(rec);
T.image = string(T.image);  T.noise = string(T.noise);  T.filter = string(T.filter);
writetable(T, fullfile(outDir, 'raw_results.csv'));

G = groupsummary(T, {'filter','noise','level'}, {'mean','std'}, {'psnr','ssim','F1','time'});
tableName = 'summary_table.csv';
if strcmp(stage, 'M1'), tableName = 'baseline_table.csv'; end
writetable(G, fullfile(outDir, tableName));
fprintf('\n--- Tóm tắt (trung bình ± std theo ảnh) ---\n');
disp(G);

fprintf('\nXong sau %.1f s. Kết quả: %s\n', toc(tStart), outDir);
fprintf('Nếu stage = M1 và pipeline ổn: git tag M1\n');

%% ===================== Hàm cục bộ =====================
function fh = pick(name, stubHandle)
% File thật trên path thì dùng file thật, không thì dùng stub.
if exist(name, 'file') == 2, fh = str2func(name); else, fh = stubHandle; end
end

function m = filterMap()
% Tên bộ lọc → function handle (file thật hoặc stub). Thêm bộ lọc mới: thêm 1 dòng
% ở đây + cfg.filters.<tên> trong config.m. Chữ ký: I_enh = filterX(I,mask,theta,freq,params)
names = struct('mean','filterMean', 'gauss','filterGauss', 'median','filterMedian', ...
               'wiener','filterWiener', 'butter','filterButter', 'notch','filterNotch', ...
               'firw','filterFIRW', 'gabor','filterGabor', 'stft','filterSTFT');
f = fieldnames(names);
for k = 1:numel(f)
    m.(f{k}) = pick(names.(f{k}), @stub_filter);
end
end

function imgs = loadImageList(cfg, prepFn)
% Đọc danh sách ảnh (cột 'file' trong CSV). Chưa có dữ liệu → ảnh vân giả.
imgs = struct('name', {}, 'I', {});
listFile = cfg.data.lists.(cfg.run.imageSet);
if exist(listFile, 'file')
    T = readtable(listFile, 'TextType', 'string');
    if ~ismember('file', T.Properties.VariableNames)
        error('run_all:list', '%s phải có cột "file"', listFile);
    end
    n = min(height(T), cfg.run.maxImages);
    for k = 1:n
        p = fullfile(cfg.paths.raw, char(T.file(k)));
        if exist(p, 'file')
            imgs(end+1).name = char(T.file(k)); %#ok<AGROW>
            imgs(end).I = prepFn(p, cfg.prep);
        else
            warning('run_all:missing', 'Không thấy ảnh: %s', p);
        end
    end
end
if isempty(imgs)
    if ~cfg.run.useDummyIfNoData
        error('run_all:nodata', 'Không có ảnh nào. Kiểm tra data/raw và %s', listFile);
    end
    warning('run_all:dummy', 'Chưa có dữ liệu thật: dùng ảnh vân giả để chạy thử pipeline.');
    for k = 1:min(3, cfg.run.maxImages)
        imgs(end+1).name = sprintf('dummy_%d', k); %#ok<AGROW>
        imgs(end).I = makeDummyClean(k);
    end
end
end

function I = makeDummyClean(k)
% Ảnh vân giả 256x256, chu kỳ ~9 px (chỉ dùng khi chưa có dữ liệu thật).
[X, Y] = meshgrid(1:256, 1:256);
r = sqrt((X-128).^2 + ((Y-150-5*k)/1.4).^2);
I = 0.5 + 0.45*cos(2*pi*r/9 + 0.8*sin(X/37 + k));
I = min(max(I, 0), 1);
end

function Ienh = checkOutput(Ienh, I, fname)
% Kiểm tra bộ lọc đúng hợp đồng (CONVENTIONS mục 3) rồi cắt về [0,1].
assert(isequal(size(Ienh), size(I)), 'run_all:badSize', ...
    'Bộ lọc %s trả sai kích thước', fname);
assert(isa(Ienh, 'double') && ~any(isnan(Ienh(:))), 'run_all:badValue', ...
    'Bộ lọc %s trả về kiểu không phải double hoặc có NaN', fname);
Ienh = min(max(Ienh, 0), 1);
end

%% ===================== STUB (thay bằng file thật trong src/) =====================
function I = stub_prepImage(src, ~)          % A2: src = đường dẫn hoặc ma trận
if ischar(src) || isstring(src), I = imread(src); else, I = src; end
if size(I, 3) == 3, I = rgb2gray(I); end
I = im2double(I);
end

function mask = stub_roiMask(I, ~)           % A2
mask = true(size(I));
end

function In = stub_addNoise(clean, ~, level, seed)   % A3: nhiễu cộng đơn giản
rng(seed, 'twister');
In = min(max(clean + 0.05*level*randn(size(clean)), 0), 1);
end

function [theta, coh] = stub_estOrient(I, ~, ~)      % A4
theta = zeros(size(I));
coh   = ones(size(I));
end

function freq = stub_estFreq(I, ~, ~, params)        % A4
freq = params.default * ones(size(I));
end

function I_enh = stub_filter(I, ~, ~, ~, ~)          % A5/A6/A7: trả lại ảnh vào
I_enh = I;
end

function [minu, skel] = stub_postprocess(I, ~, ~)    % A8
minu = zeros(0, 4);
skel = false(size(I));
end

function [P, R, F1, nMatch] = stub_matchMinutiae(~, ~, ~)   % A8
P = NaN; R = NaN; F1 = NaN; nMatch = 0;
end

function q = stub_evalQuality(I_enh, I_ref, mask)    % A8: PSNR/SSIM thật, trong ROI
if nargin < 3 || isempty(mask), mask = true(size(I_ref)); end
mse = mean((I_enh(mask) - I_ref(mask)).^2);
q.psnr = 10*log10(1 / max(mse, eps));
[~, smap] = ssim(I_enh, I_ref);
q.ssim = mean(smap(mask));
end

function score = stub_runNFIQ2(~, ~)                 % A8
score = NaN;
end
