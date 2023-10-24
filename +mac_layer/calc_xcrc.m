function [b_x_field_bits] = calc_xcrc(b_field_bits,mod_struct)
   % assuming we are only transmitting with full slots at the moment



    % x-field size depends on level of modulation
    x_field_size = mod_struct.b_z_field_bits_per_symbol*4;
    test_bits_m = mod_struct.b_z_field_bits_per_symbol*84;

    % number of test bits for 64-QAM is different
    if mod_struct.b_z_field_bits_per_symbol == 6
        test_bits_m = 496;
    end

    % set the parameters for the test bits

    delta_i = mod_struct.b_z_field_bits_per_symbol*240;

    i_max = test_bits_m-1;

    for i=0:i_max-x_field_size        % 0 < i < i_max - x according to standard
        r_polynomial(i+1) = b_field_bits(i+48*(1+floor(i/16))+1);
    end
    r_polynomial=r_polynomial.';
    crc = comm.CRCGenerator('Polynomial','z^4+1');
    r_polynomial_plus_remainder = crc(r_polynomial);

    % the x-field is the remainder of the output
    for i=1:x_field_size
        x_bits(i)=r_polynomial_plus_remainder(end-x_field_size+i);
    end
    
    % set the x-field
    b_x_field_bits = b_field_bits;
    size_b_field_bits = numel(b_field_bits);
    b_x_field_bits(size_b_field_bits+1:size_b_field_bits+x_field_size) = x_bits;

end