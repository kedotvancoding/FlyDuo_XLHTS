function I_enh = filterMedian(I_noisy, mask, theta, freq, params)
% FILTERMEDIAN Median 2D baseline (nonlinear).
% params.kernelSize: positive odd integer (default 3)
    if nargin < 5 || isempty(params), params = struct(); end
    if ~isfield(params,'kernelSize'), params.kernelSize = 3; end
    N = params.kernelSize;
    if ~isscalar(N) || N < 1 || mod(N,2) ~= 1 || N ~= floor(N)
        error('filterMedian:kernelSize','kernelSize must be positive odd integer.');
    end
    validateImageMask(I_noisy, mask, theta, freq);
    filtered = medfilt2(I_noisy,[N N],'symmetric');
    I_enh = combineROI(I_noisy,filtered,mask);
end
