function q = evalQuality(I_enh, I_ref, mask)
    I_enh = double(I_enh);
    I_ref = double(I_ref);

    if ~isequal(size(I_enh), size(I_ref))
        error('evalQuality:SizeMismatch', 'I_enh va I_ref phai cung kich thuoc.');
    end

    if nargin < 3 || isempty(mask)
        mask = true(size(I_ref));
    else
        mask = logical(mask);
        if ~isequal(size(mask), size(I_ref))
            error('evalQuality:MaskSizeMismatch', 'mask phai cung kich thuoc voi anh.');
        end
    end

    if ~any(mask(:))
        q.psnr = NaN;
        q.ssim = NaN;
        return;
    end

    % Tinh MSE va PSNR trong vung ROI (anh thang [0, 1])
    diffVal = I_enh(mask) - I_ref(mask);
    mseVal = mean(diffVal .^ 2);
    if mseVal == 0
        q.psnr = Inf;
    else
        q.psnr = 10 * log10(1 / mseVal);
    end

    % Tinh SSIM trung binh tren vung ROI
    [~, ssimMap] = ssim(I_enh, I_ref, 'DynamicRange', 1);
    q.ssim = mean(ssimMap(mask));
end
