clear all;
close all;

%% setup
num_of_packets_per_snr = 1e4;
snr_db_vec_global = -10 : 1.0 : 25;
num_of_workers = numel(snr_db_vec_global);
PER_a_field_cell = cell(numel(snr_db_vec_global),1);
PER_b_field_cell = cell(numel(snr_db_vec_global),1);
n_bits_a_field_send = zeros(num_of_workers,1);
n_bits_a_field_error = zeros(num_of_workers,1);
n_bits_b_z_field_send = zeros(num_of_workers,1);
n_bits_b_z_field_error = zeros(num_of_workers,1);
synchronisation_toggle = 0;

tx = dect_tx();

parfor i=1:num_of_workers
    rcrc_err_cnt = 0;
    xcrc_err_cnt = 0;

    ch                      = rf_channel();
    ch.verbose              = 0;
    ch.verbose_cp           = 0;
    ch.type                 = 'rician';
    ch.amp                  = 1.0;
    ch.noise                = true;
    ch.snr_db             	= snr_db_vec_global(i);
    ch.spectrum_occupied    = 1;        % no idea at the moment
    ch.N_TX                	= 1;
    ch.N_RX               	= 1;
    ch.awgn_random_source   = 'global';
    ch.awgn_randomstream 	= RandStream('mt19937ar','Seed', randi(1e9,[1 1]));
    ch.d_sto                = 0;
    ch.d_cfo               	= 0;
    ch.d_err_phase         	= 0;
    ch.r_random_source      = 'global';
    ch.r_seed    	        = randi(1e9,[1 1]);
    ch.r_sto                = 0;
    ch.r_cfo                = 0;
    ch.r_err_phase          = 0;
    ch.r_samp_rate        	= tx.packet_data.SamplingRate;
    ch.r_max_doppler     	= 0;                            % 1.946 19.458
    ch.r_type   	        = 'TDL-v';
    ch.r_DS_desired         = 10^(-7.03 + 0.00*randn(1,1));
    ch.r_K                  = db2pow(9.0 + 0.00*randn(1,1));    %93e-9;
    ch.r_interpolation      = true;
    ch.r_gains_active 	    = true;
    ch.init_rayleigh_rician_channel();


    
    for k = 1:1:num_of_packets_per_snr
        txx = dect_tx;
        rxx = dect_rx(txx.mac_meta, synchronisation_toggle);
        samples_tx = txx.generate_packet();
        samples_rx = ch.pass_samples(samples_tx,0);
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
    PER_a_field_cell{i} = rcrc_err_cnt/num_of_packets_per_snr;
    PER_b_field_cell{i} = xcrc_err_cnt/num_of_packets_per_snr;

end

PER_b_field_array = zeros(numel(PER_b_field_cell),1);

for k = 1:numel(PER_b_field_cell)
    PER_b_field_array(k) = PER_b_field_cell{k};
end

PER_a_field_array = zeros(numel(PER_a_field_cell),1);

for k = 1:numel(PER_b_field_cell)
    PER_a_field_array(k) = PER_a_field_cell{k};
end

ber_a_field = n_bits_a_field_error./n_bits_a_field_send;
ber_b_field = n_bits_b_z_field_error./n_bits_b_z_field_send;
