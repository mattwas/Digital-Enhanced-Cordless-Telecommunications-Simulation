function [samples_tx,SamplingRate] = dect_modulate(packet_data,mod_scheme, mac_meta)

    % set Modulation Index for GFSK according to Standard
    mod_index = 2*(288e3)*(0.01/24)/480;
    SymbolRate = 480/(0.01/24);
    samples_per_symbol = 8*mac_meta.Oversampling;
    SamplingRate = SymbolRate*samples_per_symbol;
    
    % modulate data in s-field
    
    switch mod_scheme.s_field_modulation
        case 'GFSK'
            s_field_Mod = comm.GMSKModulator( ...
            'BitInput',true, ...
            'BandwidthTimeProduct',0.5, ...
            'PulseLength',2, ...
            'SamplesPerSymbol',samples_per_symbol);
        case 'pi/2-DBPSK'
            error('not implemeted yet')
    end
    s_field_data_samples = s_field_Mod(packet_data{1});
    
    switch mod_scheme.a_field_modulation
        case 'GFSK'
            a_field_Mod = comm.GMSKModulator( ...
            'BitInput',true, ...
            'BandwidthTimeProduct',0.5, ...
            'PulseLength',2, ...
            'SamplesPerSymbol',samples_per_symbol);
        otherwise
            error('not implemeted yet')
    end
    
    a_field_data_samples = a_field_Mod(packet_data{2});
    
    switch mod_scheme.b_z_field_modulation
        case 'GFSK'
            b_z_field_Mod = comm.GMSKModulator( ...
            'BitInput',true, ...
            'BandwidthTimeProduct',0.5, ...
            'PulseLength',2, ...
            'SamplesPerSymbol',samples_per_symbol);
        otherwise
            error('not implemeted yet')
    end
    
    b_z_field_data_samples = b_z_field_Mod(packet_data{3});
    
    samples_tx = [s_field_data_samples; a_field_data_samples;b_z_field_data_samples];
    
    % fill the remainder of the full slot with zeros
    if mac_meta.a == "32" || mac_meta.a == "00"
        remaining_symbols = 480-numel(packet_data{1})-numel(packet_data{2})-numel(packet_data{3});
        samples_tx = [samples_tx; zeros(remaining_symbols*samples_per_symbol,1)];
    end


end