function [samples_best_antenna] = antenna_selection(samples_antenna,mac_meta)
% Selecting the best Antenna by using MMSE on the preamble

    mse = zeros(1,mac_meta.N_Rx);
    preamble_samples = phl_layer.preamble_seq(mac_meta);
    auto_corr_metric = xcorr(preamble_samples);

    for i = 1:mac_meta.N_Rx
        cross_corr_metric = xcorr(samples_antenna(1:numel(preamble_samples),i), preamble_samples);
        mse(1,i) = sum(abs(cross_corr_metric-auto_corr_metric))/numel(auto_corr_metric);
    end
    [mmse, mmse_idx] = min(mse);
    samples_best_antenna = samples_antenna(:,mmse_idx);

end