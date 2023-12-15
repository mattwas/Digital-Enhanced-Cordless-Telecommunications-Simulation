function [general_params] = get_general_params(mac_meta)
%   get general parameters: Data Rate, Symbol Rate, etc...
    general_params.SymbolRate = 480/(0.01/24);
    general_params.raised_cosine_length_symbols = 10;
    general_params.gauss_length = 4;
    general_params.viterbi_traceback_depth = 20;
    general_params.samples_per_symbol = 2*mac_meta.Oversampling;
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
end