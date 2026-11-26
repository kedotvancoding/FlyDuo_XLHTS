function I_enh = filterGauss(I_noisy, mask, theta, freq, params)
% FILTERGAUSS Gaussian 2D baseline.
% params.kernelSize: odd positive integer (default 5)
% params.sigma: Gaussian std in pixels (default 1)
    if nargin < 5 || isempty(params), params = struct(); end
    if ~isfield(params,'kernelSize'), params.kernelSize = 5; end
    if ~isfield(params,'sigma'), params.sigma = 1; end
    N = params.kernelSize;
    sigma = params.sigma;
    if ~isscalar(N) || N < 1 || mod(N,2) ~= 1 || N ~= floor(N)
        error('filterGauss:kernelSize','kernelSize must be positive odd integer.');
    end
    if ~isscalar(sigma) || ~isfinite(sigma) || sigma <= 0
        error('filterGauss:sigma','sigma must be positive.');
    end
    validateImageMask(I_noisy, mask, theta, freq);
    coords = -(N-1)/2:(N-1)/2;
    [X,Y] = meshgrid(coords,coords);
    kernel = exp(-(X.^2+Y.^2)/(2*sigma^2));
    kernel = kernel/sum(kernel(:));
    filtered = imfilter(I_noisy,kernel,'symmetric','same','conv');
    I_enh = combineROI(I_noisy,filtered,mask);
end
