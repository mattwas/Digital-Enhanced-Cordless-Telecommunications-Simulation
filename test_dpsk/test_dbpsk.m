clear all; close all;

%%
bits = randi([0 1],500,1);%[ 1;0;1;1;1;0;1;0;1;0;1;0;1;1;1;1];

i_comp(1) = 1;
q_comp(1) = 0;
for i=1:length(bits)
    phase = phaselookup(bits(i));
    i_comp(i+1) = -q_comp(i)*sin(phase);
    q_comp(i+1) = i_comp(i)*sin(phase);
end

iq = i_comp +1i*q_comp;
iq(1) = [];
scatterplot(iq)
iq = iq.';


a_field_mod = comm.DPSKModulator( ...
    2, ...
    pi/(2),...
    BitInput=1);

iq_dpsk = a_field_mod(bits);

a_field_demod  = comm.DPSKDemodulator( ...
    2, ...
    pi/(2^1),...
    BitOutput=1);
bits_rv = a_field_demod(iq);
bits_rv = ~bits_rv;
bits_rv = double(bits_rv);
bits_rv_2 = a_field_demod(iq_dpsk);


isequal(bits, bits_rv)


% % De-rotate
% y = y .* exp(-1i*ini_phase);
% % Demodulate
% normFactor = M/(2*pi); % normalization factor to convert from PI-domain to
% % linear domain
% % convert input signal angle to linear domain; round the value to get ideal
% % constellation points
% z = round((angle(y) .* normFactor));
% % move all the negative integers by M
% z(z < 0) = M + z(z < 0);



function [phase] = phaselookup(bit)
        if bit == 0
            phase = -pi/2;
        elseif bit == 1
            phase = +pi/2;
        end


end
