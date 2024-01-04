function [start_of_packet, samples_after_sync] = sync(mac_meta, synchronisation, samples)
% Synchronisation function for the Receiver. Output is the the Start of the
% modulated S-Field
general_params = general.get_general_params(mac_meta);
preamble_samples = phl_layer.preamble_seq(mac_meta);


    if synchronisation.timing_offset == 1
        preamble_detector = comm.PreambleDetector('Preamble',preamble_samples, 'Detections','All',"Threshold",50);
        [above_threshhold,metric] = preamble_detector(samples);
    
        % in case there are values above the treshhold
        if numel(above_threshhold) >= 1 || numel(above_threshhold) == 0
             start_of_packet = find(metric >= max(metric))+1-numel(preamble_samples);
        elseif numel(above_threshhold) == 1 
            start_of_packet = above_threshhold+1-numel(preamble_samples);
        else
            start_of_packet = 1;
        end
            

    elseif synchronisation.timing_offset == 0
            start_of_packet = 1;

    else
        error('Option not viable');
    end


    % synchronize the samples
    samples_timing_synchronized = samples(start_of_packet:start_of_packet+general_params.packet_size-1);

    if synchronisation.frequency_offset == 1

        if isequal(mac_meta.Configuration, '1a')
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

        samples_deshaped = phl_layer.dect_undo_pulse_shaping(samples_timing_synchronized, mac_meta);

        % Coarse CFO Correction

        % calculate a Time Reference
        num_of_samples = general_params.packet_size/general_params.samples_per_symbol;
        time = 0:1:(num_of_samples-1);
        time = time'*1/(general_params.SamplingRate/general_params.samples_per_symbol);


        [~,coarse_cfo] = coarse_cfo_correction(samples_deshaped(1:numel(preamble_samples)));
        samples_coarse_cfo = samples_deshaped.*exp(1i*2*pi*(-coarse_cfo)*time);

        % apply fine CFO correction
        [~,ph_error] = carrier_sync(samples_coarse_cfo(1:numel(preamble_samples)));
        fine_cfo = diff(ph_error)*(general_params.SamplingRate/general_params.samples_per_symbol)/(2*pi);
        mean_fine_cfo = cumsum(fine_cfo)./(1:length(fine_cfo))';
        samples_fine_cfo = samples_coarse_cfo.*exp(1i*2*pi*(fine_cfo(end))*time);
        
        samples_after_sync = samples_fine_cfo;



    elseif synchronisation.frequency_offset == 0

        % apply Unshaping Filter
        samples_deshaped = phl_layer.dect_undo_pulse_shaping(samples_timing_synchronized, mac_meta);
        if isequal(mac_meta.Configuration, '1a')
            samples_deshaped = samples;
        end

        samples_after_sync = samples_deshaped;


    else
        error('Option not viable');

    end
    
    % for coherent detection we need to correct the phase ambiguity of the
    % samples by using the preamble as reference for the correction
    if ~isequal(mac_meta.Configuration, '1a')
        preamble_samples = phl_layer.dect_undo_pulse_shaping(preamble_samples,mac_meta);
    end
    phase_offset = sum(samples_after_sync(1:numel(preamble_samples)).*conj(preamble_samples));
    phase_offset = angle(phase_offset);
    samples_after_sync = samples_after_sync*exp(1i*(-phase_offset));

    
end