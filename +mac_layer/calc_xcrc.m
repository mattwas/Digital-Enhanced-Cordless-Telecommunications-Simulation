function [b_x_field_bits] = calc_xcrc(b_field_bits,mac_meta)
    % generate the CRC for the Data (XCRC)
%%
    % assuming we are only transmitting with full slots at the moment
    mod_struct = general.configuration_to_mod_scheme(mac_meta);
    b_z_field_bits_per_symbol = mod_struct.b_z_field_bits_per_symbol;

    % x-field size depends on level of modulation; x field size here refers
    % to the size of the crc and not the field
    x_crc_size = b_z_field_bits_per_symbol*4;
    if b_z_field_bits_per_symbol == 6
        x_crc_size = 16;
    end

%%
    switch mac_meta.a
        % full slot, which translates to paket format P32
        case "32"
            test_bits_m = b_z_field_bits_per_symbol*84;
            
            % number of test bits for 64-QAM is different
            if b_z_field_bits_per_symbol == 6
                test_bits_m = 496;
            end

        % double slot, which translates to paket format P80 
        case "80"
            switch b_z_field_bits_per_symbol
                case 1
                    test_bits_m = 164;
                case 2
                    test_bits_m = 408;
                case 3
                    test_bits_m = 604;
                case 4
                    test_bits_m = 816;
                case 6
                    test_bits_m = 1216;
            end
        case "00"
            test_bits_m = 0;
            x_crc_size = 0;
        otherwise
            error("not implemented yet");
    
    end

    % set the parameters for the test bits
    delta_i = b_z_field_bits_per_symbol*240;

    i_max = test_bits_m-1;
    r_polynomial = zeros(test_bits_m,1);

    for i=0:i_max-x_crc_size        % 0 <= i <= i_max - x according to standard
        r_polynomial(i+1) = b_field_bits(i+48*(1+floor(i/16))+1);
    end
    %r_polynomial=r_polynomial.';

    % set the dividing polynomial according to Spec
    switch b_z_field_bits_per_symbol
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
    % xcrc_config = crcConfig(Polynomial=divider_polynomial);
    % r_polynomial_plus_remainder = crcGenerate(r_polynomial, xcrc_config);
    
    x_bits = zeros(x_crc_size,1);

    % the x-field is the remainder of the output
    for i=1:x_crc_size
        x_bits(i)=r_polynomial_plus_remainder(end-x_crc_size+i);
    end
    
    % add the x-field to the b-field bits vector
    b_x_field_bits = b_field_bits;
    size_b_field_bits = numel(b_field_bits);
    b_x_field_bits(size_b_field_bits+1:size_b_field_bits+x_crc_size) = x_bits;

    % for 64 QAM the true x field size is 24 bit, the rest has to be filled
    % with zeros
    if b_z_field_bits_per_symbol == 6
         b_x_field_bits(size_b_field_bits+x_crc_size+1:size_b_field_bits+x_crc_size+8) = zeros(8,1);
    end
end