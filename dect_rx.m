classdef dect_rx < handle
    %DECT_RX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
            mac_meta
            packet_data;
    end

    methods
        function obj = dect_rx()
            obj.mac_meta = struct('Configuration','1a','a', '32', 'K',0,'L', 0, 'M', 0,'N', 1, 's', 0, 'z', 0,'Oversampling',1, "transmission_type", "RFP");
            obj.packet_data = general.set_general_params(obj.mac_meta);

        end
    end

    methods 
        
        function outputArg = decode_packet(obj,samples)
            mac_meta_arg = obj.mac_meta;
            packet_data_arg = obj.packet_data;
            packet_start_idx = phl_layer.sync(mac_meta_arg,samples);


        end
    end
end

