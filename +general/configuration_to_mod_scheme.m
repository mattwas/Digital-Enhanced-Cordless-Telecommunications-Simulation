function [mod_struct] = configuration_to_mod_scheme(mac_meta)
    configuration = mac_meta.Configuration;

    code_rate       = mac_meta.code_rate;

%%  Look up table for the DECT configuration    
    % look up table for the Configuration and Modulation Scheme according
    % to p. 47 PHL Layer

    % assumed that E/U mux is in U mode
        switch configuration
            case '1a'
                s_field_modulation = 'GFSK';
                a_field_bits_per_symbol = 1;
                a_field_modulation = 'GFSK';
                b_z_field_bits_per_symbol = 1;
                b_z_field_modulation = 'GFSK';
                code_rate_available = [1; 0.8; 0.75];
            case '1b'
                s_field_modulation = 'pi/2-DBPSK';
                a_field_bits_per_symbol = 1;
                a_field_modulation = 'pi/2-DBPSK';
                b_z_field_bits_per_symbol = 1;
                b_z_field_modulation = 'pi/2-DBPSK';
                code_rate_available = [1; 0.8; 0.75];
            case '2'
                s_field_modulation = 'pi/2-DBPSK';
                a_field_bits_per_symbol = 1;
                a_field_modulation = 'pi/2-DBPSK';
                b_z_field_bits_per_symbol = 2;
                b_z_field_modulation = 'pi/4-DQPSK';
                code_rate_available = [1; 0.8; 0.75; 0.6; 0.5];
            case '2b'
                s_field_modulation = 'pi/2-DBPSK';
                a_field_bits_per_symbol = 1;
                a_field_modulation = 'pi/2-DBPSK';
                b_z_field_bits_per_symbol = 2;
                b_z_field_modulation = 'pi/4-DQPSK';
                code_rate_available = [1; 0.8; 0.75; 0.6; 0.5];
            case '3'
                s_field_modulation = 'pi/2-DBPSK';
                a_field_bits_per_symbol = 1;
                a_field_modulation = 'pi/2-DBPSK';
                b_z_field_bits_per_symbol = 3;
                b_z_field_modulation = 'pi/8-D8PSK';
                code_rate_available = [1; 0.8; 0.75; 0.6; 0.5];
            case '3b'
                s_field_modulation = 'pi/2-DBPSK';
                a_field_bits_per_symbol = 1;
                a_field_modulation = 'pi/2-DBPSK';
                b_z_field_bits_per_symbol = 3;
                b_z_field_modulation = 'pi/8-D8PSK';
                code_rate_available = [1; 0.8; 0.75; 0.6; 0.5];
            case '4a'
                s_field_modulation = 'pi/2-DBPSK';
                a_field_bits_per_symbol = 2;
                a_field_modulation = 'pi/4-DQPSK';
                b_z_field_bits_per_symbol = 2;
                b_z_field_modulation = 'pi/4-DQPSK';
                code_rate_available = [1; 0.8; 0.75; 0.6; 0.5];
            case '4b'
                s_field_modulation = 'pi/2-DBPSK';
                a_field_bits_per_symbol = 3;
                a_field_modulation = 'pi/8-D8PSK';
                b_z_field_bits_per_symbol = 3;
                b_z_field_modulation = 'pi/8-D8PSK';
                code_rate_available = [1; 0.8; 0.75; 0.6; 0.5];
            case '5'
                s_field_modulation = 'pi/2-DBPSK';
                a_field_bits_per_symbol = 1;
                a_field_modulation = 'pi/2-DBPSK';
                b_z_field_bits_per_symbol = 4;
                b_z_field_modulation = '16-QAM';
                code_rate_available = [1; 0.8; 0.75; 0.6; 0.5; 0.4];
            case '6'
                s_field_modulation = 'pi/2-DBPSK';
                a_field_bits_per_symbol = 1;
                a_field_modulation = 'pi/2-DBPSK';
                b_z_field_bits_per_symbol = 6;
                b_z_field_modulation = '64-QAM';
                code_rate_available = [1; 0.8; 0.75; 0.6; 0.5; 1/3];

            otherwise
                error("invalid Configuration selected!");
        end

        if ismember(code_rate, code_rate_available) == 0
            error("code rate not available for this configuration");
        end

        mod_struct.s_field_modulation = s_field_modulation;
        mod_struct.a_field_bits_per_symbol = a_field_bits_per_symbol;
        mod_struct.a_field_modulation = a_field_modulation;
        mod_struct.b_z_field_bits_per_symbol = b_z_field_bits_per_symbol;
        mod_struct.b_z_field_modulation = b_z_field_modulation;
end