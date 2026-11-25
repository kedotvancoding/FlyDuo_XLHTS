function [minu, skel] = postprocess(I, mask, params)
    I = double(I);
    [H, W] = size(I);

    if nargin < 2 || isempty(mask)
        mask = true(H, W);
    else
        mask = logical(mask);
    end

    if nargin < 3 || isempty(params)
        params = struct();
    end
    if isfield(params, 'margin'),  margin  = params.margin;  else, margin  = 16; end
    if isfield(params, 'spurLen'), spurLen = params.spurLen; else, spurLen = 10; end

    % 1. Nhi phan hoa thich nghi (van la vung toi -> dao bit de van = true)
    T = adaptthresh(I, 0.5, 'ForegroundPolarity', 'dark');
    bw = ~imbinarize(I, T);
    bw = bw & mask;

    % Lam sach nhieu hat nho va lo kim 1-2 px truoc khi lam manh
    bw = bwareaopen(bw, 10);
    bw = ~bwareaopen(~bw, 5) & mask;

    % 2. Lam manh (thinning) thanh xuong van rong 1 px
    skel = bwmorph(bw, 'thin', Inf);

    % 3. Loai bo doan van roi rac va nhanh cut ngan hon spurLen
    if spurLen > 0
        skel = removeShortSpurs(skel, spurLen);
    end

    % 4. Tinh Crossing Number (Rutovitz CN) tren anh xuong van
    S = double(skel);
    CN = zeros(H, W);
    if H >= 3 && W >= 3
        P1 = S(2:end-1, 3:end);
        P2 = S(1:end-2, 3:end);
        P3 = S(1:end-2, 2:end-1);
        P4 = S(1:end-2, 1:end-2);
        P5 = S(2:end-1, 1:end-2);
        P6 = S(3:end,   1:end-2);
        P7 = S(3:end,   2:end-1);
        P8 = S(3:end,   3:end);
        CN(2:end-1, 2:end-1) = 0.5 * ( ...
            abs(P1 - P2) + abs(P2 - P3) + abs(P3 - P4) + abs(P4 - P5) + ...
            abs(P5 - P6) + abs(P6 - P7) + abs(P7 - P8) + abs(P8 - P1));
        CN(~skel) = 0;
    end

    % 5. Tao mat na loai minutiae sat bien anh va sat bien ROI (margin px)
    distToBg = bwdist(~mask);
    [rowGrid, colGrid] = ndgrid(1:H, 1:W);
    validMask = (distToBg > margin) & ...
                (rowGrid > margin) & (rowGrid <= H - margin) & ...
                (colGrid > margin) & (colGrid <= W - margin);

    endMask = (CN == 1) & validMask;
    bifMask = (CN == 3) & validMask;

    % 6. Uoc luong goc theta theo quy uoc CONVENTIONS muc 2 (Sobel + goc kep)
    [gx, gy] = imgradientxy(I, 'sobel');
    Gxx = imgaussfilt(gx .^ 2, 4);
    Gyy = imgaussfilt(gy .^ 2, 4);
    Gxy = imgaussfilt(gx .* gy, 4);
    thetaMap = mod(0.5 * atan2(2 * Gxy, Gxx - Gyy), pi);

    % 7. Gom ket qua thanh ma tran Nx4: [x y theta type]
    [yEnd, xEnd] = find(endMask);
    [yBif, xBif] = find(bifMask);

    idxEnd = sub2ind([H, W], yEnd, xEnd);
    idxBif = sub2ind([H, W], yBif, xBif);

    minuEnd = [xEnd, yEnd, thetaMap(idxEnd), ones(numel(xEnd), 1)];
    minuBif = [xBif, yBif, thetaMap(idxBif), 2 * ones(numel(xBif), 1)];

    minu = [minuEnd; minuBif];
    if isempty(minu)
        minu = zeros(0, 4);
    end
end

function skelOut = removeShortSpurs(skelIn, spurLen)
    % Bo cac doan van co lap ngan hon spurLen
    skelOut = bwareaopen(skelIn, spurLen);

    % Cat cac nhanh cut noi voi diem chac (branchpoint) co do dai < spurLen
    bp = bwmorph(skelOut, 'branchpoints');
    ep = bwmorph(skelOut, 'endpoints');
    branches = skelOut & ~bp;

    cc = bwconncomp(branches, 8);
    for k = 1:cc.NumObjects
        pix = cc.PixelIdxList{k};
        if numel(pix) < spurLen && any(ep(pix))
            skelOut(pix) = false;
        end
    end

    % Lam manh lai 1 luot de xoa pixel thua quanh diem chac cu
    skelOut = bwmorph(skelOut, 'thin', Inf);
    skelOut = bwareaopen(skelOut, spurLen);
end
