function [sync_seq_out] = preamble_seq(mac_meta, transmission_type)
% create the preamble sequence according to standard

if mac_meta.s == 0
    % standard preamble
    if transmission_type == "RFP"
        sync_seq = [1; 0; 1; 0; 1; 0; 1; 0; 1; 0; 1; 0; 1; 0; 1; 0; 1; 1; 1; 0; 1; 0; 0; 1; 1; 0; 0; 0; 1; 0; 1; 0];
    elseif transmission_type == "PP"
        sync_seq = [0; 1; 0; 1; 0; 1; 0; 1; 0; 1; 0; 1; 0; 1; 0; 1; 0; 0; 0; 1; 0; 1; 1; 0; 0; 1; 1; 1; 0; 1; 0; 1];
    else
        error('transmission type not defined')
    end
elseif mac_meta.s == 16
    % prolonged
    error('prolonged preamble not implemented yet')
else
    error('parameter s not defined');
end

sync_seq_out = sync_seq;
end