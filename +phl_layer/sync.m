function [start_of_packet, samples_after_sync] = sync(mac_meta, toggle, samples)
% Synchronisation function for the Receiver. Output is the the Start of the
% modulated S-Field
    if toggle == 1
        preamble_samples = phl_layer.preamble_seq(mac_meta);
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

        if 1
            start_of_packet = 1;
        end
        

        % for coherent detection we need to correct the phase ambiguity of the
        % samples by using the preamble as reference for the correction
        phase_offset = sum(samples(start_of_packet:start_of_packet+numel(preamble_samples)-1).*conj(preamble_samples));
        phase_offset = angle(phase_offset);
        samples_after_sync = samples*exp(1i*(-phase_offset));
        % samples_after_sync = samples;
        

    elseif toggle == 0
        % preamble_samples = phl_layer.preamble_seq(mac_meta, mac_meta.transmission_type);
        % start_of_packet = numel(preamble_samples)+1;
        % samples_after_sync = samples(start_of_packet:end);
        samples_after_sync = samples;
        start_of_packet = 1;
        
    else
        error('not defined synchronisation toggle')
    end
    
end