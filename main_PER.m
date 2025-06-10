clear all;
close all;

%% setup for DECT parameters

mac_meta.Configuration      = '1b' ; % Configuration according to PHL
mac_meta.a                  = '32';       % which physical packet are we using: '00' = short packet, '32' = basic packet, '00j' = low capacity packet, '80' = high capacity packet
mac_meta.K                  = 0;          % in which slot (0 - 23) should the packet be transmitted
mac_meta.L                  = 0;          % which half slot should be used for the packet (0 for first; 1 for second)
mac_meta.M                  = 0;          % which RF channel
mac_meta.N                  = 1;          % Radio fixed Part Number (RPN)
mac_meta.s                  = 0;          % synchronization field (0 = normal length, 1 = prolonged)   
mac_meta.z                  = 0;          % z-field indicator, for collision detection (0 = no Z field, 1 = Z Field active)
target_SamplingRate         = 27.648e6;
mac_meta.Oversampling       = target_SamplingRate/1152000; % oversampling, this sets the samples per symbol
mac_meta.transmission_type  = "RFP"; % Transmission Type, changes the sequence of the S-Field
delay_spread                = [100e-9];

mac_meta.code_rate = 0.75;

sync_options.timing_offset = false;
sync_options.frequency_offset = false;


N_Rx = [2];

%% setup for simulation
num_of_packets_per_snr = 10;
snr_db_vec_global = 0 : 1 : 20;
num_of_workers = numel(snr_db_vec_global);
ber_b_field = zeros(1,numel(snr_db_vec_global));
ber_a_field = zeros(1,numel(snr_db_vec_global));
PER_b_field_array = zeros(1,numel(snr_db_vec_global));
PER_a_field_array = zeros(1,numel(snr_db_vec_global));
n_bits_a_field_send = zeros(1, num_of_workers);
n_bits_a_field_error = zeros(1, num_of_workers);
n_bits_b_z_field_send = zeros(1, num_of_workers);
n_bits_b_z_field_error = zeros(1, num_of_workers);

%% initialize Tx and Rx

tx = dect_tx(mac_meta);

mac_meta_rx = mac_meta;
mac_meta_rx.antenna_processing = "Antenna Combining";

sync_options.timing_offset = false;
sync_options.frequency_offset = false;
samples_per_symbol = mac_meta.Oversampling;

mac_meta_rx.N_Rx = N_Rx;
rx = dect_rx(mac_meta_rx, sync_options);

%% simulate

parfor i=1:num_of_workers
        rcrc_err_cnt = 0; 
        xcrc_err_cnt = 0;
    
        % create channel
        ch                      = lib_rf_channel.rf_channel();
        ch.verbose              = 0;
        ch.type                 = 'rayleigh';
        ch.amp                  = 1.0;
        ch.noise                = true;
        ch.snr_db             	= snr_db_vec_global(i);
        ch.samples_per_symbol   = samples_per_symbol;
        ch.N_TX                	= 1;
        ch.N_RX               	= N_Rx;
        ch.awgn_random_source   = 'global';
        ch.awgn_randomstream_seed 	= randi(1e9,[1 1]);
        ch.d_sto                = 0;
        ch.d_cfo               	= 0;
        ch.d_err_phase         	= 0;
        ch.r_random_source      = 'global';
        ch.r_seed    	        = randi(1e9,[1 1]);
        ch.r_sto                = 0;
        ch.r_cfo                = 0;
        ch.r_err_phase          = 0;
        ch.r_samp_rate        	= target_SamplingRate;
        ch.r_max_doppler     	= 0;                            % 1.946 19.458
        ch.r_type   	        = 'TDL-i';
        ch.r_DS_desired         = delay_spread;
        ch.r_K                  = db2pow(9.0 + 0.00*randn(1,1));    %93e-9;
        ch.r_interpolation      = true;
        ch.r_gains_active 	    = true;
        ch.init_rayleigh_rician_channel();
    
        
        for k = 1:1:num_of_packets_per_snr
            txx = dect_tx(mac_meta);
            rxx = dect_rx(mac_meta_rx, sync_options);
            samples_tx = txx.generate_packet();
    
            % pass samples through channel
            samples_rx = ch.pass_samples(samples_tx, 0);
                
            % make next channel impulse response independent from this one
            ch.reset_random_rayleigh_rician();
    
            [rcrc_check, xcrc_check] = rxx.decode_packet(samples_rx);
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
            
    
        end
        delete(ch);
       
        PER_a_field_array(i) = rcrc_err_cnt/num_of_packets_per_snr;
        PER_b_field_array(i) = xcrc_err_cnt/num_of_packets_per_snr;
    
end

ber_b_field = n_bits_b_z_field_error./n_bits_b_z_field_send;
ber_a_field = n_bits_a_field_error./n_bits_a_field_send;

figure;
title("PER B Field");
xlabel("SNR in dB");
grid on
hold on
semilogy(snr_db_vec_global,PER_b_field_array);
xlim([0 40]);
ylim([10e-5 1]);

figure;
title("PER A Field");
xlabel("SNR in dB");
grid on
hold on
semilogy(snr_db_vec_global,PER_a_field_array);
xlim([0 40]);
ylim([10e-5 1]);


figure;
semilogy(snr_db_vec_global, ber_a_field);
hold on
grid on
semilogy(snr_db_vec_global,ber_b_field);
title("BER ");
xlabel("SNR in dB");
legend("A-Field", "B-Field");
xlim([0 40]);
ylim([10e-6 1]);


