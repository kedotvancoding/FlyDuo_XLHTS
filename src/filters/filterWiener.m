function I_enh = filterWiener(I_noisy, mask, theta, freq, params)
% FILTERWIENER Local adaptive Wiener 2D baseline.
% params.kernelSize: positive odd integer (default 5)
% params.noiseVariance: optional scalar variance; omit for automatic estimate
    if nargin < 5 || isempty(params), params = struct(); end
    if ~isfield(params,'kernelSize'), params.kernelSize = 5; end
    N = params.kernelSize;
    if ~isscalar(N) || N < 1 || mod(N,2) ~= 1 || N ~= floor(N)
        error('filterWiener:kernelSize','kernelSize must be positive odd integer.');
    end
    validateImageMask(I_noisy, mask, theta, freq);
    if isfield(params,'noiseVariance') && ~isempty(params.noiseVariance)
        noiseVar = params.noiseVariance;
        if ~isscalar(noiseVar) || ~isfinite(noiseVar) || noiseVar < 0
            error('filterWiener:noiseVariance','noiseVariance must be nonnegative.');
        end
        filtered = wiener2(I_noisy,[N N],noiseVar);
    else
        filtered = wiener2(I_noisy,[N N]);
    end
    I_enh = combineROI(I_noisy,filtered,mask);
end
