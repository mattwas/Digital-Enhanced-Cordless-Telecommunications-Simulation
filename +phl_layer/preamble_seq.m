function [preamble_samples] = preamble_seq(mac_meta, transmission_type)
    sync_bits = phl_layer.preamble_seq_bits(mac_meta,transmission_type);
    
    mod_scheme = mac_layer.configuration_to_mod_scheme(mac_meta);

    switch mod_scheme.s_field_modulation
        case 'GFSK'
            s_field_Mod = comm.CPMModulator( ...
            'ModulationOrder',2, ...
            'FrequencyPulse','Gaussian', ...
            'BandwidthTimeProduct',0.5, ...
            'ModulationIndex',mod_index, ...
            'BitInput',true, ...
            'SamplesPerSymbol',samples_per_symbol);
        case 'pi/2-DBPSK'
            error('not implemeted yet')
    end

    preamble_samples = s_field_Mod(sync_bits);

end