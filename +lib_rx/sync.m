function [start_of_packet, samples_after_sync] = sync(mac_meta, synchronisation, samples_rx)
% Preliminary Synchronisation based on the PreambleDetector and  CarrierSynchronizer.
% Output is the the Start of the modulated S-Field

    N_Rx = mac_meta.N_Rx;
    configuration = mac_meta.Configuration;
    general_params = general.get_general_params(mac_meta);
    
    start_of_packet = 0;
    samples_timing_synchronized = zeros(general_params.packet_size,N_Rx);
    samples_antenna_corrected = zeros(general_params.packet_size,N_Rx);
    if ~isequal(configuration, '1a')
        samples_antenna_corrected = zeros(general_params.packet_size/general_params.samples_per_symbol,N_Rx); 
    end
    samples_after_sync = zeros(general_params.packet_size/general_params.samples_per_symbol,1);
    
    for i=1:N_Rx
        preamble_samples = phl_layer.preamble_seq(mac_meta);

    %% Timing Synchronisation
        if synchronisation.timing_offset == 1
                preamble_detector = comm.PreambleDetector('Preamble',preamble_samples, 'Detections','All',"Threshold",50);
                [above_threshhold,metric] = preamble_detector(samples_rx(:,i));
            
                % in case there are values above the treshhold
                if numel(above_threshhold) >= 1 || numel(above_threshhold) == 0
                     start_of_packet(:,i) = find(metric >= max(metric))+1-numel(preamble_samples);

                elseif numel(above_threshhold) == 1 
                    start_of_packet(:,i) = above_threshhold+1-numel(preamble_samples);

                else
                    start_of_packet(:,i) = 1;

                end

                start_of_packet = start_of_packet(:, i);
            
        elseif synchronisation.timing_offset == 0
                start_of_packet = 1;
    
        else
            error('Option not viable');

        end
    
        % synchronize the samples
        samples_timing_synchronized(:,i) = samples_rx(start_of_packet:start_of_packet+general_params.packet_size-1, i);
    
        %% Carrier Frequency Offset Correction
        if synchronisation.frequency_offset == 1
            if isequal(configuration, '1a')
                error('CFO correction does not work with GMSK, it is corrected by the Viterbi');
            end

            coarse_cfo_correction = comm.CoarseFrequencyCompensator(...
                "Modulation","QPSK",...
                "SampleRate",general_params.SamplingRate/general_params.samples_per_symbol, ...
                "FrequencyResolution",100);
            
            carrier_sync = comm.CarrierSynchronizer(...
                "Modulation","QPSK",...
                "ModulationPhaseOffset",'Custom',...
                'CustomPhaseOffset',pi/4,...
                "SamplesPerSymbol",1, ...
                "NormalizedLoopBandwidth",0.00001);
    
            % the Pulse Shaping Filter causes problems for the CFO correction,
            % in a real receiver the CFO would be corrected first before the
            % Pulse Shaping gets reversed
    
            samples_deshaped = phl_layer.dect_undo_pulse_shaping(samples_timing_synchronized(:,i), mac_meta);
    
            % calculate a Time Reference
            num_of_samples = general_params.packet_size/general_params.samples_per_symbol;
            time = 0:1:(num_of_samples-1);
            time = time'*1/(general_params.SamplingRate/general_params.samples_per_symbol);
            
            % Coarse CFO Correction
    
            [~,coarse_cfo] = coarse_cfo_correction(samples_deshaped(1:numel(preamble_samples)));
            samples_coarse_cfo = samples_deshaped.*exp(1i*2*pi*(-coarse_cfo)*time);
    
            % apply fine CFO correction
            [~,ph_error] = carrier_sync(samples_coarse_cfo(1:numel(preamble_samples)));
            fine_cfo = diff(ph_error)*(general_params.SamplingRate/general_params.samples_per_symbol)/(2*pi);
            mean_fine_cfo = cumsum(fine_cfo)./(1:length(fine_cfo))';
            samples_fine_cfo = samples_coarse_cfo.*exp(1i*2*pi*(fine_cfo(end))*time);
            
            samples_antenna_corrected(:,i) = samples_fine_cfo;
    
        elseif synchronisation.frequency_offset == 0
            % apply Unshaping Filter
            samples_deshaped = phl_layer.dect_undo_pulse_shaping(samples_timing_synchronized(:,i), mac_meta);
            if isequal(configuration, '1a')
                samples_deshaped = samples_timing_synchronized(:,i);
            end
    
            samples_antenna_corrected(:,i) = samples_deshaped;
    
        else
            error('Option not viable');
        end
    
        %% Correct Phase Ambiguit
        % for coherent detection we need to correct the phase ambiguity of the
        % samples by using the preamble as reference for the correction
        if ~isequal(configuration, '1a')
            preamble_samples = phl_layer.dect_undo_pulse_shaping(preamble_samples,mac_meta);
        end
        phase_offset = sum(samples_antenna_corrected(1:numel(preamble_samples),i).*conj(preamble_samples));
        phase_offset = angle(phase_offset);
        samples_antenna_corrected(:,i) = samples_antenna_corrected(:,i)*exp(1i*(-phase_offset));
    end
    
    if 0
        scatterplot(samples_antenna_corrected(:,1))
        scatterplot(samples_antenna_corrected(:,2))
    end
    
    %% Receiver Diversity

    if N_Rx > 1
        if isequal(mac_meta.antenna_processing, 'Antenna Selection')
            samples_after_sync = lib_rx.antenna_selection(samples_antenna_corrected,mac_meta);

        elseif isequal(mac_meta.antenna_processing, 'Antenna Combining')
            samples_after_sync = lib_rx.antenna_combining(samples_antenna_corrected,mac_meta);
            
        else
            error("Receiver Antenna Processing not valid");
        end
    else 
        samples_after_sync = samples_antenna_corrected;
    end

end