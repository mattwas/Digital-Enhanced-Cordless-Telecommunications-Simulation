function [turbo_code_params] = turbo_code_params(mac_meta, size_of_b_field)
%turbo_code_params sets parameters for convolutional code, interleaver and
%puncturing
%   The convolutional code itself is according to the Turbo Code specified
%   the rest was created by myself because it would be to much work to
%   implement the remainder, since it is not realy tested
   
%% Convolutional Code
    trellis = poly2trellis(5,[37 25], 37); % trellis defined in MAC

%% Find a block length
    r_fix = 1/3;

    M_prime = 5;
    K = size_of_b_field * mac_meta.code_rate;

    K = floor(K);
    
    if mod(K, M_prime) == 0
        K_new = K;
        n = K / M_prime;
    else
        n = ceil(K/M_prime);
        if mod(n,2) ~= 0    % n has to be even
            n = n + 1;
        end 
        % new block size 
        K_new = n * M_prime;
    end

    % K_diff = K_new - K;

    int_idx = inner_interleaving();

%% puncturing
%code puncturing for the turbo coder to apply adaptive code rates
    code_rate = mac_meta.code_rate;
    mod_struct = general.configuration_to_mod_scheme(mac_meta);
    mod_scheme = mod_struct.b_z_field_modulation;

    adaptive_code_rates = [1; 0.8; 0.75; 0.6; 0.5; 0.4; 1/3];
    puncturing_vec = [];
    puncturing_block_length = [];
    num_of_punc = [];
    punc_adaptive_code_rate_diff = [];

    if ~ismember(mac_meta.code_rate, adaptive_code_rates)
        error('code rate is not standard cb_field_bits compliant');
    end
   
    switch code_rate
        case 0.4
            puncturing_vec = [5; 12];
            num_of_punc = numel(puncturing_vec);
            puncturing_block_length = 12;
        case 0.5
            puncturing_vec = [3; 5];
            num_of_punc = numel(puncturing_vec);
            puncturing_block_length = 6;
        case 0.6
            if ismember(mod_scheme, ["pi/8-D8PSK"; "64-QAM"])
                puncturing_vec = [3; 5; 8; 9; 11; 12; 15; 17; 21; 24; 26; 27; 29; 30; 32; 35];
            else
                puncturing_vec = [3; 5; 8; 9; 12; 15; 17; 20; 21; 24; 26; 27; 29; 30; 32; 36];
            end
                num_of_punc = numel(puncturing_vec);
                puncturing_block_length = 36;
        case 0.75
            puncturing_vec = [3; 5; 8; 9; 11; 12; 14; 15; 17; 18; 20; 21; 23; 26; 27];
            num_of_punc = numel(puncturing_vec);
            puncturing_block_length = 27;
        case 0.8
            puncturing_vec = [3; 5; 8; 9; 11; 12; 14; 15; 17; 18; 20; 21; 23; 24];
            num_of_punc = numel(puncturing_vec);
            puncturing_block_length = 24;

    end
    
    if code_rate == 0.33
        punc_adaptive_code_rate_diff = 1;

    else
        punc_adaptive_code_rate_diff = puncturing_block_length/(puncturing_block_length-num_of_punc);
    end

%%
    turbo_code_params.useful_bits = K;
    turbo_code_params.useful_bits_new = K_new;
    turbo_code_params.interleaver.indices = int_idx;
    turbo_code_params.conv_code_trellis = trellis;
    turbo_code_params.puncturing.block_length = puncturing_block_length;
    turbo_code_params.puncturing.puncturing_vec = puncturing_vec;

%% Interleaver function DECT
    function [interleaver_idx] = inner_interleaving()
        s = 0;                                      % offset
        p = M_prime + 1;
        k = 0:1:K_new-1;                            % p = constraint length (5) + 1
        
        K_diff = K_new - K;

        interleaver_idx = zeros(1,K_new);

        % The basic algorithm only works if block size K is a multiple of
        % M_prime (in this case p = M_prime + 1)
        if mod(K, M_prime) == 0                     
            % check if K and p are relative prime 
            if gcd(p,K) == 1
                interleaver_idx(k+1) = mod(s + k * p, K) + 1;  % apply MATLABSHIFT (+1)

            else
                error('interleaver not working');

            end

        else
            % identity function for 0 < k < K_diff
            interleaver_idx(1:K_diff) = 1:K_diff;

            I(k+1) = mod(s + k * p, K) + 1;

            interleaver_idx(K_diff+1:K_new) = K_diff + I(1:K_new-K_diff);

        end
    end

end