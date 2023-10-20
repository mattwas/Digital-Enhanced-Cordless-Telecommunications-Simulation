function [s_field_cell] = preamble_seq(mac_meta, transmission_type)
% create the preamble sequence according to standard

s_field_cell = cell(1);
if mac_meta.s == 0
    % standard preamble
    if transmission_type == "RFP"
        sync_seq = [1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 1 1 0 1 0 0 1 1 0 0 0 1 0 1 0];
    elseif transmission_type == "PP"
        sync_seq = [0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 0 0 1 0 1 1 0 0 1 1 1 0 1 0 1];
    else
        error('transmission type not defined')
    end


elseif mac_meta.s == 16
    % prolonged
    % to do
    error('prolonged preamble not implemented yet')

else
    error('parameter s not defined');
end

s_field_cell{1} = sync_seq;

end