function [samples_out] = dect_pulse_shaping(samples_in, mac_meta)
%This function applys pulse shaping to the samples according to the
%Physical Layer specifications
%%
    general_params = general.get_general_params(mac_meta);

    % pulse shaping filter according to standard
    pulse_shaping_filter = comm.RaisedCosineTransmitFilter(...
        "RolloffFactor",0.5,...
        "FilterSpanInSymbols",general_params.raised_cosine_length_symbols,...
        "OutputSamplesPerSymbol",general_params.samples_per_symbol);
%%
    % prolong the samples, cause of the filter delay
    samples_extended = [samples_in; zeros(0.5*general_params.raised_cosine_length_symbols,1)];
    samples_filtered = pulse_shaping_filter(samples_extended);
    samples_filtered(1:0.5*general_params.samples_per_symbol*general_params.raised_cosine_length_symbols) = [];


    % power boost to bring the power to 1 (0 dB). The attentuation of the
    % filter is getting reversed
    power_after_filter = power(rms(samples_filtered), 2);
    samples_out = samples_filtered./ sqrt(power_after_filter);

    % for debugging
    % samples_out = samples_filtered;
end