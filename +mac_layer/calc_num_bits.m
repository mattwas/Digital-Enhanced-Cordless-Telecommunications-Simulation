function [num_t_field_bits,num_b_field_bits,num_x_field_bits] = calc_num_bits(mac_meta, mod_struct)
    % mapping according to p. 66 MAC-Layer


    % calculate A-Field Bits
    switch mac_meta.a
        case '32'
            b_field_base_size = 320;
        otherwise
            error('other packet formats not implemented yet');
    end
    num_s_field_bits = 32;
    num_a_field_bits = mod_struct.a_field_bits_per_symbol*64;
    num_t_field_bits = num_a_field_bits-8-16;
    num_x_field_bits = mod_struct.b_z_field_bits_per_symbol*4;
    % for 64 QAM this is not the case
    num_b_field_bits = mod_struct.b_z_field_bits_per_symbol*b_field_base_size;

end