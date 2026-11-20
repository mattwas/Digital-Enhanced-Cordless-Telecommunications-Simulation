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
            L = general_params.gauss_length;
            mk = comm.GMSKModulator( ...
                'BitInput',true, ...
                'BandwidthTimeProduct',0.5, ...
                'PulseLength',L, ...
                'SamplesPerSymbol',samples_per_symbol);
        
            % add the tail
            y_p = mk([gfsk_bits; ones(L-1,1)]);   % extra +1 symbols
            reset(mk);
            y_m = mk([gfsk_bits; zeros(L-1,1)]);  % extra -1 symbols
        
            phi = (unwrap(angle(y_p)) + unwrap(angle(y_m)))/2;  % extra symbols cancel
            samples_tx = exp(1j*phi);   % (n_bits + L-1)*sps samples: burst + tail
    
            % append the TracebackDepth for the receiver
            samples_tx = [samples_tx; zeros(general_params.viterbi_traceback_depth*samples_per_symbol, size(samples_tx,2))];

            % % reference: plain GMSK modulator, data bits only, no tail
            % ref = comm.GMSKModulator( ...
            %     'BitInput',true, ...
            %     'BandwidthTimeProduct',0.5, ...
            %     'PulseLength',L, ...
            %     'SamplesPerSymbol',samples_per_symbol);
            % y_ref = ref(gfsk_bits);
            % 
            % N = numel(y_ref);                         % = numel(gfsk_bits)*sps
            % max(abs(samples_tx(1:N) - y_ref))         % expect ~1e-15 (burst identical)
            % numel(samples_tx) - N                     % expect (L-1)*sps (tail length)
            % 
            % plot(unwrap(angle(samples_tx))); hold on
            % plot(unwrap(angle(y_ref)),'--'); xline(N);  % curves overlap up to N, then the tail flattens

        case {"1b", "2", "2b", "3", "3b", "4a", "4b"}

            s_field_data_samples = phl_layer.dect_dpsk_modulation(packet_data{1},1);
            a_field_data_samples = phl_layer.dect_dpsk_modulation(packet_data{2},mod_scheme.a_field_bits_per_symbol);
            

            if ~isequal(packet_data{3}, double.empty(0,1))
                b_z_field_data_samples = phl_layer.dect_dpsk_modulation(packet_data{3}, mod_scheme.b_z_field_bits_per_symbol);

            else
                b_z_field_data_samples = [];
            end


            samples_tx = [s_field_data_samples; a_field_data_samples;b_z_field_data_samples];

            samples_tx = phl_layer.dect_pulse_shaping(samples_tx,mac_meta);

        case {"5", "6"}

            % s and a field are fixed to Pi/2-DBPSK
            s_field_data_samples = phl_layer.dect_dpsk_modulation(packet_data{1},1);
            a_field_data_samples = phl_layer.dect_dpsk_modulation(packet_data{2},mod_scheme.a_field_bits_per_symbol);

            if ~isequal(packet_data{3}, double.empty(0,1))
                b_z_field_data_samples = qammod( ...
                        packet_data{3}, ...
                        2^mod_scheme.b_z_field_bits_per_symbol, ...
                        InputType="bit",...
                        UnitAveragePower=1);
            else
                b_z_field_data_samples = [];
            end

            samples_tx = [s_field_data_samples; a_field_data_samples; b_z_field_data_samples];

            samples_tx = phl_layer.dect_pulse_shaping(samples_tx, mac_meta);
            
        otherwise
            error("invalid Configuration");

    end

   
    
    % fill the remainder of the full slot with zeros
    % if mac_meta.a == "32" || mac_meta.a == "00"
    %     remaining_symbols = 480-numel(packet_data{1})-numel(packet_data{2})-numel(packet_data{3});
    %     samples_tx = [samples_tx; zeros(remaining_symbols*samples_per_symbol,1)];
    % end


end
