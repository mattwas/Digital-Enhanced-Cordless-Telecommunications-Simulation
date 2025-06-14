function [b_field_without_x_bits, error_crc] = check_xcrc(b_field_bits, mac_meta)
    % check if the XCRC of the data part is correct
    % assuming we are only transmitting with full slots at the moment
%%
    mod_struct = general.configuration_to_mod_scheme(mac_meta);

%%
    % x-field size depends on level of modulation; x field size here refers
    % to the size of the crc and not the field
    x_crc_size = mod_struct.b_z_field_bits_per_symbol*4;
    if mod_struct.b_z_field_bits_per_symbol == 6
        x_crc_size = 16;
    end

    switch mac_meta.a

        % full slot, which translates to paket format P32
        case "32"
            test_bits_m = mod_struct.b_z_field_bits_per_symbol*84;
            
            % number of test bits for 64-QAM is different
            if mod_struct.b_z_field_bits_per_symbol == 6
                test_bits_m = 496;
            end

        % double slot, which translates to paket format P80 
        case "80"
            switch mod_struct.b_z_field_bits_per_symbol
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
    
    end
 %% recreate the r-polynomial and check the checksum

    % set the parameters for the test bits
    delta_i = mod_struct.b_z_field_bits_per_symbol*240;

    i_max = test_bits_m-1;
    r_polynomial = zeros(test_bits_m,1);

    for i=0:i_max-x_crc_size        % 0 < i < i_max - x according to standard
        r_polynomial(i+1) = b_field_bits(i+48*(1+floor(i/16))+1);
    end

    % add the XCRC to the polynomial bits

    test_bits_plus_xcrc = [r_polynomial; b_field_bits(end-x_crc_size+1:end)];

    if mod_struct.b_z_field_bits_per_symbol == 6
        test_bits_plus_xcrc = [r_polynomial; b_field_bits(end-8-x_crc_size+1:end-8)];
    end

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
            error("invalid MOD Scheme");
    end

    if ~isequal(test_bits_plus_xcrc, double.empty(0,0))
        crcdetector = comm.CRCDetector('Polynomial',divider_polynomial);
        [~,error_crc] = crcdetector(test_bits_plus_xcrc);
    else
        error_crc = 1;
    end

    b_field_without_x_bits = b_field_bits(1:end-x_crc_size);

end