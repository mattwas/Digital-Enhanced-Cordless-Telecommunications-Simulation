function [start_of_packet] = sync(mac_meta, samples)
    preamble_samples = phl_layer.preamble_seq(mac_meta, mac_meta.transmission_type);
    preamble_detector = comm.PreambleDetector('Preamble',preamble_samples);
    start_of_packet = preamble_detector(samples);

end