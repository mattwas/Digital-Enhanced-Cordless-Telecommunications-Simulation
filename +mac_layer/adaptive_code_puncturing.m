function [punc_pattern] = adaptive_code_puncturing(mac_meta)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    code_rate = mac_meta.code_rate;
    mod_struct = general.configuration_to_mod_scheme(mac_meta);
    mod_scheme = mod_struct.b_z_field_modulation;
    adaptive_code_rates = [1;0.8; 0.75; 0.6; 0.5; 0.4; 0.33];
    punc_pattern = cell(4,1);
    punc_vec = [];
    punc_block_length = [];
    num_of_punc = [];
    punc_adaptive_code_rate_diff = [];
    if ~ismember(mac_meta.code_rate, adaptive_code_rates)
        error('code rate is not standard cb_field_bitsompliant');
    end
   

    %%
    switch code_rate
        case 0.4
            punc_vec = [5; 12];
            num_of_punc = numel(punc_vec);
            punc_block_length = 12;
        case 0.5
            punc_vec = [3; 5];
            num_of_punc = numel(punc_vec);
            punc_block_length = 6;
        case 0.6
            if ismember(mod_scheme, ["pi/8-D8PSK"; "64-QAM"])
                punc_vec = [3; 5; 8; 9; 11; 12; 15; 17; 21; 24; 26; 27; 29; 30; 32; 35];
            else
                punc_vec = [3; 5; 8; 9; 12; 15; 17; 20; 21; 24; 26; 27; 29; 30; 32; 36];
            end
                num_of_punc = numel(punc_vec);
                punc_block_length = 36;
        case 0.75
            punc_vec = [3; 5; 8; 9; 11; 12; 14; 15; 17; 18; 20; 21; 23; 26; 27];
            num_of_punc = numel(punc_vec);
            punc_block_length = 27;
        case 0.8
            punc_vec = [3; 5; 8; 9; 11; 12; 14; 15; 17; 18; 20; 21; 23; 24];
            num_of_punc = numel(punc_vec);
            punc_block_length = 24;

    end
    if code_rate == 0.33
        punc_adaptive_code_rate_diff = 1;
    else
        punc_adaptive_code_rate_diff = punc_block_length/(punc_block_length-num_of_punc);
    end
    punc_pattern{1} = punc_block_length;
    punc_pattern{2} = num_of_punc;
    punc_pattern{3} = punc_vec;
    punc_pattern{4} = punc_adaptive_code_rate_diff;

end