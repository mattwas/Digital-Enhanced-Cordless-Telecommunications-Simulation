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
                'PulseLength',general_params.gauss_length, ...
                'SamplesPerSymbol',general_params.samples_per_symbol,...
                "TracebackDepth",general_params.viterbi_traceback_depth);

                bits_rv = GFSK_demod(samples);
                tracebackBits = GFSK_demod.TracebackDepth;
                bits_rv(1:tracebackBits)=[];
                a_field_bits_rv = bits_rv(synchronisation.packet_start+general_params.s_field_size:synchronisation.packet_start-1+general_params.s_field_size+size_t_field_bits+general_params.a_field.header+general_params.a_field.size_rcrc);
                b_z_field_bits_rv = bits_rv(synchronisation.packet_start-1+general_params.s_field_size+size_t_field_bits+general_params.a_field.header+general_params.a_field.size_rcrc+1:(synchronisation.packet_start-1+general_params.s_field_size+size_t_field_bits+general_params.a_field.header+general_params.a_field.size_rcrc)+size_b_field_bits+size_x_field_bits+size_z_field);
        case {"1b", "2", "2b", "3", "3b", "4a", "4b"}

                % sync not working at the moment, we assume perfect
                % synchronisation


                % derive the number of samples per data field

                a_field_size_symbols = (size_t_field_bits+8+16)/mod_scheme.a_field_bits_per_symbol;
                b_z_field_size_symbols = (size_b_field_bits+size_x_field_bits)/mod_scheme.b_z_field_bits_per_symbol;

                if mac_meta.z == 1
                    b_z_field_size_symbols = b_z_field_size_symbols + 4*mod_scheme.b_z_field_bits_per_symbol;
                end

                % select which samples belong to the data fields, we have
                % to include one symbol from the field before the actual
                % data field to recover the first bit (it is used as a
                % reference and has to be discarded after demodulation)
                
                a_field_symbols_rv = samples(synchronisation.packet_start+general_params.s_field_size:synchronisation.packet_start-1+general_params.s_field_size+a_field_size_symbols);
                if ~isequal(size_b_field_bits,0)
                    b_z_field_symbols_rv = samples(synchronisation.packet_start-1+general_params.s_field_size+a_field_size_symbols+1:synchronisation.packet_start-1+general_params.s_field_size+a_field_size_symbols+b_z_field_size_symbols);
                else
                    b_z_field_symbols_rv = [];
                end

                
                a_field_demod  = comm.DPSKDemodulator( ...
                    2^mod_scheme.a_field_bits_per_symbol, ...
                    pi/(2^mod_scheme.a_field_bits_per_symbol),...
                    BitOutput=1);
                

                a_field_bits_rv = a_field_demod(a_field_symbols_rv);
                %a_field_bits_rv(1:mod_scheme.a_field_bits_per_symbol) = [];
                if mod_scheme.a_field_bits_per_symbol == 1
                    a_field_bits_rv = double(~a_field_bits_rv);
                end

                if ~isequal(size_b_field_bits,0)
                    b_z_field_demod = comm.DPSKDemodulator( ...
                        2^mod_scheme.b_z_field_bits_per_symbol, ...
                        pi/(2^mod_scheme.b_z_field_bits_per_symbol),...
                        BitOutput=1);
                    b_z_field_bits_rv = b_z_field_demod(b_z_field_symbols_rv);
                    if mod_scheme.b_z_field_bits_per_symbol == 1
                        b_z_field_bits_rv = double(~b_z_field_bits_rv);
                    end
                    % b_z_field_bits_rv(1:end-size_b_field_bits-size_x_field_bits) = [];
                else
                    b_z_field_bits_rv = [];
                end

        case {"5", "6"}

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

                a_field_demod = comm.DPSKDemodulator( ...
                    2^mod_scheme.a_field_bits_per_symbol, ...
                    pi/(2^mod_scheme.a_field_bits_per_symbol),...
                    BitOutput=1);

                a_field_bits_rv = a_field_demod(a_field_symbols_rv);
                if mod_scheme.a_field_bits_per_symbol == 1
                    a_field_bits_rv = ~a_field_bits_rv;
                end
                

                 b_z_field_bits_rv = qamdemod( ...
                    b_z_field_symbols_rv, ...
                    2^mod_scheme.b_z_field_bits_per_symbol, ...
                    OutputType="bit",...
                    UnitAveragePower=1);
        otherwise
            error("invalid Configuration");

    end

            
end