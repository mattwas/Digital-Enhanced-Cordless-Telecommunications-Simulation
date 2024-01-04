function [preamble_samples] = preamble_seq(mac_meta)
    % build the preamble according to the Standard with GFSK or PSK
    % Modulation
    
    sync_bits = phl_layer.preamble_seq_bits(mac_meta);
    
    mod_scheme = general.configuration_to_mod_scheme(mac_meta);

    general_params = general.get_general_params(mac_meta);
    samples_per_symbol = general_params.samples_per_symbol;

    switch mod_scheme.s_field_modulation
        case 'GFSK'
            s_field_Mod = comm.GMSKModulator( ...
            'BitInput',true, ...
            'BandwidthTimeProduct',0.5, ...
            'PulseLength',general_params.gauss_length, ...
            'SamplesPerSymbol',general_params.samples_per_symbol);
            preamble_samples = s_field_Mod(sync_bits);
        case 'pi/2-DBPSK'
            preamble_samples_dbpsk = phl_layer.dect_dpsk_modulation(sync_bits, 1);
            preamble_samples = phl_layer.dect_pulse_shaping(preamble_samples_dbpsk, mac_meta);
     end

    

end