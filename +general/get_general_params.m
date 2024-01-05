function [general_params] = get_general_params(mac_meta)
%   get general parameters: Data Rate, Symbol Rate, etc...
    mod_struct = general.configuration_to_mod_scheme(mac_meta);
    [num_t_field_bits,num_b_field_bits,num_x_field_bits] = mac_layer.calc_num_bits(mac_meta,mod_struct);
    general_params.SymbolRate = 480/(0.01/24);
    general_params.raised_cosine_length_symbols = 10;
    general_params.gauss_length = 4;
    general_params.viterbi_traceback_depth = 20;
    general_params.samples_per_symbol = 1*mac_meta.Oversampling;
    general_params.SamplingRate = general_params.SymbolRate*general_params.samples_per_symbol;

    % size of parameters in A-Field (fixed)
    general_params.a_field.header = 8;
    general_params.a_field.size_rcrc = 16;
    switch mac_meta.s
        case 0
            general_params.s_field_size = 32;
        case 1
            general_params.s_field_size = 32+16;
    end

    general_params.packet_size = general_params.samples_per_symbol*(general_params.s_field_size*1+(num_t_field_bits+general_params.a_field.header+general_params.a_field.size_rcrc)/mod_struct.a_field_bits_per_symbol+(num_b_field_bits+num_x_field_bits)/mod_struct.b_z_field_bits_per_symbol);
    if isequal(mac_meta.Configuration, '1a')
        general_params.packet_size = general_params.packet_size + general_params.viterbi_traceback_depth*general_params.samples_per_symbol;
    end

end