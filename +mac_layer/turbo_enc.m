function [enc_data, data] = turbo_enc(mac_meta)
%turbo encoder using the defined trellis for the convolutional decoder and
%a prelimanary puncturing not according to standard
%%  extract parameters
    mod_struct = general.configuration_to_mod_scheme(mac_meta);
    [~,num_b_field_bits,~] = mac_layer.calc_num_bits(mac_meta, mod_struct);
    
    turbo_code_params = mac_layer.turbo_code_params(mac_meta, num_b_field_bits);
    trellis = turbo_code_params.conv_code_trellis;
    K = turbo_code_params.useful_bits;
    K_new = turbo_code_params.useful_bits_new;
    interleaver_idx = turbo_code_params.interleaver.indices;

    puncturing_block_length =    turbo_code_params.puncturing.block_length;
    puncturing_vec              = turbo_code_params.puncturing.puncturing_vec;

%%  1/3 Turbo code
    data = randi([0 1], K, 1);
    X_k = data;

    X_k_padded = [zeros(K_new - K, 1); X_k];

    % keep the zeros at the beginning
    X_k_interleaved = zeros(K_new, 1);
    X_k_interleaved(1:(K_new - K)) = X_k_padded(1:(K_new - K));
    X_k_interleaved((K_new - K) + 1:end) = X_k_padded(interleaver_idx((K_new - K) + 1:end));
    
    rce1 = comm.ConvolutionalEncoder('TrellisStructure', trellis,...
        'TerminationMethod', 'Truncated');
    rce2 = comm.ConvolutionalEncoder('TrellisStructure', trellis, ...
        'TerminationMethod', 'Truncated');

    rce1_out = rce1(X_k_padded);

    rce2_out = rce2(X_k_interleaved);

    % only take the parity bits
    Y_k = rce1_out(2:2:end);
    Y_prime_k = rce2_out(2:2:end);

    % save encoded padded bits
    enc_padded_bits = [Y_k(1:(K_new - K)) Y_prime_k(1:(K_new - K))];

    % Puncture the added zeros
    Y_k(1:(K_new - K)) = [];
    Y_prime_k(1:(K_new - K)) = [];

    enc_data = reshape([X_k.'; Y_k.'; Y_prime_k.'], [], 1);

    if mac_meta.code_rate ~= 1/3
        % calculate the puncturing indices

        puncturing_blocks_int = floor(numel(enc_data)/puncturing_block_length);
        
        puncturing_vec_ = zeros(numel(puncturing_vec),puncturing_blocks_int);
        
        k = 1:1:puncturing_blocks_int;

        puncturing_vec_(:,k) = puncturing_vec + (puncturing_block_length * (k-1));

        puncturing_vec_ = reshape(puncturing_vec_,[],1);

        if mod(numel(enc_data), puncturing_block_length) ~= 0

            puncturing_block_residual = (numel(enc_data)-puncturing_blocks_int * numel(puncturing_vec)) - K/mac_meta.code_rate;

            k = 1:1:puncturing_block_residual;

            puncturing_vec_(k + puncturing_blocks_int * numel(puncturing_vec)) = puncturing_vec(k) + (puncturing_block_length * (puncturing_blocks_int));
        end
        
        % do the puncturing according to the index
        enc_data(puncturing_vec_) = [];
    end

end