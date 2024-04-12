function [samples_combined] = antenna_combining(samples_antenna,mac_meta)
N_Rx = mac_meta.N_Rx;

%% simple Antenna Combining
    samples_combined = zeros(numel(samples_antenna(:,1)),1);

    for i = 1:N_Rx
        samples_combined = samples_combined + (1/mac_meta.N_Rx)*samples_antenna(:,i);
    end

end