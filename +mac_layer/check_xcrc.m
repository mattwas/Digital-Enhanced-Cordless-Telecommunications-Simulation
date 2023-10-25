function [b_field_without_x_bits,error] = check_xcrc(b_field_bits, mac_meta)
   % assuming we are only transmitting with full slots at the moment

    mod_struct = general.configuration_to_mod_scheme(mac_meta);

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
    test_bits_plus_xcrc = [r_polynomial.'; b_field_bits(end-x_field_size+1:end)];
    crcdetector = comm.CRCDetector('Polynomial','z^4+1');
    [~,error] = crcdetector(test_bits_plus_xcrc);
    if error == 0
        b_field_without_x_bits = b_field_bits(1:end-x_field_size);
    else
        b_field_without_x_bits = 0;
    end
end