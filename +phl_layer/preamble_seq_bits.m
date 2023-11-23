function [sync_seq_out] = preamble_seq_bits(mac_meta, transmission_type)
% create the preamble sequence according to standard
    sync_seq = [1; 0; 1; 0; 1; 0; 1; 0; 1; 0; 1; 0; 1; 0; 1; 0; 1; 1; 1; 0; 1; 0; 0; 1; 1; 0; 0; 0; 1; 0; 1; 0];
if mac_meta.s == 0
    % standard preamble
    if transmission_type == "RFP"
        sync_seq = sync_seq;
    elseif transmission_type == "PP"
        sync_seq = sync_seq.*(-1)+1;
    else
        error('transmission type not defined')
    end
elseif mac_meta.s == 16
    % prolonged preamble; first 16 bit sequence gets repeated
    sync_seq = [sync_seq(1:16); sync_seq];
    if transmission_type == "RFP"
        sync_seq = sync_seq;
    elseif transmission_type == "PP"
        sync_seq = sync_seq.*(-1)+1;
    else
        error('transmission type not defined')
    end
else
    error('parameter s not defined');
end

sync_seq_out = sync_seq;
end