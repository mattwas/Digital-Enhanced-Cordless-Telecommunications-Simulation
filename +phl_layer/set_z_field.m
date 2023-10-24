function [z_field_bits] = set_z_field(b_field, mac_meta)


    z_field_bits = [];
    if mac_meta.z == 1
        z_field_bits = b_field(end-3:end);
    end




end