function [h, info] = designBP(N, fLow, fHigh, windowType)
% DESIGNBP Window-method 1D FIR bandpass filter, frequencies cycles/pixel.
% [h,info] = designBP(N,fLow,fHigh,windowType)
% N odd: 9,15,21,31. 0 < fLow < fHigh < 0.5 cycles/pixel.
% windowType: 'rectangular','bartlett','hann','hamming','blackman'.
% h[n] = h_ideal[n] * w[n], with center-frequency gain normalized to 1.
    if ~isscalar(N) || ~ismember(N,[9 15 21 31])
        error('designBP:N','N must be one of 9,15,21,31.');
    end
    if ~isscalar(fLow) || ~isscalar(fHigh) || ~isfinite(fLow) ...
            || ~isfinite(fHigh) || fLow<=0 || fHigh>=0.5 || fLow>=fHigh
        error('designBP:Frequencies','Require 0 < fLow < fHigh < 0.5 cycles/pixel.');
    end
    t = (-(N-1)/2:(N-1)/2).';
    % MATLAB sinc(x) = sin(pi*x)/(pi*x).
    hIdeal = 2*fHigh*sinc(2*fHigh*t) - 2*fLow*sinc(2*fLow*t);
    switch lower(char(windowType))
        case {'rectangular','rect','boxcar'}
            w = ones(N,1);
            name = 'rectangular';
        case 'bartlett'
            w = 1-abs(2*t/(N-1));
            name = 'bartlett';
        case {'hann','hanning'}
            w = 0.5+0.5*cos(2*pi*t/(N-1));
            name = 'hann';
        case 'hamming'
            w = 0.54+0.46*cos(2*pi*t/(N-1));
            name = 'hamming';
        case 'blackman'
            w = 0.42+0.5*cos(2*pi*t/(N-1))+0.08*cos(4*pi*t/(N-1));
            name = 'blackman';
        otherwise
            error('designBP:Window','Unknown window: %s',char(windowType));
    end
    h = hIdeal.*w;
    fCenter = (fLow+fHigh)/2;
    gainCenter = abs(sum(h.*exp(-1i*2*pi*fCenter*(0:N-1).')));
    if gainCenter < 1e-10
        error('designBP:SmallGain','Too small center-frequency gain. Increase N or band width.');
    end
    h = h/gainCenter;
    info = struct('phaseDelaySamples',(N-1)/2,'N',N,'fLow',fLow,'fHigh',fHigh,'fCenter',fCenter, ...
                  'windowType',name,'window',w,'hIdeal',hIdeal,'gainCenterBeforeNormalization',gainCenter);
end
