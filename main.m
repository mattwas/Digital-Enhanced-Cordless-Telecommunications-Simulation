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

sync_options.timing_offset = false;
sync_options.frequency_offset = false;

tx = dect_tx(mac_meta);
rx = dect_rx(tx.mac_meta, sync_options);
T = (1/tx.packet_data.SamplingRate);
samples_tx = tx.generate_packet();
path_delays = [0 0.3819 0.4025 0.5868 0.4610 0.5375 0.6708 0.6750 0.7618 1.5375 1.8978 2.2242 2.1718 2.4942 2.5119 3.0582 4.0810 4.4579 4.5695 4.7966 5.0066 5.3043 9.6586];
path_gains = [-13.4 0 -2.2 -4 -6 -8.2 -9.9 -10.5 -7.5 -15.9 -6.6 -16.7 -12.4 -15.2 -10.8 -11.3 -12.7 -16.2 -18.3 -18.9 -16.6 -19.9 -29.7];
awgn_chan = comm.AWGNChannel("NoiseMethod","Signal to noise ratio (SNR)","SNR",40);
rayleighchan = comm.RayleighChannel( ...
                'SampleRate',tx.packet_data.SamplingRate, ...
                'PathDelays',0, ...
                'AveragePathGains',0, ...
                'NormalizePathGains',true, ...
                'MaximumDopplerShift',500, ...
                'DopplerSpectrum',{doppler('Jakes')});%,...
                %'Visualization','Impulse and frequency responses');
samples_rx = rayleighchan(samples_tx);


samples_rx = awgn_chan(samples_tx);

[rcrc, xcrc] = rx.decode_packet(samples_rx);

biterr(tx.packet_data.a_field_bits, rx.packet_data.a_field_bits_rv)

biterr(tx.packet_data.b_z_field_bits, rx.packet_data.b_z_field_bits_rv)