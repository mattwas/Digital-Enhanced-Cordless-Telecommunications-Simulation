function [data_enc, data] = turbo_enc(mac_meta)
%turbo encoder using the defined trellis for the convolutional decoder and
%a prelimanary puncturing not according to standard
%%  extract parameters
    mod_struct = general.configuration_to_mod_scheme(mac_meta);
    [~,num_b_field_bits,~] = mac_layer.calc_num_bits(mac_meta, mod_struct);
    
    turbo_code_params = mac_layer.turbo_code_params(mac_meta, num_b_field_bits);
    intIndices = turbo_code_params.interleaver.indices;
    outIndices = turbo_code_params.puncturing_indices;
    trellis = turbo_code_params.conv_code_trellis;
    blk_len = turbo_code_params.useful_bits;
    
%%  create turbo encoder, generate data and encode
    turboEnc = comm.TurboEncoder('TrellisStructure',trellis);
    turboEnc.InterleaverIndices = intIndices;
    turboEnc.OutputIndicesSource = 'Property';
    turboEnc.OutputIndices = outIndices;

    % generate data
    data = randi([0 1], blk_len, 1);
    
    % encode data
    data_enc = turboEnc(data);

end