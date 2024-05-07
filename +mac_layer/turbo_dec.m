function [b_field_user_data] = turbo_dec(mac_meta, b_field_enc_bits)
    %UNTITLED Summary of this function goes here
    %   Detailed explanation goes here
    
    
    mod_struct = general.configuration_to_mod_scheme(mac_meta);
    [~,num_b_field_bits,~] = mac_layer.calc_num_bits(mac_meta, mod_struct);
    turbo_code_params = mac_layer.turbo_code_params(mac_meta, num_b_field_bits);
    intIndices = turbo_code_params.interleaver.indices;
    outIndices = turbo_code_params.puncturing_indices;
    trellis = turbo_code_params.conv_code_trellis;
    blk_len = turbo_code_params.useful_bits;
    turboDec = comm.TurboDecoder('TrellisStructure',trellis);
    turboDec.InputIndicesSource = 'Property';
    turboDec.InterleaverIndices = intIndices;
    turboDec.InputIndices = outIndices;
    b_field_user_data = turboDec(2*b_field_enc_bits-1);

end