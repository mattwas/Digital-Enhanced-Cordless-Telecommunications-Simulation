function [received_head_tail_bits, error_rcrc] = check_rcrc(received_a_field_data)
    % check the RCRC of the A-field
    %% Create CRC Detector object and check the checksum
    crcdetector = comm.CRCDetector('Polynomial','z^16+z^10+z^8+z^7+z^3+1');
    %rcrc_config = crcConfig(Polynomial='z^16+z^10+z^8+z^7+z^3+1');

    received_a_field_data(end) = ~received_a_field_data(end); % the last bit has to be inverted again

    [received_head_tail_bits, error_rcrc] = crcdetector(received_a_field_data);
    %[received_head_tail_bits, error_rcrc] = crcDetect(received_a_field_data, rcrc_config);

end