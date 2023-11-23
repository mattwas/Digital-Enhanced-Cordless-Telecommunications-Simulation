clear all;
%close all;
%%
snr_vec = 0:1:30;
samplesPerSymbol = 2;
samp_rate_effective = 1.728e6*samplesPerSymbol;

gmskmodulator = comm.GMSKModulator('BitInput',true, ...
                             'InitialPhaseOffset',pi/4,SamplesPerSymbol=samplesPerSymbol);
randn(1,1) + 1i*randn(1,1);
gmskdemodulator = comm.GMSKDemodulator('BitOutput',true, ...
                                 'InitialPhaseOffset',pi/4, SamplesPerSymbol=samplesPerSymbol);

errorRate = comm.ErrorRate( ...
    ReceiveDelay=gmskdemodulator.TracebackDepth);

channel_instance = 1000;

ber_vec = zeros(numel(snr_vec),channel_instance);

cnt = 1;

for snr = snr_vec


    for i=1:channel_instance 
    
        data = randi([0 1],100,1);
        data = zeros(100,1);
        modSignal = gmskmodulator(data);

        %modSignal = modSignal + 0.5*circshift(modSignal, 25);

        % flat
        % ch_coeff = randn(1,1) + 1i*randn(1,1);
        % ch_coeff = ch_coeff / sqrt(2);
        % modSignal_ch = modSignal*ch_coeff;

        T = 1/samp_rate_effective;

        % % delay spread > =
        % rayleighchan = comm.RayleighChannel( ...
        %     'SampleRate',samp_rate_effective, ...
        %     'PathDelays',T*[0 30], ...
        %     'AveragePathGains',[0 0], ...
        %     'NormalizePathGains',true, ...
        %     'MaximumDopplerShift',0, ...
        %     'DopplerSpectrum',{doppler('Gaussian',0.6)});
        % 
        % modSignal_ch = rayleighchan(modSignal);

        % % equalizer
        % tmp0 = modSignal_ch.*conj(modSignal);
        % tmp1 = sum(tmp0);
        % tmp2 = angle(tmp1);
        % modSignal_ch_equ = modSignal_ch*exp(1i*(-tmp2));
        
        % noise
        channel = comm.AWGNChannel('NoiseMethod', ...
                       'Signal to noise ratio (SNR)', ...
                       'SNR',snr-pow2db(samplesPerSymbol));
        
        noisySignal = channel(modSignal);

        receivedData = gmskdemodulator(noisySignal);
        a= errorRate(data, receivedData);
        ber_vec(cnt,i) = a(1);
        
        errorRate.reset();
    
    end
    
    cnt = cnt + 1;
    
end

ber_vec = mean(ber_vec, 2);
figure(1)
clf()
semilogy(snr_vec,ber_vec);
hold on
AA = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50];
BB = [0.21132, 0.18923, 0.16755, 0.14666, 0.12693, 0.10866, 0.092075, 0.07728, 0.064307, 0.053105, 0.043565, 0.035535, 0.028845, 0.02332, 0.01879, 0.015099, 0.012105, 0.0096873, 0.0077409, 0.0061782, 0.0049262, 0.0039249, 0.0031252, 0.0024873, 0.0019787, 0.0015737, 0.0012512, 0.00099466, 0.00079057, 0.00062828, 0.00049925, 0.00039669, 0.00031518, 0.00025041, 0.00019893, 0.00015804, 0.00012555, 9.9733e-05, 7.9226e-05, 6.2934e-05, 4.9993e-05, 3.9712e-05, 3.1545e-05, 2.5057e-05, 1.9904e-05, 1.5811e-05, 1.2559e-05, 9.976e-06, 7.9243e-06, 6.2945e-06, 4.9999e-06];
plot(AA, BB)
xlim([0,50])
ylim([1e-8,1e0])
grid on
