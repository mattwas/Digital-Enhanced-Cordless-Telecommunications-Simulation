function [samples_out] = dect_undo_pulse_shaping(samples_in, mac_meta)
% This function undos the pulse shaping according to the DECT Specification

        general_params = general.get_general_params(mac_meta);
        pulse_shaping_filter = comm.RaisedCosineReceiveFilter(...
                    "RolloffFactor",0.5,...
                    "FilterSpanInSymbols",general_params.raised_cosine_length_symbols,...
                    "InputSamplesPerSymbol",general_params.samples_per_symbol,...
                    "DecimationFactor",general_params.samples_per_symbol);

        samples_extended = [samples_in; zeros(0.5*general_params.samples_per_symbol*general_params.raised_cosine_length_symbols,1)];
        samples_filtered = pulse_shaping_filter(samples_extended);
        samples_filtered(1:0.5*general_params.raised_cosine_length_symbols) = [];  

        % Bring the Power back
        current_rms = rms(samples_filtered);
        samples_out = samples_filtered./current_rms;

        % Debugging
        % samples_out = samples_in;
end