function [packet_data] = set_general_params(mac_meta)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
mod_index = 2*(288e3)*(0.01/24)/480;
packet_data.r_sym = 480/(0.01/24);
packet_data.samples_per_symbol = 8*mac_meta.Oversampling;
packet_data.SamplingRate = packet_data.r_sym*packet_data.samples_per_symbol;
end