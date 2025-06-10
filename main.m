close all;
clear all;

%% Set the parameters for the packet

mac_meta.Configuration = '1b' ; % Configuration according to PHL
mac_meta.a = '32';       % which physical packet are we using: '00' = short packet, '32' = basic packet, '00j' = low capacity packet, '80' = high capacity packet
mac_meta.K = 0;          % in which slot (0 - 23) should the packet be transmitted
mac_meta.L = 0;          % which half slot should be used for the packet (0 for first; 1 for second)
mac_meta.M = 0;          % which RF channel
mac_meta.N = 1;          % Radio fixed Part Number (RPN)
mac_meta.s = 0;          % synchronization field (0 = normal length, 1 = prolonged)   
mac_meta.z = 0;          % z-field indicator, for collision detection (0 = no Z field, 1 = Z Field active)
mac_meta.Oversampling = 2; % oversampling
mac_meta.code_rate = 0.75;
mac_meta.transmission_type = "RFP"; % Transmission Type changes the sequence of the S-Field

sync_options.timing_offset = false;
sync_options.frequency_offset = false;

mac_meta_rx = mac_meta;
mac_meta_rx.N_Rx = 1;

mac_meta_rx.antenna_processing = "Antenna Combining";

%% create transmitter and receiver objects
tx = dect_tx(mac_meta);
rx = dect_rx(mac_meta_rx, sync_options);

%% generate samples and channel, pass samples through channel
samples_tx = tx.generate_packet();

awgn_chan = comm.AWGNChannel("NoiseMethod","Signal to noise ratio (SNR)","SNR",10);

samples_antennas_rx = zeros(numel(samples_tx),4);
samples_antennas_rx(:,1) = awgn_chan(samples_tx);
samples_antennas_rx(:,2) = awgn_chan(samples_tx);
samples_antennas_rx(:,3) = awgn_chan(samples_tx);
samples_antennas_rx(:,4) = awgn_chan(samples_tx);

%% decode packet, calculate bit errors
 
[rcrc, xcrc] = rx.decode_packet(samples_antennas_rx);

biterr(tx.packet_data.a_field_bits, rx.packet_data.a_field_bits_rv)

biterr(tx.packet_data.b_z_field_bits, rx.packet_data.b_z_field_bits_rv)

biterr(tx.packet_data.b_field_data, rx.packet_data.b_field_bits_dec_rv)