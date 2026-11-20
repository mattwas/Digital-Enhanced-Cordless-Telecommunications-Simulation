function [interleaver_idx, params] = b_field_interleaver_idx(mac_meta, K)
%B_FIELD_INTERLEAVER_IDX Turbo-Like B-field binary interleaver
%   Index vector of the B-field binary interleaver according to
%   ETSI EN 300 175-3, Annex I.4 (Turbo-Like interleaver L(k)).
%
%   The interleaver is applied to the protected (turbo encoded and
%   punctured) B-field bits:
%       interleaving:    y = x(interleaver_idx)        (Y(k) = X(L(k)))
%       deinterleaving:  x(interleaver_idx) = y
%
%   interleaver_idx is 1-based (L(k) + 1), K is the B-field size in bits.
%
%   L(k) = I_{p,q}^{(j)}(k), iteration j (equation I.28):
%       L0^{(j)}(k)      = [ -k - p * I^{(j-1)}(k) ]_K ,   I^{(0)}(k) = k
%       I_{p,q}^{(j)}(k) = [ K - p + k + q * p * L0^{(j)}(k) ]_K

%% parameters {p,q,j} according to tables I.9 and I.10
    mod_struct = general.configuration_to_mod_scheme(mac_meta);
    bits_per_symbol = mod_struct.b_z_field_bits_per_symbol;

    %                  m   K     p    q  j
    switch mac_meta.a
        case '80'   % Table I.9: P80 (double slot)
            tab = [ 1   800   10   2  1;    % GMSK, DBPSK
                    2  1600   20   2  3;    % DQPSK
                    3  2400   15   2  1;    % D8PSK
                    4  3200   20   2  3;    % 16-QAM
                    6  4800   60   2  3];   % 64-QAM
        case '32'   % Table I.10: P32 (full slot)
            tab = [ 1   320   20   2  1;    % GMSK, DBPSK
                    2   640   80   2  1;    % DQPSK
                    3   960   15   2  1;    % D8PSK
                    4  1280   40   2  3;    % 16-QAM
                    6  1920  240   2  1];   % 64-QAM
        otherwise
            error("B-field interleaving is only defined for protected P32 and P80 packets");
    end

    row = tab(tab(:,1) == bits_per_symbol, :);
    if isempty(row)
        error("no B-field interleaving parameters for %d bits per symbol", bits_per_symbol);
    end

    K_tab = row(2);
    p = row(3);
    q = row(4);
    j = row(5);

    if nargin < 2
        K = K_tab;
    elseif K ~= K_tab
        error("B-field size K = %d does not match interleaver size %d", K, K_tab);
    end

%% interleaving algorithm (equations I.26 - I.28)
    k = (0:K-1).';
    I = k;                                      % I^{(0)}(k) = k
    for iter = 1:j
        L0 = mod(-k - p * I, K);
        I  = mod(K - p + k + q * p * L0, K);
    end

    interleaver_idx = I + 1;                    % MATLAB indexing

    params.K = K;
    params.p = p;
    params.q = q;
    params.j = j;
end
