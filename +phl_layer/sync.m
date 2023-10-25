function [samples_after_sync, start_of_packet] = sync(mac_meta, samples)
% Synchronisation function for the Receiver. Output is the the Start of the
% modulated A-Field

    preamble_samples = phl_layer.preamble_seq(mac_meta, mac_meta.transmission_type);
    preamble_detector = comm.PreambleDetector('Preamble',preamble_samples, 'Detections','All',"Threshold",254);
    [above_threshhold,metric] = preamble_detector(samples);

    % in case there are values above the treshhold
    if numel(above_threshhold) >= 1
         start_of_packet = find(metric >= max(metric))+1;
    else 
        start_of_packet = above_threshhold+1;
    end

    samples_after_sync = samples(start_of_packet:end);
    
end