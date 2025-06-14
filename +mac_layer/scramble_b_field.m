function [scrambled_data] = scramble_b_field(tdma_frame_num, b_field_bits)
% scramble the data of the packet with the defined sequence in the MAC
% Layer
%%
    n_bits_b_field = numel(b_field_bits);
    
%% calculate scrambling sequence according to p. 101 MAC Layer
    % Check if Frame number is correct
    if tdma_frame_num < 0 || tdma_frame_num > 7
        error('tdma_frame_no has to be between 0 and 7')
    end
    
    % initiate the shift register according to frame number
    f_str = dec2bin(tdma_frame_num);
    [num, bits] = size(f_str);
    f = str2num(f_str(:));
    f = reshape(f,num,bits);
    switch numel(f)
        case 2
            f = [0 f(1:end)];
        case 1
            f = [0 0 f(1:end)];
    end
    f = flip(f);
    q = [f 1 1];
    
    scramb_seq = zeros(n_bits_b_field,1);     % sequence is 248 bits long
    inversion_mechanism_flag = 1;
    for i=1:n_bits_b_field
        if inversion_mechanism_flag == 0
            scramb_seq(i) = q(end);
        else
            scramb_seq(i) = ~q(end);
        end
        q_xor = xor(q(2),q(end));
        if sum(q) == 5
            inversion_mechanism_flag = ~inversion_mechanism_flag;
        end
        q = circshift(q,1);
        q(1) = q_xor;
    end
     
    scrambled_data = xor(scramb_seq, b_field_bits);

end


