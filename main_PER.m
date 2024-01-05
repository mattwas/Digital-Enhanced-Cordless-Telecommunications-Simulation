clear all;
close all;

%% setup for DECT parameters

mac_meta.Configuration = '1a' ; % Configuration according to PHL
mac_meta.a = '80';       % which physical packet are we using: '00' = short packet, '32' = basic packet, '00j' = low capacity packet, '80' = high capacity packet
mac_meta.K = 0;          % in which slot (0 - 23) should the packet be transmitted
mac_meta.L = 0;          % which half slot should be used for the packet (0 for first; 1 for second)
mac_meta.M = 0;          % which RF channel
mac_meta.N = 1;          % Radio fixed Part Number (RPN)
mac_meta.s = 0;          % synchronization field (0 = normal length, 1 = prolonged)   
mac_meta.z = 0;          % z-field indicator, for collision detection (0 = no Z field, 1 = Z Field active)
mac_meta.Oversampling = 1; % oversampling
mac_meta.transmission_type = "RFP"; % Transmission Type changes the sequence of the S-Field

delay_spread = [100e-9; 150e-9];

%% setup for simulation
num_of_packets_per_snr = 1e5;
snr_db_vec_global = 0 : 1.0 : 40;
num_of_workers = numel(snr_db_vec_global);
PER_a_field_cell = cell(numel(delay_spread),numel(snr_db_vec_global),1);
PER_b_field_cell = cell(numel(delay_spread),numel(snr_db_vec_global),1);
n_bits_a_field_send = zeros(num_of_workers,1);
n_bits_a_field_error = zeros(num_of_workers,1);
n_bits_b_z_field_send = zeros(num_of_workers,1);
n_bits_b_z_field_error = zeros(num_of_workers,1);

PER_b_field_array = zeros(numel(delay_spread),size(PER_b_field_cell,1));


sync_options.timing_offset = false;
sync_options.frequency_offset = false;

tx = dect_tx(mac_meta);
rx = dect_rx(tx.mac_meta, sync_options);
T = (1/tx.packet_data.SamplingRate);

errorRate = comm.ErrorRate( ...
    ReceiveDelay=tx.packet_data.viterbi_traceback_depth);

ber_vec = zeros(numel(snr_db_vec_global),num_of_packets_per_snr);



ber_b_field = cell(1,numel(delay_spread));
ber_a_field = cell(1,numel(delay_spread));

for l=1:numel(delay_spread)

    parfor i=1:num_of_workers
        rcrc_err_cnt = 0; 
        xcrc_err_cnt = 0;
    
    
    
        
        for k = 1:1:num_of_packets_per_snr
            txx = tx;
            rxx = rx;
            errorRate_worker = errorRate;
            samples_tx = txx.generate_packet();
    
            %path_delays = [0 0.3819 0.4025 0.5868 0.4610 0.5375 0.6708 0.6750 0.7618 1.5375 1.8978 2.2242 2.1718 2.4942 2.5119 3.0582 4.0810 4.4579 4.5695 4.7966 5.0066 5.3043 9.6586];
            %path_gains = [-13.4 0 -2.2 -4 -6 -8.2 -9.9 -10.5 -7.5 -15.9 -6.6 -16.7 -12.4 -15.2 -10.8 -11.3 -12.7 -16.2 -18.3 -18.9 -16.6 -19.9 -29.7];
    
            rayleighchan = comm.RayleighChannel( ...
                'SampleRate',tx.packet_data.SamplingRate, ...
                'PathDelays',T*[0 floor(delay_spread(l)/T)], ...
                'AveragePathGains',[0 -6], ...
                'NormalizePathGains',true, ...
                'MaximumDopplerShift',0, ...
                'DopplerSpectrum',{doppler('Gaussian',0.6)});%,...
                %'Visualization','Impulse and frequency responses');
            samples_rx = rayleighchan(samples_tx);
    
            awgnchan = comm.AWGNChannel("NoiseMethod","Signal to noise ratio (SNR)","SNR",snr_db_vec_global(i)-pow2db(txx.packet_data.samples_per_symbol));
            samples_rx_noise = awgnchan(samples_rx);
    
    
            % tdl = nrTDLChannel("DelayProfile","TDL-A",...
            %     "DelaySpread",10e-9,...
            %     "MaximumDopplerShift",0,...
            %     "SampleRate",tx.packet_data.SamplingRate,...
            %     "NumReceiveAntennas",1,...
            %     "NumTransmitAntennas",1)
    
            % samples_rx_noise = tdl(samples_tx);
    
            [rcrc_check, xcrc_check] = rxx.decode_packet(samples_rx_noise);
            if rcrc_check == 0
                rcrc_err_cnt = rcrc_err_cnt+1;
            end
            if xcrc_check == 0
                xcrc_err_cnt = xcrc_err_cnt+1;
            end
        
            n_bits_a_field_send(i) = n_bits_a_field_send(i) + numel(txx.packet_data.a_field_bits);
            n_bits_a_field_error(i) = n_bits_a_field_error(i) + sum(abs(double(txx.packet_data.a_field_bits) - double(rxx.packet_data.a_field_bits_rv)));                
        
            n_bits_b_z_field_send(i) = n_bits_b_z_field_send(i) + numel(txx.packet_data.b_z_field_bits);
            n_bits_b_z_field_error(i) = n_bits_b_z_field_error(i) + sum(abs(double(txx.packet_data.b_z_field_bits) - double(rxx.packet_data.b_z_field_bits_rv)));
            
    
            a= errorRate_worker([txx.packet_data.a_field_bits; txx.packet_data.b_z_field_bits], [rxx.packet_data.a_field_bits_rv; rxx.packet_data.b_z_field_bits_rv]);
            ber_vec(i,k) = a(1);
    
            % errorRate_worker.reset();
            % awgnchan.release();
            % rayleighchan.release();
        end
       
        PER_a_field_cell{l,i} = rcrc_err_cnt/num_of_packets_per_snr;
        PER_b_field_cell{l,i} = xcrc_err_cnt/num_of_packets_per_snr;
    
    end


    
    for k = 1:size(PER_b_field_cell,2)
        PER_b_field_array(l,k) = PER_b_field_cell{l,k};
    end
    
    PER_a_field_array = zeros(numel(delay_spread),size(PER_a_field_cell,2));
    
    for k = 1:size(PER_b_field_cell,2)
        PER_a_field_array(l,k) = PER_a_field_cell{l,k};
    end
    
    ber_b_field{l} = n_bits_b_z_field_error./n_bits_b_z_field_send;
    ber_a_field{l} = n_bits_a_field_error./n_bits_a_field_send;

n_bits_a_field_send = zeros(num_of_workers,1);
n_bits_a_field_error = zeros(num_of_workers,1);
n_bits_b_z_field_send = zeros(num_of_workers,1);
n_bits_b_z_field_error = zeros(num_of_workers,1);

end

figure;semilogy(snr_db_vec_global,PER_b_field_array(1,:));
title("PER");
xlabel("SNR in dB");
grid on
hold on
semilogy(snr_db_vec_global,PER_b_field_array(2,:));
legend("100 ns", "150 ns");
xlim([0 40]);
ylim([10e-5 1]);

figure;semilogy(snr_db_vec_global,ber_b_field{1});
title("BER A-Field");
xlabel("SNR in dB");



