function [encData, data] = turbo_enc(mac_meta)
    
    
    
    
    %UNTITLED Summary of this function goes here
    %   Detailed explanation goes here
    mod_struct = general.configuration_to_mod_scheme(mac_meta);
    [~,num_b_field_bits,~] = mac_layer.calc_num_bits(mac_meta, mod_struct);
    turbo_code_params = mac_layer.turbo_code_params(mac_meta, num_b_field_bits);
    intIndices = turbo_code_params.interleaver.indices;
    outIndices = turbo_code_params.puncturing_indices;
    trellis = turbo_code_params.conv_code_trellis;
    blk_len = turbo_code_params.useful_bits;
    data = randi([0 1], blk_len, 1);
    
    
    turboEnc = comm.TurboEncoder('TrellisStructure',trellis);
    turboEnc.InterleaverIndices = intIndices;
    turboEnc.OutputIndicesSource = 'Property';
    turboEnc.OutputIndices = outIndices;
    
    encData = turboEnc(data);   % Encode



end