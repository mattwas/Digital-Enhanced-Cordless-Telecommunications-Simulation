function [b_field_bits] = remove_z_field(b_z_field_bits,mac_meta)
% remove z-field (last 4 bits
%%
    if mac_meta.z == 1
        b_field_bits = b_z_field_bits(1:end-4);
    else
        b_field_bits = b_z_field_bits;
    end
end