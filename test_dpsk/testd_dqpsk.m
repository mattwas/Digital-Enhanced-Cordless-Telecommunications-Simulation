close all; clear all;

bits_orig = randi([0 1],1000,1);
bits = reshape(bits_orig,2,[]);

i_comp(1) = 1;
q_comp(1) = 0;
for i=1:size(bits,2)
    i_comp(i+1) = i_comp(i)*cos(phaselookup_pi_4(bits(:,i)))-q_comp(i)*sin(phaselookup_pi_4(bits(:,i)));
    q_comp(i+1) = i_comp(i)*sin(phaselookup_pi_4(bits(:,i)))+q_comp(i)*cos(phaselookup_pi_4(bits(:,i)));
end

iq = i_comp + 1i*q_comp;
iq(1) = [];
scatterplot(iq)

iq = iq.';

a_field_mod = comm.DPSKModulator( ...
    2^2, ...
    pi/(2^2),...
    BitInput=1);

iq_dpsk = a_field_mod(bits_orig);

a_field_demod  = comm.DPSKDemodulator( ...
    2^2, ...
    pi/(2^2),...
    BitOutput=1);

bits_rv = a_field_demod(iq);
bits_rv_2 = a_field_demod(iq_dpsk);
isequal(bits_orig,bits_rv)

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
