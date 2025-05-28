function [decoded_bits] = turbo_dec(mac_meta, enc_b_field_bits)
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

%%
    % reverse mapping of the interleaver
    deinterleaver_idx = zeros(length(interleaver_idx),1);
    deinterleaver_idx(interleaver_idx) = 1:length(interleaver_idx);

    % Separate the encoded stream
    % Remember: encoded as [X_k; Y_k; Y'_k], reshape back
    total_len = length(enc_b_field_bits);
    L = total_len / 3;

    enc_b_field_bits_depunctured = depuncture(enc_b_field_bits);

    X_k        = enc_b_field_bits_depunctured(1:3:end);
    Y_k        = enc_b_field_bits_depunctured(2:3:end);
    Y_prime_k  = enc_b_field_bits_depunctured(3:3:end);

    % Reinsert padded zeros at the beginning
    X_k_padded = [zeros(K_new - K, 1); X_k];
    Y_k_padded = [zeros(K_new - K, 1); Y_k];
    Y_prime_k_padded = [zeros(K_new - K, 1); Y_prime_k];

    % Setup APP decoders
    dec1 = comm.APPDecoder(...
        'TrellisStructure', trellis, ...
        'Algorithm', 'Max*', ...
        'CodedBitLLROutputPort', false, ...
        'TerminationMethod', 'Truncated');

    dec2 = comm.APPDecoder(...
        'TrellisStructure', trellis, ...
        'Algorithm', 'Max*', ...
        'CodedBitLLROutputPort', false, ...
        'TerminationMethod', 'Truncated');

    % Initial LLRs
    L_a1 = zeros(K_new, 1);  % a priori info
   
    num_iterations = 6;
    for i = 1:num_iterations
        % ---- Decoder 1 ----
        L_e1 = dec1(X_k_padded + L_a1, Y_k_padded);
        L_int = L_e1 - L_a1;

        % ---- Interleave ----
        L_int_interleaved = L_int(interleaver_idx);

        % ---- Decoder 2 ----
        L_e2 = dec2(X_k_padded(interleaver_idx) + L_int_interleaved, Y_prime_k_padded);
        L_int2 = L_e2 - L_int_interleaved;

        % ---- Deinterleave extrinsic info ----
        L_a1 = zeros(K_new, 1);
        L_a1(deinterleaver_idx) = L_int2;  % becomes a priori for next round
    end

    % Final hard decision
    decoded_bits_padded = L_e1 < 0;
    decoded_bits = decoded_bits_padded((K_new - K + 1):end);

    %% Depuncture (if needed)
    function bit_field_depunctured = depuncture(bit_field)
    if mac_meta.code_rate ~= 1/3
        % Length of encoded block before puncturing
        total_length = 3 * K;

        % Create full length with NaNs (treated as erasures)
        depunctured = NaN(total_length, 1);

        % Create puncturing pattern/ calculate the puncturing indices
        puncturing_vec_ = zeros(numel(puncturing_vec),total_length/puncturing_block_length);
        
        k = 1:1:total_length/puncturing_block_length;

        puncturing_vec_(:,k) = puncturing_vec + (puncturing_block_length * (k-1));

        puncturing_vec = reshape(puncturing_vec_,[],1);

        % Fill known values (non-punctured)
        depunctured_mask = true(total_length, 1);
        depunctured_mask(puncturing_vec) = false;

        depunctured(depunctured_mask) = bit_field;

        bit_field_depunctured = depunctured;
    end
end

end
