close all, clc;

%number of available data points
N = 2000;
k = 0:N-1;

f0 = 0.24;
f1 = 0.245:0.005:0.26;
nbins = 500;
nsig = 2;
nmethods = 5;
L = length(f1);
M = zeros(L,1);
t = zeros(L, nmethods);
err = zeros(L,nmethods);
freqs = zeros(L, nmethods, 2*nsig);
sig_freqs = zeros(L, 2*nsig);
f = zeros(1,2*nsig);
snr = 10;
x = zeros(L,N);

%frequencies detected by MUSIC with basic QR
for n = 1:L
    y = cos(2*f0*pi.*k) + 0.5*cos(2*f1(n)*pi.*k + 0.25*pi);
    %normalize signal power to 0dB
    y_norm = y./max(abs(y));
    %signal+noise
    x(n,:) = awgn(y_norm, snr);
    R = estimate_autocorrelation_function(x(n,:), N/2, 'fft');
    M(n) = find_periodicity(R,0.05);
    sig_freqs(n,:) = [-f1(n),f0,f0,f1(n)]*2*pi;
end

for n = 1:L
    tic;
    freqs(n,1,:) = music(x(n,:), nsig, nbins, 'gram_schmidt','fft',M(n));
    t(n,1) = toc;
    f(1,:) = freqs(n,1,:);
    err(n,1) = norm(sort(f) - sig_freqs(n,:));
end

%this is needed so all variables used by the function are cleared
clearvars -except x nbins nsig nmethods t err sig_freqs snr M freqs f L f1 

%frequencies detected by MUSIC with hessenberg QR 
for n = 1:L
    tic;
    freqs(n,2,:) = music(x(n,:), nsig, nbins, 'hess','fft',M(n));
    t(n,2) = toc;
    f(1,:) = freqs(n,2,:);
    err(n,2) = norm(sort(f) - sig_freqs(n,:));
end

clearvars -except x nbins nsig nmethods t err sig_freqs snr M freqs f L f1

for n = 1:L
    tic;
    freqs(n,3,:) = music(x(n,:), nsig, nbins, 'implicit','fft',M(n));
    t(n,3) = toc;
    f(1,:) = freqs(n,3,:);
    err(n,3) = norm(sort(f) - sig_freqs(n,:));
end

clearvars -except x nbins nsig nmethods t err sig_freqs snr M freqs f L f1

%frequencies detected by fast_MUSIC with fft
for n = 1:L
    tic;
    freqs(n,4,:) = fast_music(x(n,:), nsig, nbins, 'fft', 'fft',M(n));
    t(n,4) = toc;
    f(1,:) = freqs(n,4,:);
    err(n,4) = norm(sort(f) - sig_freqs(n,:));
end

clearvars -except x nbins nsig nmethods t err sig_freqs snr M freqs f L f1

%frequencies detected by fast_MUSIC with dft
for n = 1:L
    tic;
    %freqs(n,5,:) = fast_music(x, nsig, nbins(n), 'dft', 'fft');
    freqs(n,5,:) = fast_music(x(n,:), nsig, nbins, 'dft', 'fft',M(n));
    t(n,5) = toc;
    f(1,:) = freqs(n,5,:);
    err(n,5) = norm(sort(f) - sig_freqs(n,:));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%plot computation time and MSE plots
figure;
for k = 1:nmethods
    %plot(nbins, t(:,k));hold on;grid on;
    plot(M, fliplr(log(t(:,k))));hold on;grid on;
end
hold off;
xlabel('Order of autocorrelation matrix');
%xlabel('Number of bins in search space');
ylabel('Time in seconds (log)');
legend('MUSIC basic QR','MUSIC hess QR','MUSIC implicit QR', ...
    'fast MUSIC fft','fast MUSIC dft');
%title(strcat('Order of autocorrelation matrix =', num2str(M)));
title(strcat('Number of bins in search space =', num2str(nbins)));

figure;
for k = 1:nmethods
    %plot(nbins, log10(err(:,k)+eps));hold on;grid on;
    plot(M, fliplr(log10(err(:,k)+eps)));hold on;grid on;
end
hold off;
%xlabel('Number of bins in search space');
xlabel('Order of autocorrelation matrix');
ylabel('Mean squared error in Hz (log_{10})');
legend('MUSIC basic QR','MUSIC hess QR','MUSIC implicit QR', ...
    'fast MUSIC fft','fast MUSIC dft');
%title(strcat('Order of autocorrelation matrix =', num2str(M)));
title(strcat('Number of bins in search space =', num2str(nbins)));