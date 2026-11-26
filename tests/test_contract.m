% Automated interface, ROI, constant-signal, FIR symmetry / freqz tests.
clear; clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src','filters'));
rng(101,'twister');
I = rand(32,40);
mask = false(size(I)); mask(5:28,6:34)=true;
theta = zeros(size(I)); freq=0.10*ones(size(I));
M = {@()filterMean(I,mask,theta,freq,struct('kernelSize',3)), ...
     @()filterMean(I,mask,theta,freq,struct('kernelSize',5)), ...
     @()filterGauss(I,mask,theta,freq,struct('kernelSize',5,'sigma',1)), ...
     @()filterMedian(I,mask,theta,freq,struct('kernelSize',3)), ...
     @()filterWiener(I,mask,theta,freq,struct('kernelSize',5))};
for k=1:numel(M)
    O=M{k}();
    assert(isequal(size(O),size(I)) && isa(O,'double'));
    assert(all(isfinite(O(:))) && all(O(:)>=0) && all(O(:)<=1));
    assert(isequal(O(~mask),I(~mask)), 'Pixels outside ROI must be unchanged');
end
one = ones(32,40)*0.45; fullmask=true(size(one));
O1=filterMean(one,fullmask,[],[],struct('kernelSize',3));
O2=filterMean(one,fullmask,[],[],struct('kernelSize',5));
O3=filterGauss(one,fullmask,[],[],struct('kernelSize',5,'sigma',1));
assert(max(abs(O1(:)-0.45))<1e-12);
assert(max(abs(O2(:)-0.45))<1e-12);
assert(max(abs(O3(:)-0.45))<1e-12);
windows={'rectangular','bartlett','hann','hamming','blackman'};
for N=[9 15 21 31]
    for k=1:numel(windows)
        [h,info]=designBP(N,0.06,0.15,windows{k});
        assert(all(isfinite(h)) && numel(h)==N);
        assert(max(abs(h-flipud(h)))<1e-12);
        Hcenter=freqz(h,1,2*pi*info.fCenter);
        assert(abs(abs(Hcenter)-1)<1e-8);
    end
end
fprintf('PASS: 5 baseline configs, ROI, constants, 20 FIR designs, freqz.\n');
