function [freqs] = music(x, nsignals, nbins, method_eig, method_autocorr,M)

%MUSIC algorithm for sinusoid parameter estimation
%x - signal corrupted with white noise
%nsignals - number of real sinusoids in signal
%nbins - number of bins in search space
%method eig - algorithm for eigenvalue decomposition
%method_autocorr - method for calculating autocorrelation function, direct
%or fft
%M - autocorrelation matrix order (ideally should be calcuated from ACF
%periodicity, but included just for plotting accuracy vs M).

if nargin == 3
    method_eig = 'default';
elseif nargin == 4
    method_autocorr = 'fft';
end

N = length(x);
%estimate autocorrelation function
R = estimate_autocorrelation_function(x, N/2, method_autocorr);

if nargin == 5
    %M is the number of antenna, or the dimension of the autocorrelation matrix
    %in our case.
    M = find_periodicity(R,0.05);
    %if signal is not periodic, or too short to be periodic
    if(M < 1)
        M = N/2;
    end
end
%get autocorrelation matrix
Rx = toeplitz(R(1:M));

%get eigenvalues

%matlab's built-in function
if strcmp(method_eig,'default')
    [eig_vec, eig_vals] = eig(Rx);
    
%my eigen decomposition function
else
    %not all methods need same number of iterations to converge
    if strcmp(method_eig,'gram_schmidt')
        niter = 50;
    elseif strcmp(method_eig,'hess')
        niter = 30;
    else
        niter = 30;
    end
    [eig_vec,eig_vals] = eig_decomp(Rx,method_eig,niter);
end

[eig_vals_sorted, inds] = sort(abs(diag(eig_vals)),'descend');

% figure;
% stem(1:M, eig_vals_sorted);hold off;
% title('Sorted eigenvalues');

%twice the number of real sinusoids
p = 2*nsignals;
noise_eigvals_pos = inds(p+1:M);
%eigenvectors spanning noise subspace
noise_eigvec = eig_vec(:,noise_eigvals_pos);
noise_subspace = noise_eigvec*noise_eigvec';

omega = linspace(0,pi,nbins);
k = 0:M-1;
P = zeros(length(omega),1);

for n = 1:length(omega);
    a = exp(1i*omega(n).*k');
    %pseudospectrum estimation
    P(n) = 1/(a'*noise_subspace*a);
end
%frequency estimates
[peaks,freqs] = find_peaks(abs(P),nsignals);
freqs = (freqs-1)*(pi/length(P));

% figure;
% plot(omega/(2*pi), abs(P));hold on;grid on;
% plot(freqs/(2*pi), peaks, '*');hold off;grid on;
% ylabel('Pseudospectrum');
% xlabel('Frequency in Hz');
% title('MUSIC');

%since the signal is real, spectrum will be symmetric
freqs = [-freqs, freqs];

end



