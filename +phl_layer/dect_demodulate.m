function [a_field_bits_rv,b_z_field_bits_rv] = dect_demodulate(samples,mac_meta, synchronisation)
    
    general_params = general.get_general_params(mac_meta);
    mod_scheme = general.configuration_to_mod_scheme(mac_meta);
    
    [size_t_field_bits,size_b_field_bits,size_x_field_bits] = mac_layer.calc_num_bits(mac_meta,mod_scheme);
    
    % a_field_size_samples = (size_t_field_bits+8+16)*general_params.samples_per_symbol*mod_scheme.a_field_bits_per_symbol;
    % b_z_field_size_samples = (size_b_field_bits+size_x_field_bits)*general_params.samples_per_symbol*mod_scheme.b_z_field_bits_per_symbol;
    % 
    % if mac_meta.z == 1
    %     b_z_field_size_samples = b_z_field_size_samples + 4*general_params.samples_per_symbol*mod_scheme.b_z_field_bits_per_symbol;
    % end
    % 
    % if a_field_size_samples + b_z_field_size_samples <= numel(samples)
    % 
    %     switch mod_scheme.a_field_modulation
    %         case 'GFSK'
    %             a_field_Demod = comm.GMSKDemodulator( ...
    %             'BitOutput',true, ...
    %             'BandwidthTimeProduct',0.5, ...
    %             'PulseLength',2, ...
    %             'SamplesPerSymbol',general_params.samples_per_symbol);
    %         otherwise
    %             error('not implemeted yet')
    %     end
    % 
    %     tracebackBits = a_field_Demod.TracebackDepth;
    % 
    %     a_field_samples_traceback = [samples(1:a_field_size_samples); zeros(tracebackBits*mod_scheme.a_field_bits_per_symbol*general_params.samples_per_symbol,1)];
    % 
    % 
    %     a_field_bits_rv = a_field_Demod(a_field_samples_traceback);
    %     a_field_bits_rv = a_field_bits_rv(tracebackBits+1:end);
    % 
    %     switch mod_scheme.b_z_field_modulation
    %         case 'GFSK'
    %             b_z_field_Demod = comm.GMSKDemodulator( ...
    %             'BitOutput',true, ...
    %             'BandwidthTimeProduct',0.5, ...
    %             'PulseLength',2, ...
    %             'SamplesPerSymbol',general_params.samples_per_symbol);
    %         otherwise
    %             error('not implemeted yet')
    %     end
    % 
    %     tracebackBits = b_z_field_Demod.TracebackDepth;
    % 
    %     b_z_field_samples_traceback = [samples(a_field_size_samples+1:a_field_size_samples+b_z_field_size_samples); zeros(tracebackBits*mod_scheme.b_z_field_bits_per_symbol*general_params.samples_per_symbol,1)];
    % 
    % 
    %     b_z_field_bits_rv = b_z_field_Demod(b_z_field_samples_traceback);
    % 
    %     b_z_field_bits_rv = b_z_field_bits_rv(tracebackBits+1:end);
    % 
    % else
    %     a_field_bits_rv = 0;
    %     b_z_field_bits_rv = 0;
    % end

    switch mac_meta.Configuration
        case "1a"
                size_z_field = mac_meta.z*4;
                GFSK_demod = comm.GMSKDemodulator( ...
                'BitOutput',true, ...
                'BandwidthTimeProduct',0.5, ...
                'PulseLength',4, ...
                'SamplesPerSymbol',general_params.samples_per_symbol,...
                "TracebackDepth",60);

                % there is a decoding delay caused by the Viterbi (indicated by
                % a preamble of zeros before the actual decoded bits).
                % Because the number of decoded bits is the same length as
                % the sended bits, the last part of the packet is not
                % decoded.
                % To resolve this issue a signal of zeros will be modulated
                % and follow the actual samples in the demodulator.

                GMSK_mod = comm.GMSKModulator( ...
                     'BitInput',true, ...
                     'BandwidthTimeProduct',0.5, ...
                     'PulseLength',4, ...
                     'SamplesPerSymbol',general_params.samples_per_symbol);
                zero_bits = zeros(GFSK_demod.TracebackDepth,1);

                zero_samples = GMSK_mod(zero_bits);

                %samples = [samples; zero_samples];


                bits_rv = GFSK_demod(samples);
                tracebackBits = GFSK_demod.TracebackDepth;
                bits_rv(1:tracebackBits)=[];
                a_field_bits_rv = bits_rv(synchronisation.packet_start-1+32+1:32+size_t_field_bits+8+16);
                b_z_field_bits_rv = bits_rv(synchronisation.packet_start-1+32+size_t_field_bits+8+16+1:(32+size_t_field_bits+8+16)+size_b_field_bits+size_x_field_bits+size_z_field);
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

                a_field_symbols_rv = samples(synchronisation.packet_start+32:synchronisation.packet_start-1+32+a_field_size_symbols);
                b_z_field_symbols_rv = samples(synchronisation.packet_start-1+32+a_field_size_symbols+1:synchronisation.packet_start-1+32+a_field_size_symbols+b_z_field_size_symbols);


                a_field_bits_rv = pskdemod( ...
                    a_field_symbols_rv, ...
                    2^mod_scheme.a_field_bits_per_symbol, ...
                    pi/(2^mod_scheme.a_field_bits_per_symbol),...
                    OutputType="bit");


                 b_z_field_bits_rv = pskdemod( ...
                    b_z_field_symbols_rv, ...
                    2^mod_scheme.b_z_field_bits_per_symbol, ...
                    pi/(2^mod_scheme.b_z_field_bits_per_symbol),...
                    OutputType="bit");

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

                a_field_symbols_rv = samples(synchronisation.packet_start+32:synchronisation.packet_start-1+32+a_field_size_symbols);
                b_z_field_symbols_rv = samples(synchronisation.packet_start-1+32+a_field_size_symbols+1:synchronisation.packet_start-1+32+a_field_size_symbols+b_z_field_size_symbols);


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