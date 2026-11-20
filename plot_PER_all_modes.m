function plot_PER_all_modes(results, field)
% PLOT_PER_ALL_MODES  PER vs. SNR for all DECT configurations (style of
% Fig. 2 in the DECT-2020 NR URLLC paper).
%
%   plot_PER_all_modes(results)            plots B-field, A-field and packet PER
%   plot_PER_all_modes(results, field)     field = "B", "A" or "packet"
%   plot_PER_all_modes("results/PER_all_modes.mat", ...)  loads the file first
%
%   results is the struct written by main_PER_all_modes.m

    if isstring(results) || ischar(results)
        tmp     = load(results, "results");
        results = tmp.results;
    end

    if nargin < 2
        field = ["B" "A" "packet"];
    end

    set(groot,'defaultAxesTickLabelInterpreter','latex');
    set(groot,'defaultLegendInterpreter','latex');
    set(groot,'defaultTextInterpreter','latex');

    for f = string(field)
        switch f
            case "B"
                per       = results.PER_b_field;
                fig_title = "PER B-Field";
            case "A"
                per       = results.PER_a_field;
                fig_title = "PER A-Field";
            case "packet"
                per       = results.PER_packet;
                fig_title = "PER Packet (A- and B-Field)";
            otherwise
                error("field must be ""B"", ""A"" or ""packet""");
        end
        plot_one(results, per, fig_title);
    end
end

function plot_one(results, per, fig_title)

    snr     = results.snr_db_vec;
    cfgs    = results.configurations;
    n_cfg   = size(cfgs,1);

    markers = {'s','v','o','+','x','d','^','*'};
    colors  = lines(n_cfg);

    figure;
    ax = gca;
    hold(ax, 'on');

    leg = strings(1, n_cfg);
    for c = 1:n_cfg
        y = per(c,:);

        % PER = 0 cannot be shown on a log axis, the curve ends at the
        % last SNR point with at least one error
        y(y == 0) = NaN;

        % first half solid, second half dashed (as in the paper)
        if c <= ceil(n_cfg/2)
            ls = '-';
        else
            ls = '--';
        end

        semilogy(ax, snr, y, ...
            'LineStyle', ls, ...
            'Marker', markers{mod(c-1, numel(markers))+1}, ...
            'Color', colors(c,:), ...
            'MarkerFaceColor', 'none', ...
            'MarkerSize', 5, ...
            'LineWidth', 1);

        leg(c) = sprintf("Conf. %s, %s, %d bit", cfgs{c,1}, cfgs{c,2}, results.n_b_field_bits(c));
    end

    set(ax, 'YScale', 'log');
    grid(ax, 'on');
    grid(ax, 'minor');
    box(ax, 'on');

    % x-limits: from first SNR point to the last one with errors (+ margin)
    last_idx = find(any(per > 0, 1), 1, 'last');
    if isempty(last_idx)
        last_idx = numel(snr);
    end
    xlim(ax, [snr(1), min(snr(end), snr(last_idx) + 2)]);
    ylim(ax, [1e-6 2]);
    yticks(ax, 10.^(-6:2:0));

    xlabel(ax, "Signal-to-Noise Ratio $E_s/N_0$ (dB)");
    ylabel(ax, "Packet Error Rate");
    title(ax, sprintf("%s, AWGN, $N_{Rx}$ = %d, code rate %g", fig_title, results.N_Rx, results.code_rate));
    legend(ax, leg, 'Location', 'northoutside', 'NumColumns', 2);
end
