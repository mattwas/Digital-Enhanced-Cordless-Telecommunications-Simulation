function [samples] = dect_dpsk_modulation(bits, bit_per_symbol)

    i_comp = zeros(numel(bits)/bit_per_symbol,1);
    q_comp = i_comp;

if bit_per_symbol == 1
    % PI/2 DBPSK
    i_comp(1) = 1;
    q_comp(1) = 0;
    for i=1:length(bits)
        phase = phaselookup_pi_2(bits(i));
        i_comp(i+1) = -q_comp(i)*sin(phase);
        q_comp(i+1) = i_comp(i)*sin(phase);
    end
    
    samples = i_comp +1i*q_comp;
    samples(1) = [];
    %samples = samples.';
elseif bit_per_symbol == 2

    % PI/4 DQPSK
    bits = reshape(bits,2,[]);

    i_comp(1) = 1;
    q_comp(1) = 0;
    for i=1:size(bits,2)
        i_comp(i+1) = i_comp(i)*cos(phaselookup_pi_4(bits(:,i)))-q_comp(i)*sin(phaselookup_pi_4(bits(:,i)));
        q_comp(i+1) = i_comp(i)*sin(phaselookup_pi_4(bits(:,i)))+q_comp(i)*cos(phaselookup_pi_4(bits(:,i)));
    end
    
    samples = i_comp + 1i*q_comp;
    samples(1) = [];
    %samples = samples.';
elseif bit_per_symbol == 3
    % PI/8 D8PSK
    bits = reshape(bits,3,[]);

    i_comp(1) = 1;
    q_comp(1) = 0;
    for i=1:size(bits,2)
        i_comp(i+1) = i_comp(i)*cos(phaselookup_pi_8(bits(:,i)))-q_comp(i)*sin(phaselookup_pi_8(bits(:,i)));
        q_comp(i+1) = i_comp(i)*sin(phaselookup_pi_8(bits(:,i)))+q_comp(i)*cos(phaselookup_pi_8(bits(:,i)));
    end
    
    samples = i_comp + 1i*q_comp;
    samples(1) = [];    
    %samples = samples.';
end



% Phase Definition according to Spec

    function [phase] = phaselookup_pi_2(bit)
        if bit == 0
            phase = -pi/2;
        elseif bit == 1
            phase = +pi/2;
        end
    end


    function [phase] = phaselookup_pi_4(bit)
        if bit == [1; 1]
            phase = -3*pi/4;
        elseif bit == [0; 1]
            phase = +3*pi/4;
        elseif bit == [0; 0]
            phase = pi/4;
        elseif bit == [1; 0]
            phase = -pi/4;
        end
    end

    function [phase] = phaselookup_pi_8(bit)
        if bit == [0; 0; 0]
            phase = pi/8;
        elseif bit == [0; 0; 1]
            phase = 3*pi/8;
        elseif bit == [0; 1; 1]
            phase = 5*pi/8;
        elseif bit == [0; 1; 0]
            phase = 7*pi/8;
        elseif bit == [1; 1; 0]
            phase = -7*pi/8;
        elseif bit == [1; 1; 1]
            phase = -5*pi/8;
        elseif bit == [1; 0; 1]
            phase = -3*pi/8;
        elseif bit == [1; 0; 0]
            phase = -pi/8;
        end


    end

end