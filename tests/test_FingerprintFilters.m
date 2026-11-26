% TEST_A5: execute from anywhere using Run on this script.
% Demonstration image is synthetic only; it does not represent a real fingerprint.
clear; close all; clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src','filters'));
rng(1234,'twister');
[X,Y] = meshgrid(1:192,1:192);
clean = 0.5 + 0.32*cos(2*pi*(0.09*X + 0.015*sin(Y/18)));
clean = min(max(clean,0),1);
I_noisy = min(max(clean+0.12*randn(size(clean)),0),1);
mask = true(size(I_noisy));
theta = zeros(size(I_noisy)); freq = 0.09*ones(size(I_noisy));
methods = {@()filterMean(I_noisy,mask,theta,freq,struct('kernelSize',3)), ...
           @()filterMean(I_noisy,mask,theta,freq,struct('kernelSize',5)), ...
           @()filterGauss(I_noisy,mask,theta,freq,struct('kernelSize',5,'sigma',1)), ...
           @()filterMedian(I_noisy,mask,theta,freq,struct('kernelSize',3)), ...
           @()filterWiener(I_noisy,mask,theta,freq,struct('kernelSize',5))};
names = {'Mean 3x3','Mean 5x5','Gaussian','Median','Wiener'};
figure('Name','A5 baseline (synthetic stripes + AWGN)');
subplot(2,4,1); imshow(clean); title('Synthetic clean');
subplot(2,4,2); imshow(I_noisy); title('AWGN noisy');
fprintf('--- BASELINES (synthetic demo only) ---\n');
for j=1:numel(methods)
    out = methods{j}();
    assert(isequal(size(out),size(I_noisy)) && isa(out,'double'));
    assert(all(isfinite(out(:))) && all(out(:)>=0) && all(out(:)<=1));
    mse = mean((clean(:)-out(:)).^2);
    value = 10*log10(1/max(mse,eps));
    fprintf('%-12s PSNR = %6.2f dB\n',names{j},value);
    subplot(2,4,j+2); imshow(out); title(names{j});
end
fprintf('\n--- FIR: 5 windows x 4 N = 20 designs ---\n');
windows = {'rectangular','bartlett','hann','hamming','blackman'};
Ns = [9 15 21 31]; fLow=0.06; fHigh=0.15;
figure('Name','FIR freqz comparison by N');
for k=1:numel(Ns)
    subplot(2,2,k); hold on;
    for j=1:numel(windows)
        [h,info] = designBP(Ns(k),fLow,fHigh,windows{j});
        assert(numel(h)==Ns(k) && max(abs(h-flipud(h)))<1e-10);
        [H,f] = freqz(h,1,2048,1);  % fs=1 pixel^-1 => cycles/pixel
        plot(f,20*log10(max(abs(H),1e-6)),'DisplayName',info.windowType);
        [~,idx]=min(abs(f-info.fCenter));
        fprintf('N=%2d %-11s |H(fc)|=%.4f, H(0)=%.4f\n', ...
            Ns(k),info.windowType,abs(H(idx)),abs(sum(h)));
    end
    grid on; xlim([0 0.5]); ylim([-100 25]);
    xlabel('Frequency (cycles/pixel)'); ylabel('Magnitude (dB)');
    title(sprintf('N=%d (order=%d)',Ns(k),Ns(k)-1));
    if k==1, legend('show','Location','southwest'); end
end
fprintf('\nNOTE: Short N may have poor pass/stop separation.\n');
disp('A5 demonstration finished. Run tests/test_contract.m for assertions.');
