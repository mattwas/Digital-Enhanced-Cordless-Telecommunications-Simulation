clear all; close all;

%%
bits_orig = randi([0 1],150*10,1);
bits = reshape(bits_orig,3,[]);

i_comp(1) = 1;
q_comp(1) = 0;
for i=1:size(bits,2)
    i_comp(i+1) = i_comp(i)*cos(phaselookup_pi_8(bits(:,i)))-q_comp(i)*sin(phaselookup_pi_8(bits(:,i)));
    q_comp(i+1) = i_comp(i)*sin(phaselookup_pi_8(bits(:,i)))+q_comp(i)*cos(phaselookup_pi_8(bits(:,i)));
end

iq = i_comp + 1i*q_comp;
iq(1) = [];
scatterplot(iq)

iq = iq.';

a_field_mod = comm.DPSKModulator( ...
    2^3, ...
    pi/(2^3),...
    BitInput=1);

iq_dpsk = a_field_mod(bits_orig);

a_field_demod  = comm.DPSKDemodulator( ...
    2^3, ...
    pi/(2^3),...
    BitOutput=1);

bits_rv = a_field_demod(iq);
bits_rv_2 = a_field_demod(iq_dpsk);

isequal(bits_orig, bits_rv_2)


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
