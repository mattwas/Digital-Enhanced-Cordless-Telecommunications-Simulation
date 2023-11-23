function [samples_tx,SamplingRate] = dect_modulate(packet_data,mod_scheme, mac_meta)

    % set Modulation Index for GFSK according to Standard
    mod_index = 2*(288e3)*(0.01/24)/480;
    SymbolRate = 480/(0.01/24);
    general_params = general.get_general_params(mac_meta);
    samples_per_symbol = general_params.samples_per_symbol;
    SamplingRate = general_params.SamplingRate;
    
    % modulate data in s-field
    
    switch mac_meta.Configuration
        case "1a"
            gfsk_bits = [packet_data{1}; packet_data{2}; packet_data{3}];
            zero_bits = zeros(60,1);
            gfsk_bits = [gfsk_bits;zero_bits];
            gfsk_mod =  comm.GMSKModulator( ...
             'BitInput',true, ...
             'BandwidthTimeProduct',0.5, ...
             'PulseLength',4, ...
             'SamplesPerSymbol',samples_per_symbol);
            samples_tx = gfsk_mod(gfsk_bits);

        case {"1b", "2", "2b", "3", "3b", "4a", "4b"}

            s_field_data_samples = pskmod( ...
                    packet_data{1}, ...
                    2, ...
                    pi/2,...
                    InputType="bit");


            a_field_data_samples = pskmod( ...
                    packet_data{2}, ...
                    2^mod_scheme.a_field_bits_per_symbol, ...
                    pi/(2^mod_scheme.a_field_bits_per_symbol),...
                    InputType="bit");


            b_z_field_data_samples = pskmod( ...
                    packet_data{3}, ...
                    2^mod_scheme.b_z_field_bits_per_symbol, ...
                    pi/(2^mod_scheme.b_z_field_bits_per_symbol),...
                    InputType="bit");


            samples_tx = [s_field_data_samples; a_field_data_samples;b_z_field_data_samples];

            % pulse shaping according to standard

            pulse_shaping_filter = comm.RaisedCosineTransmitFilter(...
                "RolloffFactor",0.5,...
                "FilterSpanInSymbols",general_params.raised_cosine_length_symbols,...
                "OutputSamplesPerSymbol",samples_per_symbol);

            % prolong the samples, cause of the filter delay
            samples_tx = [samples_tx; zeros(general_params.raised_cosine_length_symbols,1)];
            samples_tx = pulse_shaping_filter(samples_tx);


            % power boost to bring the rms to 1 (0 dB). The attentuation of the
            % filter is getting reversed
            rms_after_filter = rms(samples_tx);
            samples_tx = samples_tx./rms_after_filter;

        case {"5", "6"}

            % s and a field are fixed to pi/2 dbpsk
            s_field_data_samples = pskmod( ...
                    packet_data{1}, ...
                    2, ...
                    pi/2,...
                    InputType="bit");


            a_field_data_samples = pskmod( ...
                    packet_data{2}, ...
                    2^mod_scheme.a_field_bits_per_symbol, ...
                    pi/(2^mod_scheme.a_field_bits_per_symbol),...
                    InputType="bit");

            b_z_field_data_samples = qammod( ...
                    packet_data{3}, ...
                    2^mod_scheme.b_z_field_bits_per_symbol, ...
                    InputType="bit",...
                    UnitAveragePower=1);

            samples_tx = [s_field_data_samples; a_field_data_samples;b_z_field_data_samples];

            % pulse shaping according to standard

            pulse_shaping_filter = comm.RaisedCosineTransmitFilter(...
                "RolloffFactor",0.5,...
                "FilterSpanInSymbols",general_params.raised_cosine_length_symbols,...
                "OutputSamplesPerSymbol",samples_per_symbol);

            % prolong the samples, cause of the filter delay
            samples_tx = [samples_tx; zeros(general_params.raised_cosine_length_symbols,1)];
            samples_tx = pulse_shaping_filter(samples_tx);


            % power boost to bring the rms to 1 (0 dB). The attentuation of the
            % filter is getting reversed
            rms_after_filter = rms(samples_tx);
            samples_tx = samples_tx./rms_after_filter;
            
        otherwise
            error("invalid Configuration");

    end

   
    
    % fill the remainder of the full slot with zeros
    % if mac_meta.a == "32" || mac_meta.a == "00"
    %     remaining_symbols = 480-numel(packet_data{1})-numel(packet_data{2})-numel(packet_data{3});
    %     samples_tx = [samples_tx; zeros(remaining_symbols*samples_per_symbol,1)];
    % end


end