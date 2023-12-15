close all;
clear all;

%% Set the parameters for the packet

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

tx = dect_tx(mac_meta);
rx = dect_rx(tx.mac_meta, 1);

samples_tx = tx.generate_packet();
awgn_chan = comm.AWGNChannel("NoiseMethod","Signal to noise ratio (SNR)","SNR",40);
samples_rx = awgn_chan(samples_tx);

[rcrc, xcrc] = rx.decode_packet(samples_tx);