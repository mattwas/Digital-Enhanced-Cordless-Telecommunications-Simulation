function [a_field_bits] = calc_rcrc(header_and_tail_bits)
%% add the CRC to the A Field
% WIP: Has to be updated to crcGenerate
    crc16 = comm.CRCGenerator('Polynomial','z^16+z^10+z^8+z^7+z^3+1');
    % crc16_config = crcConfig(Polynomial='z^16+z^10+z^8+z^7+z^3+1');
    % a_field_bits = crcGenerate(header_and_tail_bits, crc16_config);
    a_field_bits = crc16(header_and_tail_bits);
    a_field_bits(end) = ~a_field_bits(end);     % invert the last bit according to MAC-Layer

end