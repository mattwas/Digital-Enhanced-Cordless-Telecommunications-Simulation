function [a_field_bits_rv,b_z_field_bits_rv] = dect_demodulate(samples,mac_meta)
    
    general_params = general.get_general_params(mac_meta);
    mod_scheme = general.configuration_to_mod_scheme(mac_meta);
    
    [size_t_field_bits,size_b_field_bits,size_x_field_bits] = mac_layer.calc_num_bits(mac_meta,mod_scheme);
    
    a_field_size_samples = (size_t_field_bits+8+16)*general_params.samples_per_symbol*mod_scheme.a_field_bits_per_symbol;
    
    switch mod_scheme.a_field_modulation
        case 'GFSK'
            a_field_Demod = comm.GMSKDemodulator( ...
            'BitOutput',true, ...
            'BandwidthTimeProduct',0.5, ...
            'PulseLength',4, ...
            'SamplesPerSymbol',general_params.samples_per_symbol);
        otherwise
            error('not implemeted yet')
    end
    
    a_field_bits_rv = a_field_Demod(samples(1:a_field_size_samples));
    
    switch mod_scheme.b_z_field_modulation
        case 'GFSK'
            b_z_field_Demod = comm.GMSKDemodulator( ...
            'BitOutput',true, ...
            'BandwidthTimeProduct',0.5, ...
            'PulseLength',4, ...
            'SamplesPerSymbol',general_params.samples_per_symbol);
        otherwise
            error('not implemeted yet')
    end



    b_z_field_bits_rv = b_z_field_Demod(samples(a_field_size_samples+1:end));

end