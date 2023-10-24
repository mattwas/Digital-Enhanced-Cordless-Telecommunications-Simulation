function [received_head_tail_bits,error] = check_rcrc(received_a_field_data)
    crcdetector = comm.CRCDetector('Polynomial','z^16+z^10+z^8+z^7+z^3+1');
    received_a_field_data(end) = ~received_a_field_data(end); % the last bit has to be inverted again

    [received_head_tail_bits,error] = crcdetector(received_a_field_data);

end