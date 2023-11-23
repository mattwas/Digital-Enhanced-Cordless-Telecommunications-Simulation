function [b_x_field_bits] = calc_xcrc(b_field_bits,mod_struct)
   % assuming we are only transmitting with full slots at the moment



    % x-field size depends on level of modulation; x field size here refers
    % to the size of the crc and not the field
    x_crc_size = mod_struct.b_z_field_bits_per_symbol*4;
    test_bits_m = mod_struct.b_z_field_bits_per_symbol*84;

    % number of test bits for 64-QAM is different
    if mod_struct.b_z_field_bits_per_symbol == 6
        test_bits_m = 496;
        x_crc_size = 16;
    end

    % set the parameters for the test bits

    delta_i = mod_struct.b_z_field_bits_per_symbol*240;

    i_max = test_bits_m-1;

    for i=0:i_max-x_crc_size        % 0 < i < i_max - x according to standard
        r_polynomial(i+1) = b_field_bits(i+48*(1+floor(i/16))+1);
    end
    r_polynomial=r_polynomial.';

    % set the dividing polynomial according to Spec
    switch mod_struct.b_z_field_bits_per_symbol
        case 1
            divider_polynomial = 'z^4+1';
        case 2
            divider_polynomial = 'z^8+1';
        case 3
            divider_polynomial = 'z^12+z^11+z^3+z^2+z+1';
        case {4,6}
            divider_polynomial = 'z^16+z^10+z^8+z^7+z^3+1';
        otherwise
            error("invalid Modulation scheme");
    end

    crc = comm.CRCGenerator('Polynomial',divider_polynomial);
    r_polynomial_plus_remainder = crc(r_polynomial);

    % the x-field is the remainder of the output
    for i=1:x_crc_size
        x_bits(i)=r_polynomial_plus_remainder(end-x_crc_size+i);
    end
    
    
    % set the x-field
    b_x_field_bits = b_field_bits;
    size_b_field_bits = numel(b_field_bits);
    b_x_field_bits(size_b_field_bits+1:size_b_field_bits+x_crc_size) = x_bits;

    % for 64 QAM the true x field size is 24 bit, the rest has to be filled
    % with zeros

    if mod_struct.b_z_field_bits_per_symbol == 6
         b_x_field_bits(size_b_field_bits+x_crc_size+1:size_b_field_bits+x_crc_size+8) = zeros(8,1);
    end
end