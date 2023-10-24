function [a_field_bits] = calc_rcrc(header_and_teil_bits)
    crc16 = comm.CRCGenerator('Polynomial','z^16+z^10+z^8+z^7+z^3+1');
    a_field_bits = crc16(header_and_teil_bits);
    a_field_bits(end) = ~a_field_bits(end);     % invert the last bit according to MAC-Layer


end