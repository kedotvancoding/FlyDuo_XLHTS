function score = runNFIQ2(I, params)
    score = NaN;

    if nargin < 2 || isempty(params)
        params = struct('exe', '');
    end

    if isfield(params, 'exe') && ~isempty(params.exe)
        exeCmd = char(params.exe);
    else
        exeCmd = 'nfiq2';
    end

    % Xac dinh duong dan file anh dau vao
    if ischar(I) || isstring(I)
        imgPath = char(I);
        if ~isfile(imgPath)
            error('runNFIQ2:FileNotFound', 'Khong tim thay file anh: %s', imgPath);
        end
    else
        img = double(I);
        if size(img, 3) == 3
            img = rgb2gray(img);
        end
        imgU8 = im2uint8(min(max(img, 0), 1));

        % Ghi file tam PNG chuan 500 DPI (500 / 0.0254 ~= 19685 px/m)
        imgPath = [tempname, '.png'];
        resPerMeter = round(500 / 0.0254);
        imwrite(imgU8, imgPath, 'png', ...
            'ResolutionUnit', 'meter', ...
            'XResolution', resPerMeter, ...
            'YResolution', resPerMeter);
        cleanupObj = onCleanup(@() deleteTempFile(imgPath)); %#ok<NASGU>
    end

    % Goi lenh he thong (co -F bo qua loi thieu metadata DPI)
    if isfile(exeCmd)
        cmd = sprintf('"%s" -F "%s"', exeCmd, imgPath);
    else
        cmd = sprintf('%s -F "%s"', exeCmd, imgPath);
    end

    [status, rawOut] = system(cmd);
    if status ~= 0
        warning('runNFIQ2:ExecFailed', ...
            'Loi chay NFIQ2 (ma %d): %s', status, strtrim(rawOut));
        return;
    end

    % Trich xuat so diem tu dau ra stdout
    tokens = regexp(strtrim(rawOut), '(\d+)', 'tokens');
    if ~isempty(tokens)
        val = str2double(tokens{end}{1});
        if ~isnan(val) && val >= 0 && val <= 100
            score = val;
        end
    end
end

function deleteTempFile(filepath)
    if isfile(filepath)
        delete(filepath);
    end
end
