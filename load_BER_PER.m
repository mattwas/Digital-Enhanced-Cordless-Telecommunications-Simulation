clear all;
close all;
set(groot,'defaultAxesTickLabelInterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');
set(groot,'defaultTextInterpreter','latex');
%%
format = ["1a" "1b" "4a" "4b"];
format_mod = ["GMSK" "$\pi$/2-DBPSK" "$\pi$/4-DQPSK" "$\pi$/8-D8PSK"];
path = "/home/dect1/Documents/MATLAB/DECT Legacy/results/100ns/";
snr_db_old = 0:1:40;
antenna = ["-n_1" "-n_2"];
SNR_steps = 41;
PER_A_field_n1 = zeros(numel(format),SNR_steps);
PER_A_field_n2 = zeros(numel(format),SNR_steps);
cnt = 1;

file = strjoin([path,"1a"],'');
load(file);
PER_A_field_n1(cnt,:) = PER_a_field_array(1,:);
PER_A_field_n2(cnt,:) = PER_a_field_array(2,:);
legend_string_n1 = [convertCharsToStrings(strcat(mac_meta.Configuration, ' (GMSK)'))];
legend_string_n2 = [convertCharsToStrings(strcat(mac_meta.Configuration, ' (GMSK)'))];
cnt = cnt +1;
for i=2:numel(format)
    %for j = 1:numel(antenna)
        file = strjoin([path,format(i), "-n_1"],'');
        load(file);
        PER_A_field_n1(cnt,:) = PER_a_field_array;
        file = strjoin([path,format(i), "-n_2"],'');
        legend_string_n1 = [legend_string_n1, convertCharsToStrings(strcat(mac_meta.Configuration, ' (', format_mod(i),')'))];
        load(file);
        PER_A_field_n2(cnt,:) = PER_a_field_array;
        cnt = cnt+1;
        legend_string_n2 = [legend_string_n2, convertCharsToStrings(strcat(mac_meta.Configuration, ' (', format_mod(i),')'))];
    %end
end
PER_A_field_movmean_n1 = zeros(numel(format),SNR_steps);
PER_A_field_movmean_n2 = zeros(numel(format),SNR_steps);
for k = 1:size(PER_A_field_n1,1)
    PER_A_field_movmean_n1(k,:) = movmean(PER_A_field_n1(k,:),[2 2]);
    PER_A_field_movmean_n2(k,:) = movmean(PER_A_field_n2(k,:),[2 2]);
end

format = ["1" "3"];
format_mod = ["QPSK" "16QAM"];
SNR_steps = 51;
path = "/home/dect1/Documents/MATLAB/dect-2020-results/";
PER_pdc_n1 = zeros(numel(format),SNR_steps);
PER_pdc_n2 = zeros(numel(format),SNR_steps);
for i=1:numel(format)
    file = strjoin([path,"mcs",format(i), "-n_1"],'');
    load(file);
    PER_pdc_n1(i,:) = PER_pdc_array;
    legend_string_n1 = [legend_string_n1, convertCharsToStrings(strcat('MCS ', num2str(format(i)), ' (', format_mod(i),')'))];
        
    file = strjoin([path,"mcs",format(i), "-n_2"],'');
    load(file);
    PER_pdc_n2(i,:) = PER_pdc_array;
    legend_string_n2 = [legend_string_n2, convertCharsToStrings(strcat('MCS ', num2str(format(i)), ' (', format_mod(i),')'))];
    


end

PER_pdc_movmean_n1 = zeros(numel(format),SNR_steps);
PER_pdc_movmean_n2 = zeros(numel(format),SNR_steps);
for k = 1:size(PER_pdc_movmean_n1,1)
    PER_pdc_movmean_n1(k,:) = movmean(PER_pdc_n1(k,:),[1 1]);
    PER_pdc_movmean_n2(k,:) = movmean(PER_pdc_n2(k,:),[1 1]);
end



figure;
for k = 1:size(PER_A_field_n1,1)
    semilogy(snr_db_old,PER_A_field_movmean_n1(k,:),'--');
    hold on
end
for k = 1:size(PER_pdc_movmean_n1,1)
    semilogy(snr_db_vec_global,PER_pdc_movmean_n1(k,:));
    hold on
end
xlim([0 40]);
ylim([10e-5 1]);
grid on;
legend(legend_string_n1,'Location','southwest');
title("PER A-Field 100 ns delay spread (ITU-i), $N_{Rx} = 1$");
ylabel("PER")
xlabel("SNR in dB")

figure;
for k = 1:size(PER_A_field_n1,1)
    semilogy(snr_db_old,PER_A_field_movmean_n2(k,:),'--');
    hold on
end
for k = 1:size(PER_pdc_movmean_n2,1)
    semilogy(snr_db_vec_global,PER_pdc_movmean_n2(k,:));
    hold on
end
xlim([0 40]);
ylim([10e-5 1]);
grid on;
legend(legend_string_n2,'Location','southwest');
title("PER A-Field 100 ns delay spread (ITU-i), $N_{Rx} = 2$");
ylabel("PER")
xlabel("SNR in dB")
