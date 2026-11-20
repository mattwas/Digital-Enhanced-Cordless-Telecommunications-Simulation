clear all;
close all;

% PER vs. SNR in an AWGN channel for all DECT modulation configurations,
% similar to Fig. 2 in "URLLC Performance Evaluation of IMT-2020 Candidate
% Technology: DECT-2020 New Radio".
%
% Channel coding is switched off (code rate 1), because B-field
% interleaving is not implemented yet.
%
% SNR definition: Es/N0, i.e. average energy per (modulation) symbol over
% noise power spectral density. The transmit samples have unit power and
% rf_channel adds noise with variance sps/10^(SNR/10) per sample. After the
% matched RRC filter and downsampling the SNR per symbol equals snr_db.

%% configurations to simulate (Configuration, label for legend)
% '2b'/'3b' use the same modulation as '2'/'3' and are therefore skipped
configurations = {
    '1a', 'GFSK'
    '1b', '$\pi$/2-DBPSK'
    '2',  '$\pi$/4-DQPSK'
    '3',  '$\pi$/8-D8PSK'
    '4a', '$\pi$/4-DQPSK (A+B)'
    '4b', '$\pi$/8-D8PSK (A+B)'
    '5',  '16-QAM'
    '6',  '64-QAM'
};

%% common DECT parameters
mac_meta_common.a                  = '32';  % P32 basic packet (full slot)
mac_meta_common.K                  = 0;
mac_meta_common.L                  = 0;
mac_meta_common.M                  = 0;
mac_meta_common.N                  = 1;
mac_meta_common.s                  = 0;
mac_meta_common.z                  = 0;
mac_meta_common.Oversampling       = 2;     % AWGN: oversampling does not change the result, 2 is much faster than 24
mac_meta_common.transmission_type  = "RFP";
mac_meta_common.code_rate          = 1;     % no channel coding (B-field interleaver missing)
mac_meta_common.gfsk_receiver      = "viterbi"; % "viterbi" or "iad" (only used for '1a')

sync_options.timing_offset    = false;      % perfect synchronisation
sync_options.frequency_offset = false;

N_Rx               = 1;                     % AWGN, single antenna as in Fig. 2
antenna_processing = "Antenna Combining";

%% simulation parameters
snr_db_vec      = -5 : 1 : 40;
min_packet_errors = 100;       % stop an SNR point after this many B-field packet errors ...
max_packets       = 1e5;       % ... or after this many packets
batch_size        = 500;       % packets per parfor batch

%% result containers
n_cfg = size(configurations,1);
n_snr = numel(snr_db_vec);

results.snr_db_vec        = snr_db_vec;
results.configurations    = configurations;
results.N_Rx              = N_Rx;
results.code_rate         = mac_meta_common.code_rate;
results.PER_a_field       = nan(n_cfg, n_snr);
results.PER_b_field       = nan(n_cfg, n_snr);
results.PER_packet        = nan(n_cfg, n_snr);
results.BER_a_field       = nan(n_cfg, n_snr);
results.BER_b_field       = nan(n_cfg, n_snr);
results.n_packets         = zeros(n_cfg, n_snr);
results.n_b_field_bits    = zeros(n_cfg, 1);

