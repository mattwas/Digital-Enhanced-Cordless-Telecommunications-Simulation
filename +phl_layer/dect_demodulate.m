function [a_field_bits_rv,b_z_field_bits_rv] = dect_demodulate(samples,mac_meta, synchronisation)
    
    general_params = general.get_general_params(mac_meta);
    mod_scheme = general.configuration_to_mod_scheme(mac_meta);
    
    [size_t_field_bits,size_b_field_bits,size_x_field_bits] = mac_layer.calc_num_bits(mac_meta,mod_scheme);
  
    switch mac_meta.Configuration
        case "1a"
                size_z_field = mac_meta.z*4;
                GFSK_demod = comm.GMSKDemodulator( ...
                'BitOutput',true, ...
                'BandwidthTimeProduct',0.5, ...
                'PulseLength',4, ...
                'SamplesPerSymbol',general_params.samples_per_symbol,...
                "TracebackDepth",60);

                bits_rv = GFSK_demod(samples);
                tracebackBits = GFSK_demod.TracebackDepth;
                bits_rv(1:tracebackBits)=[];
                a_field_bits_rv = bits_rv(synchronisation.packet_start-1+general_params.s_field_size+1:general_params.s_field_size+size_t_field_bits+general_params.a_field.header+general_params.a_field.size_rcrc);
                b_z_field_bits_rv = bits_rv(synchronisation.packet_start-1+general_params.s_field_size+size_t_field_bits+general_params.a_field.header+general_params.a_field.size_rcrc+1:(general_params.s_field_size+size_t_field_bits+general_params.a_field.header+general_params.a_field.size_rcrc)+size_b_field_bits+size_x_field_bits+size_z_field);
        case {"1b", "2", "2b", "3", "3b", "4a", "4b"}
                if synchronisation.packet_start == 1
                   synchronisation.packet_start = synchronisation.packet_start + general_params.raised_cosine_length_symbols;
                end


                pulse_shaping_filter = comm.RaisedCosineReceiveFilter(...
                    "RolloffFactor",0.5,...
                    "FilterSpanInSymbols",general_params.raised_cosine_length_symbols,...
                    "InputSamplesPerSymbol",general_params.samples_per_symbol,...
                    "DecimationFactor",general_params.samples_per_symbol);

                samples = pulse_shaping_filter(samples);

                % bring the power back to baseline

                current_rms = rms(samples);
                samples = samples./current_rms;

                a_field_size_symbols = (size_t_field_bits+8+16)/mod_scheme.a_field_bits_per_symbol;
                b_z_field_size_symbols = (size_b_field_bits+size_x_field_bits)/mod_scheme.b_z_field_bits_per_symbol;

                if mac_meta.z == 1
                    b_z_field_size_symbols = b_z_field_size_symbols + 4*mod_scheme.b_z_field_bits_per_symbol;
                end

                a_field_symbols_rv = samples(synchronisation.packet_start+general_params.s_field_size:synchronisation.packet_start-1+general_params.s_field_size+a_field_size_symbols);
                if ~isequal(size_b_field_bits,0)
                    b_z_field_symbols_rv = samples(synchronisation.packet_start-1+general_params.s_field_size+a_field_size_symbols+1:synchronisation.packet_start-1+general_params.s_field_size+a_field_size_symbols+b_z_field_size_symbols);
                else
                    b_z_field_symbols_rv = [];
                end


                a_field_bits_rv = pskdemod( ...
                    a_field_symbols_rv, ...
                    2^mod_scheme.a_field_bits_per_symbol, ...
                    pi/(2^mod_scheme.a_field_bits_per_symbol),...
                    OutputType="bit");

                if ~isequal(size_b_field_bits,0)
                    b_z_field_bits_rv = pskdemod( ...
                        b_z_field_symbols_rv, ...
                        2^mod_scheme.b_z_field_bits_per_symbol, ...
                        pi/(2^mod_scheme.b_z_field_bits_per_symbol),...
                        OutputType="bit");
                else
                    b_z_field_bits_rv = [];
                end

        case {"5", "6"}
                if synchronisation.packet_start == 1
                   synchronisation.packet_start = synchronisation.packet_start + general_params.raised_cosine_length_symbols;
                end


                pulse_shaping_filter = comm.RaisedCosineReceiveFilter(...
                    "RolloffFactor",0.5,...
                    "FilterSpanInSymbols",general_params.raised_cosine_length_symbols,...
                    "InputSamplesPerSymbol",general_params.samples_per_symbol,...
                    "DecimationFactor",general_params.samples_per_symbol);

                samples = pulse_shaping_filter(samples);

                % bring the power back to baseline

                current_rms = rms(samples);
                samples = samples./current_rms;

                a_field_size_symbols = (size_t_field_bits+8+16)/mod_scheme.a_field_bits_per_symbol;
                b_z_field_size_symbols = (size_b_field_bits+size_x_field_bits)/mod_scheme.b_z_field_bits_per_symbol;

                if mac_meta.z == 1
                    b_z_field_size_symbols = b_z_field_size_symbols + 4*mod_scheme.b_z_field_bits_per_symbol;
                end

                a_field_symbols_rv = samples(synchronisation.packet_start+general_params.s_field_size:synchronisation.packet_start-1+general_params.s_field_size+a_field_size_symbols);
                if ~isequal(size_b_field_bits,0)
                    b_z_field_symbols_rv = samples(synchronisation.packet_start-1+general_params.s_field_size+a_field_size_symbols+1:synchronisation.packet_start-1+general_params.s_field_size+a_field_size_symbols+b_z_field_size_symbols);
                else
                    b_z_field_symbols_rv = [];
                end

                a_field_bits_rv = pskdemod( ...
                    a_field_symbols_rv, ...
                    2^mod_scheme.a_field_bits_per_symbol, ...
                    pi/(2^mod_scheme.a_field_bits_per_symbol),...
                    OutputType="bit");


                 b_z_field_bits_rv = qamdemod( ...
                    b_z_field_symbols_rv, ...
                    2^mod_scheme.b_z_field_bits_per_symbol, ...
                    OutputType="bit",...
                    UnitAveragePower=1);
        otherwise
            error("invalid Configuration");

    end

            
end