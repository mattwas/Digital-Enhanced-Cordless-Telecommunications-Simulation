function [preamble_samples] = preamble_seq(mac_meta, transmission_type)
    % build the preamble according to the Standard with GFSK or PSK
    % Modulation
    
    sync_bits = phl_layer.preamble_seq_bits(mac_meta,transmission_type);
    
    mod_scheme = general.configuration_to_mod_scheme(mac_meta);

    general_params = general.get_general_params(mac_meta);

    switch mod_scheme.s_field_modulation
        case 'GFSK'
            s_field_Mod = comm.GMSKModulator( ...
            'BitInput',true, ...
            'BandwidthTimeProduct',0.5, ...
            'PulseLength',4, ...
            'SamplesPerSymbol',general_params.samples_per_symbol);
        case 'pi/2-DBPSK'
            error('not implemeted yet')
    end

    preamble_samples = s_field_Mod(sync_bits);

end