%% simulate
for c = 1:n_cfg

    mac_meta               = mac_meta_common;
    mac_meta.Configuration = configurations{c,1};

    mac_meta_rx                    = mac_meta;
    mac_meta_rx.N_Rx               = N_Rx;
    mac_meta_rx.antenna_processing = antenna_processing;

    mod_struct = general.configuration_to_mod_scheme(mac_meta);
    [~, n_b_bits] = mac_layer.calc_num_bits(mac_meta, mod_struct);
    results.n_b_field_bits(c) = n_b_bits;

    sps = mac_meta.Oversampling;

    fprintf('Configuration %s (%s), B-field %d bit\n', configurations{c,1}, configurations{c,2}, n_b_bits);

    for s = 1:n_snr

        snr_db = snr_db_vec(s);

        % AWGN channel ('deterministic' = no fading). The noise is set in
        % rf_channel.pass_samples via snr_db - 10*log10(samples_per_symbol),
        % i.e. noise variance per sample = sps/10^(snr_db/10) (Es/N0).
        % init_rayleigh_rician_channel() must not be called for this type.
        ch                      = lib_rf_channel.rf_channel();
        ch.verbose              = 0;
        ch.type                 = 'deterministic';
        ch.amp                  = 1.0;
        ch.noise                = true;
        ch.snr_db               = snr_db;
        ch.samples_per_symbol   = sps;
        ch.N_TX                 = 1;
        ch.N_RX                 = N_Rx;
        ch.awgn_random_source   = 'global';
        ch.d_sto                = 0;
        ch.d_cfo                = 0;
        ch.d_err_phase          = 0;

        n_pkt       = 0;
        n_err_a     = 0;
        n_err_b     = 0;
        n_err_pkt   = 0;
        n_biterr_a  = 0;
        n_biterr_b  = 0;
        n_bits_a    = 0;
        n_bits_b    = 0;

        while n_err_b < min_packet_errors && n_pkt < max_packets

            err_a    = zeros(batch_size,1);
            err_b    = zeros(batch_size,1);
            biterr_a = zeros(batch_size,1);
            biterr_b = zeros(batch_size,1);
            bits_a   = zeros(batch_size,1);
            bits_b   = zeros(batch_size,1);

            parfor k = 1:batch_size
                txx = dect_tx(mac_meta);
                rxx = dect_rx(mac_meta_rx, sync_options);

                samples_tx = txx.generate_packet();

                % pass samples through the AWGN channel (independent noise
                % on every rx antenna, global random stream of the worker)
                samples_rx = ch.pass_samples(samples_tx, 0);

                rxx.decode_packet(samples_rx);

                a_tx = double(txx.packet_data.a_field_bits(:));
                a_rx = double(rxx.packet_data.a_field_bits_rv(:));
                b_tx = double(txx.packet_data.b_z_field_bits(:));
                b_rx = double(rxx.packet_data.b_z_field_bits_rv(:));

                % genie aided error detection: the XCRC only covers a
                % subset of the B-field bits and would underestimate the PER
                ea = sum(a_tx ~= a_rx);
                eb = sum(b_tx ~= b_rx);

                biterr_a(k) = ea;
                biterr_b(k) = eb;
                bits_a(k)   = numel(a_tx);
                bits_b(k)   = numel(b_tx);
                err_a(k)    = ea > 0;
                err_b(k)    = eb > 0;
            end

            n_pkt      = n_pkt      + batch_size;
            n_err_a    = n_err_a    + sum(err_a);
            n_err_b    = n_err_b    + sum(err_b);
            n_err_pkt  = n_err_pkt  + sum(err_a | err_b);
            n_biterr_a = n_biterr_a + sum(biterr_a);
            n_biterr_b = n_biterr_b + sum(biterr_b);
            n_bits_a   = n_bits_a   + sum(bits_a);
            n_bits_b   = n_bits_b   + sum(bits_b);
        end

        results.n_packets(c,s)   = n_pkt;
        results.PER_a_field(c,s) = n_err_a/n_pkt;
        results.PER_b_field(c,s) = n_err_b/n_pkt;
        results.PER_packet(c,s)  = n_err_pkt/n_pkt;
        results.BER_a_field(c,s) = n_biterr_a/n_bits_a;
        results.BER_b_field(c,s) = n_biterr_b/n_bits_b;

        delete(ch);

        fprintf('  SNR %5.1f dB: PER_B = %.3e, PER_A = %.3e (%d packets)\n', ...
            snr_db, results.PER_b_field(c,s), results.PER_a_field(c,s), n_pkt);

        % no more errors -> higher SNR values are not needed
        if n_err_pkt == 0 && n_pkt >= max_packets
            break;
        end
    end
end

%% save and plot
if ~exist("results", "dir")
    mkdir("results");
end
save(fullfile("results", "PER_all_modes.mat"), "results", "mac_meta_common");

plot_PER_all_modes(results);
