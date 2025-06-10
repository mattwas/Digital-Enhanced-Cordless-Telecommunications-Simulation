classdef dect_rx < handle
    %DECT_RX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
            mac_meta
            packet_data;
            synchronisation;
    end

    methods
        function obj = dect_rx(mac_meta_argin, sync_params)
            obj.mac_meta = mac_meta_argin;
            obj.packet_data = general.get_general_params(obj.mac_meta);
            obj.synchronisation.timing_offset = sync_params.timing_offset;
            obj.synchronisation.frequency_offset = sync_params.frequency_offset;

            obj.packet_data.a_field_bits_rv         = [];
            obj.packet_data.h_and_t_field_bits_rv   = [];
            obj.packet_data.b_z_field_bits_rv       = [];
            obj.packet_data.b_field_bits_rv         = [];
            obj.packet_data.b_field_bits_dec_rv     = [];
        end
    end

    methods 
        
        function [rcrc_correct, xcrc_correct] = decode_packet(obj, samples_rx)
            rcrc_correct = false;
            xcrc_correct = false;
            
 %%         Detection & Synchronisation
            [packet_start_idx, samples_rx_after_sync] = lib_rx.sync(obj.mac_meta,obj.synchronisation,samples_rx);
            obj.synchronisation.packet_start = packet_start_idx;

 %%         Demodulation
            [a_field_bits_rv, b_z_field_bits_rv] = phl_layer.dect_demodulate(samples_rx_after_sync,obj.mac_meta, obj.synchronisation);
            obj.packet_data.a_field_bits_rv = a_field_bits_rv;
            obj.packet_data.b_z_field_bits_rv = b_z_field_bits_rv;

%%          
            if ~isequal(a_field_bits_rv,0) && ~isequal(b_z_field_bits_rv,0)
                [b_field_bits_rv] = phl_layer.remove_z_field(b_z_field_bits_rv,obj.mac_meta);

                [h_and_t_bits_rv, error_rcrc] = mac_layer.check_rcrc(a_field_bits_rv);
                obj.packet_data.h_and_t_field_bits_rv = h_and_t_bits_rv;

                [b_bits_rv, error_xcrc] = mac_layer.check_xcrc(b_field_bits_rv,obj.mac_meta);

                b_bits_data_unscrambled_rv = mac_layer.scramble_b_field(0, b_bits_rv);
                obj.packet_data.b_field_bits_rv = b_bits_data_unscrambled_rv;

                % Turbo decoder
                if ~(obj.mac_meta.code_rate == 1)
                    b_bits_user_data_rv = mac_layer.turbo_dec(obj.mac_meta, b_bits_data_unscrambled_rv);
                    obj.packet_data.b_field_bits_dec_rv = b_bits_user_data_rv;
                else
                    obj.packet_data.b_field_bits_dec_rv = obj.packet_data.b_field_bits_rv;
                end
    
                if error_rcrc == 0
                    rcrc_correct = 1;
                end
    
                if error_xcrc == 0
                    xcrc_correct = 1;
                end
            end

        end
    end
end

