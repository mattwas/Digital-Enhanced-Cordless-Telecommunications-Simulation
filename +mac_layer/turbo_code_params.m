function [turbo_code_params] = turbo_code_params(mac_meta, size_of_b_field)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    punc_pattern = mac_layer.adaptive_code_puncturing(mac_meta);
    puncturing_block_length = punc_pattern{1};
    num_of_punctures = punc_pattern{2};
    punctures_vec = punc_pattern{3};
    multiplying_rate_adaptive_code_rate = punc_pattern{4};
    code_rate = mac_meta.code_rate;
    
%% Convolutional Code

    trellis = poly2trellis(5,[37 25], 37); % trellis for conv coders in DECT spec
    n = log2(trellis.numOutputSymbols);
    mLen = log2(trellis.numStates);     % also refers to number of tail bits
    multiplying_rate = 0.75;            % multiplying rate needed to fit bits into the b-field    
    % blkLen is calculated 
    blkLen = ((size_of_b_field*(1/multiplying_rate)*multiplying_rate_adaptive_code_rate/(2*n))-mLen);

%% INTERLEAVER
    % Random Interleaver, DECT Inteleaver does not work at the Moment
    intrlv_state = 873426;
    ind_data = (1:1:blkLen)';
    intIndices  = randintrlv(ind_data, intrlv_state);
%% Puncturing
    outindices = getTurboIOIndices(blkLen,n,mLen);
    if ~(code_rate == 0.33)
        outindices = reshape(outindices,puncturing_block_length,[]);
        punctures_vec = flip(punctures_vec);
        for i = 1:numel(punctures_vec)
            outindices(punctures_vec(i),:) = [];
        end
        outindices = reshape(outindices,[],1);
    end


%%
    turbo_code_params.interleaver.indices = intIndices;
    turbo_code_params.interleaver.state = intrlv_state;
    turbo_code_params.conv_code_trellis = trellis;
    turbo_code_params.puncturing_indices = outindices;
    turbo_code_params.useful_bits = blkLen;

%% Interleaver function DECT

    function [interleaver_ind] = inner_interleaving(size_useful_bits)
        
        s = 0;                                  % offset
        p = 6;                                  % p = constraint length (5) + 1
        K = size_useful_bits;
        k = 0:1:K-1;
        if gcd(p,K) == 1
            interleaver_ind = zeros(1,K);
            interleaver_ind(k+1) = mod(s+k*p,K)+1;  % apply MATLABSHIFT (+1)
        else
            error('interleaver not working');
        end
    end
end