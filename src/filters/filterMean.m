function I_enh = filterMean(I_noisy, mask, theta, freq, params)
% FILTERMEAN Mean 2D baseline with common FLYDUO interface.
% params.kernelSize: 3 or 5 (default 3)
    if nargin < 5 || isempty(params), params = struct(); end
    if ~isfield(params,'kernelSize'), params.kernelSize = 3; end
    N = params.kernelSize;
    if ~isscalar(N) || ~ismember(N,[3 5])
        error('filterMean:kernelSize','kernelSize must be 3 or 5.');
    end
    validateImageMask(I_noisy, mask, theta, freq);
    kernel = ones(N,N)/(N*N);
    filtered = imfilter(I_noisy,kernel,'symmetric','same','conv');
    I_enh = combineROI(I_noisy,filtered,mask);
end
