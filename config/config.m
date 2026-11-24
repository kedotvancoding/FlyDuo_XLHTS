%% system
clc;
clear;
close all;

%% ---
function cfg = config(stage)
%CONFIG  Tham số chung của dự án FlyDuo (nguồn duy nhất của mọi con số).
%   cfg = config()        stage mặc định 'M1'
%   cfg = config('M2')    stage ∈ {'M1','M2','FINAL'}
%
%   Mục có chữ TODO là giá trị tạm, người phụ trách cập nhật sau khi đo/chốt.
%   Người phụ trách: A1

if nargin < 1 || isempty(stage), stage = 'M1'; end

%% 1. Đường dẫn và dữ liệu
cfg.paths.root    = fileparts(fileparts(mfilename('fullpath')));
cfg.paths.raw     = fullfile(cfg.paths.root, 'data', 'raw');
cfg.paths.lists   = fullfile(cfg.paths.root, 'data', 'lists');
cfg.paths.results = fullfile(cfg.paths.root, 'results');

cfg.data.lists.tuning = fullfile(cfg.paths.lists, 'tuning.csv');
cfg.data.lists.test   = fullfile(cfg.paths.lists, 'test.csv');
cfg.data.nTuning = 10;
cfg.data.nTest   = 30;

%% 2. Seed (xem CONVENTIONS mục 4)
cfg.seed = 2026;
base = cfg.seed;
cfg.seedFor = @(imgIdx, typeIdx, level) base + 10000*imgIdx + 100*typeIdx + level;

%% 3. Chuẩn hoá ảnh và ROI (A2)  — TODO: A2 chỉnh sau khi xem dữ liệu thật
cfg.prep.normalize  = true;
cfg.prep.meanTarget = 0.5;
cfg.prep.stdTarget  = 0.2;
cfg.mask.blockSize  = 16;
cfg.mask.stdThresh  = 0.10;

%% 4. Hướng và tần số (A4)
cfg.orient.blockSize   = 16;    % khối cộng gradient
cfg.orient.smoothSigma = 8;     % px, làm mượt trên (cos2θ, sin2θ)
cfg.freq.default = 1/9;         % chu kỳ vân ~9 px (500 dpi)
cfg.freq.range   = [1/15, 1/5]; % TODO: A2/A4 đo lại từ dữ liệu

%% 5. Nhiễu (A3) — mỗi loại 3 mức
cfg.noise.nLevels   = 3;
cfg.noise.typesV1   = {'awgn','saltpepper','speckle'};                       % M1
cfg.noise.typesGrid = [cfg.noise.typesV1, {'blur','background','periodic'}]; % lưới chính
cfg.noise.typesAll  = [cfg.noise.typesGrid, {'dry'}];                        % thêm nhiễu khô

cfg.noise.awgn.levels       = [0.05 0.10 0.20];   % độ lệch chuẩn σ
cfg.noise.saltpepper.levels = [0.02 0.05 0.10];   % tỉ lệ pixel bị nhiễu
cfg.noise.speckle.levels    = [0.04 0.10 0.20];   % phương sai (nhiễu nhân)
cfg.noise.blur.levels       = [1 2 3];            % σ Gaussian (px)
cfg.noise.blur.contrast     = [0.85 0.70 0.55];   % TODO: hệ số giảm tương phản
cfg.noise.background.levels = [0.2 0.4 0.6];      % biên độ thành phần tần số thấp
cfg.noise.periodic.levels   = [0.10 0.20 0.30];   % TODO: chốt ở M1 (biên độ sóng sin)
cfg.noise.periodic.fIn      = 0.11;               % sóng trong vành tần số vân
cfg.noise.periodic.fOut     = 0.30;               % sóng ngoài vành
cfg.noise.periodic.angle    = pi/4;
cfg.noise.dry.levels        = [0.10 0.20 0.30];   % TODO: chốt ở M1 (tỉ lệ mặt nạ làm đứt vân)

