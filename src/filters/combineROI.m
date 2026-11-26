function I_enh = combineROI(I, filtered, mask)
% Outside ROI keep original image; clamp filtered values to [0,1].
    filtered = min(max(double(filtered),0),1);
    I_enh = I;
    I_enh(logical(mask)) = filtered(logical(mask));
end
