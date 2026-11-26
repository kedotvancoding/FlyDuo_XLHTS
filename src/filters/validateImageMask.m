function validateImageMask(I, mask, theta, freq)
% Validate common FLYDUO contract; orientation/frequency optional for baselines.
    if ~isa(I,'double') || ~ismatrix(I) || ~isreal(I) || ...
            any(~isfinite(I(:))) || any(I(:)<0) || any(I(:)>1)
        error('FLYDUO:Image','I must be finite real double in [0,1].');
    end
    if ~isequal(size(I),size(mask)) || ...
            ~(islogical(mask) || isnumeric(mask)) || ...
            any(~isfinite(double(mask(:)))) || ...
            any(double(mask(:))~=0 & double(mask(:))~=1)
        error('FLYDUO:Mask','mask must be binary and same size as I.');
    end
    if nargin >= 3 && ~isempty(theta)
        if ~isnumeric(theta) || ~isreal(theta) || ...
                ~isequal(size(I),size(theta)) || ...
                any(~isfinite(theta(:))) || any(theta(:)<0) || any(theta(:)>=pi)
            error('FLYDUO:Theta','theta must be real finite, [0,pi), same size as I.');
        end
    end
    if nargin >= 4 && ~isempty(freq)
        if ~isnumeric(freq) || ~isreal(freq) || ...
                ~isequal(size(I),size(freq)) || ...
                any(~isfinite(freq(:))) || any(freq(:)<0) || any(freq(:)>0.5)
            error('FLYDUO:Frequency','freq must be real finite, [0,0.5] cycles/pixel, same size as I.');
        end
    end
end