%% 6. Bộ lọc — params truyền thẳng vào filterX (A5, A6, A7)
cfg.filters.mean   = struct('size', 5);
cfg.filters.gauss  = struct('sigma', 1.0);
cfg.filters.median = struct('size', 3);
cfg.filters.wiener = struct('size', 5);
cfg.filters.butter = struct('order', 4, 'fc', 0.20);           % fc: chu kỳ/pixel
cfg.filters.notch  = struct('nPeaks', 4, 'radius', 3, ...
                            'ringBand', [0.06 0.20], 'peakThresh', 6);
cfg.filters.firw   = struct('window', 'hamming', 'N', 21, 'nTheta', 16, ...
                            'bpRel', 0.4, 'lpCut', 0.05);      % TODO: tune
cfg.filters.gabor  = struct('nTheta', 16, 'nFreq', 9, 'sigmaK', 5/12, ...
                            'freqRange', cfg.freq.range);      % σ = sigmaK/f
cfg.filters.stft   = struct('W', 32, 'hopRatio', 0.25, 'order', 4, ...
                            'angBW', pi/6);                    % TODO: tune

cfg.baselines   = {'mean','gauss','median','butter'};  % TODO: A1+A5 chốt ở M1 (docs/baseline_choice.md)
cfg.mainFilters = {'firw','gabor','stft'};

%% 7. Hậu xử lý và đánh giá (A8)
cfg.post.margin  = 16;    % px, bỏ minutiae sát biên
cfg.post.spurLen = 10;    % px, bỏ nhánh cụt ngắn hơn
cfg.eval.match   = struct('dist', 14, 'angle', pi/9, 'useType', false);
cfg.eval.useNFIQ2 = false;                  % bật khi đã cài NFIQ2 (docs/nfiq2_setup.md)
cfg.eval.nfiq2    = struct('exe', '');

%% 8. Ablation (A1 điều phối)
cfg.ablation.windows     = {'rect','bartlett','hann','hamming','blackman'};
cfg.ablation.N           = [9 15 21 31];
cfg.ablation.nTheta      = [8 16 32];
cfg.ablation.stftW       = [16 32 48];
cfg.ablation.stftHop     = [0.25 0.5];
cfg.ablation.butterOrder = [2 4 6 8];
cfg.ablation.stftOrder   = [2 4 6];

%% 9. Cấu hình chạy theo stage
cfg.run.stage            = stage;
cfg.run.oracleOrient     = false;   % true: lấy θ, f từ ảnh sạch (ablation oracle)
cfg.run.useDummyIfNoData = true;    % chưa có ảnh thật → dùng ảnh vân giả để pipeline vẫn chạy
switch stage
    case 'M1'      % tuần 1: baseline, nhiễu bản 1
        cfg.run.imageSet   = 'tuning';
        cfg.run.maxImages  = 10;
        cfg.run.noiseTypes = cfg.noise.typesV1;
        cfg.run.filters    = cfg.baselines;
    case 'M2'      % tuần 2: thêm ba họ lọc, đủ loại nhiễu
        cfg.run.imageSet   = 'tuning';
        cfg.run.maxImages  = 10;
        cfg.run.noiseTypes = cfg.noise.typesGrid;
        cfg.run.filters    = [cfg.baselines, cfg.mainFilters];
    case 'FINAL'   % chỉ chạy sau khi đóng băng cấu hình (tag 'freeze')
        cfg.run.imageSet   = 'test';
        cfg.run.maxImages  = cfg.data.nTest;
        cfg.run.noiseTypes = cfg.noise.typesGrid;
        cfg.run.filters    = [cfg.baselines, cfg.mainFilters];
    otherwise
        error('config:stage', 'stage không hợp lệ: %s (chọn M1, M2 hoặc FINAL)', stage);
end
cfg.run.outDir = fullfile(cfg.paths.results, stage);
end
