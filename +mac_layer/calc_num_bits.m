function [num_t_field_bits,num_b_field_bits,num_x_field_bits] = calc_num_bits(mac_meta, mod_struct)
    % mapping according to p. 66 MAC-Layer

%%
    a_field_size = mac_meta.a;
    s_field_size = mac_meta.s;
    a_field_bits_per_symbol = mod_struct.a_field_bits_per_symbol;
    b_z_field_bits_per_symbol = mod_struct.b_z_field_bits_per_symbol;

%%
    % calculate B-Field Bits
    switch a_field_size
        case '32'
            b_field_base_size = 320;
        case '80'
            b_field_base_size = 800;
        case '00'
            b_field_base_size = 0;
            if mac_meta.code_rate ~= 1
                error("code rate not available for P00 format");
            end
        otherwise
            error('other packet formats not implemented yet');
    end

    switch s_field_size
        case 0
            num_s_field_bits = 32;
        case 1
            num_s_field_bits = 32+16;
    end

    % A-Field is per Definition always 64 symbols long
    num_a_field_bits = a_field_bits_per_symbol*64;
    num_t_field_bits = num_a_field_bits-8-16;
    num_x_field_bits = b_z_field_bits_per_symbol*4;

    % for 64 QAM this is not the case
    num_b_field_bits = b_z_field_bits_per_symbol*b_field_base_size;

end