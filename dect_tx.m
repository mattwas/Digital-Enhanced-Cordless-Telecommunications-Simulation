classdef dect_tx < handle
    properties
            mac_meta
            packet_data;
    end

    methods
        function obj = dect_tx()
            obj.mac_meta = struct('Configuration','1a','a', '32', 'K',0,'L', 0, 'M', 0,'N', 1, 's', 0, 'z', 0);
            obj.packet_data = [];

        end
    end

    methods 
        function [samples_tx] = generate_packet(obj)
            mac_meta_arg = obj.mac_meta;

            mod_scheme_struct = mac_layer.configuration_to_mod_scheme(mac_meta_arg);
            [num_t_field_bits, num_b_field_bits, num_x_field_bits] = mac_layer.calc_num_bits(mac_meta_arg,mod_scheme_struct);


            % generate MAC Layer Data

            % generate A-Field bits
            % A-Field is 64/128/192 bits long and contains the Header (8
            % bits) the Tail (depending on modulation) and the Redundancy 
            % bits (16 bits)
            a_field_h_t_bits = randi([0 1], 8+num_t_field_bits,1);

            % generate B-Field bits
            b_field_bits = randi([0 1], num_b_field_bits, 1);

            % scramble B-Field and add XCRC and RCRC
            a_field_bits = mac_layer.calc_rcrc(a_field_h_t_bits);
            b_field_bits_scrambled = mac_layer.scramble_b_field(0,b_field_bits);
            b_x_field_bits = mac_layer.calc_xcrc(b_field_bits_scrambled, mod_scheme_struct);


            % PHL Layer

            s_field_bits = phl_layer.preamble_seq(mac_meta_arg,"RFP");
            packet_data = cell(3,1);
            packet_data{1} = s_field_bits;
            packet_data{2} = a_field_bits;
            packet_data{3} = b_x_field_bits;

            samples_tx = phl_layer.dect_modulate(packet_data, mod_scheme_struct);
            
            


        end
    end
end