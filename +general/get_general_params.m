function [general_params] = get_general_params(mac_meta)
%   get general parameters: Data Rate, Symbol Rate, etc...
    
    general_params.SymbolRate = 480/(0.01/24);
    general_params.samples_per_symbol = 8*mac_meta.Oversampling;
    general_params.SamplingRate = general_params.SymbolRate*general_params.samples_per_symbol;
end