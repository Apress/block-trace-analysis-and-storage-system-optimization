function []= sequential_stream_count(trace_folder, total_trace_files, queue_len_setting, output_folder)
% this function is particular for PCMark trace
% parse and display results of PCMark trace
%
% input parameters:
%   trace_folder: Path to PCMark output
%   total_trace_files: Number of files in the folder
%   queue_len_setting: What was Qd for the PCMark trace
%   output_folder: Location to generate figures
% output parameters:
%   Generates sequential stream and command analysis for PCMark in output_folder
%
% Author: jun.xu99@gmail.com

num_queue_setting = size(queue_len_setting, 2);

cmd_count_read_only = zeros(total_trace_files, num_queue_setting);
stream_count_read_only = zeros(total_trace_files, num_queue_setting);
cmd_count_all = zeros(total_trace_files, num_queue_setting);
stream_count_all = zeros(total_trace_files, num_queue_setting);

ratio_cmd_count_read_only = zeros(total_trace_files, num_queue_setting);
ratio_stream_count_read_only = zeros(total_trace_files, num_queue_setting);
ratio_cmd_count_all = zeros(total_trace_files, num_queue_setting);
ratio_stream_count_all = zeros(total_trace_files, num_queue_setting);

average_seq_cmd_size_read_only = zeros(total_trace_files, num_queue_setting);
average_seq_cmd_size_all = zeros(total_trace_files, num_queue_setting);

for file_id=1 : total_trace_files
    disp([int2str(file_id), '.csv']);
    % Here, we load the trace files, and pass the loading result
    % to the processor for processing
    filename = [trace_folder int2str(file_id), '.csv'];
    % before loading the trace file, we need to clear the temp first
    clear PcMark_trace;
    load_csv_file;
    
    for queue_id=1 : num_queue_setting
        queue_len = queue_len_setting(queue_id);
        [n_cmd, n_seq, n_read, n_total,size_dist_read_only] = sequential_stream_track(queue_len, PcMark_trace, 1); % read only
        cmd_count_read_only(file_id, queue_id) = n_cmd;
        stream_count_read_only(file_id, queue_id) = n_seq;
        ratio_cmd_count_read_only(file_id, queue_id) = n_cmd / n_read;
        ratio_stream_count_read_only(file_id, queue_id) = n_seq / n_read;
        idx=size(size_dist_read_only,1);
        average_seq_cmd_size_read_only(file_id, queue_id)=((1:idx)*size_dist_read_only)/sum(size_dist_read_only);
        
        [n_cmd_all, n_seq_all, n_read, n_total,size_dist_all] = sequential_stream_track(queue_len, PcMark_trace, 0); % all commands
        cmd_count_all(file_id, queue_id) = n_cmd_all;
        stream_count_all(file_id, queue_id) = n_seq_all;
        ratio_cmd_count_all(file_id, queue_id) = n_cmd_all / n_total;
        ratio_stream_count_all(file_id, queue_id) = n_seq_all / n_total;
        idx=size(size_dist_all,1);
        average_seq_cmd_size_all(file_id, queue_id)=((1:idx)*size_dist_all)/sum(size_dist_all);
    end
end

app_title={'Windows Defender','Gaming','Importing Pictures','Vista Startup','Video Editing','Windows Media Center','Adding Music','Application Loading'};
plot_flags={'r','r-.','r:','k--','b','b-.','b:','y--'};
h1=figure;
hold on;
h2=figure;
hold on
h3=figure;
hold on
h4=figure;
hold on
h5=figure;
hold on;
h6=figure;
hold on
h7=figure;
hold on
h8=figure;
hold on
h9=figure;
hold on
h10=figure;
hold on
legend_str=[];
for k=1:8
    figure(h1);
    plot(queue_len_setting,stream_count_read_only(k,1:num_queue_setting), plot_flags{k});
    xlabel('queue length');
    ylabel('number of streams');
    title(['Sequential stream detection read only (frequency)']);
    
    figure(h2);
    %plot(queue_len_setting,stream_count_read_only(k,1:num_queue_setting)*2+cmd_count_read_only(k,1:num_queue_setting), plot_flags{k});
    plot(queue_len_setting,cmd_count_read_only(k,1:num_queue_setting), plot_flags{k});
    xlabel('queue length');
    ylabel('number of sequential commands');
    title(['Sequential command detection read only (frequency)']);
    
    figure(h3);
    plot(queue_len_setting,stream_count_all(k,1:num_queue_setting), plot_flags{k});
    xlabel('queue length');
    ylabel('number of sequential stream');
    title(['Sequential stream detection all (frequency)']);
    
    figure(h4);
    %plot(queue_len_setting,stream_count_all(k,1:num_queue_setting)*2+cmd_count_all(k,1:num_queue_setting), plot_flags{k});
    plot(queue_len_setting,cmd_count_all(k,1:num_queue_setting), plot_flags{k});
    xlabel('queue length');
    ylabel('number of sequential commands');
    title(['Sequential command detection all (frequency)']);
    
    figure(h5);
    plot(queue_len_setting,ratio_stream_count_read_only(k,1:num_queue_setting), plot_flags{k});
    xlabel('queue length');
    ylabel('Sequential streams ratio');
    title(['Sequential stream detection read only (ratio)']);
    
    figure(h6);
    %plot(queue_len_setting,ratio_stream_count_read_only(k,1:num_queue_setting)*2+cmd_count_read_only(k,1:num_queue_setting), plot_flags{k});
    plot(queue_len_setting,ratio_cmd_count_read_only(k,1:num_queue_setting), plot_flags{k});
    xlabel('queue length');
    ylabel('sequential commands ratio');
    title(['Sequential command detection read only (ratio)']);
    
    figure(h7);
    plot(queue_len_setting,ratio_stream_count_all(k,1:num_queue_setting), plot_flags{k});
    xlabel('queue length');
    ylabel('Sequential stream ratio');
    title(['Sequential stream detection all (ratio)']);
    
    figure(h8);
    %plot(queue_len_setting,ratio_stream_count_all(k,1:num_queue_setting)*2+cmd_count_all(k,1:num_queue_setting), plot_flags{k});
    plot(queue_len_setting,ratio_cmd_count_all(k,1:num_queue_setting), plot_flags{k});
    xlabel('queue length');
    ylabel('Sequential commands ratio');
    title(['Sequential command detection all (ratio)']);
    
    figure(h9)
    plot(queue_len_setting,average_seq_cmd_size_all(k,1:num_queue_setting), plot_flags{k});
    xlabel('queue length');
    ylabel('average size');
    title(['Sequential command all (ave size)']);
    
    figure(h10)
    plot(queue_len_setting,average_seq_cmd_size_read_only(k,1:num_queue_setting), plot_flags{k});
    xlabel('queue length');
    ylabel('average size');
    title(['Sequential command read only (ave size)']);
    
    if k==8
        legend_str=[legend_str,'''',app_title{k},''''];
    else
        legend_str=[legend_str,'''',app_title{k},'''',','];
    end
end


figure(h1);
set(gca,'xscale','log')
eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEastOutside', '''',')']);
filename = [output_folder,'\sequential stream read only'];
saveas(gcf, filename, 'fig');

figure(h2);
set(gca,'xscale','log')
eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEastOutside', '''',')']);
filename = [output_folder,'\sequential cmd read only'];
saveas(gcf, filename, 'fig');

figure(h3);
set(gca,'xscale','log')
eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEastOutside', '''',')']);
filename = [output_folder,'\sequential stream all'];
saveas(gcf, filename, 'fig');

figure(h4);
set(gca,'xscale','log')
eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEastOutside', '''',')']);
filename = [output_folder,'\sequential cmd all'];
saveas(gcf, filename, 'fig');

figure(h5);
set(gca,'xscale','log')
eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEastOutside', '''',')']);
filename = [output_folder,'\sequential stream read only ratio'];
saveas(gcf, filename, 'fig');

figure(h6);
set(gca,'xscale','log')
eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEastOutside', '''',')']);
filename = [output_folder,'\sequential cmd read only ratio'];
saveas(gcf, filename, 'fig');

figure(h7);
set(gca,'xscale','log')
eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEastOutside', '''',')']);
filename = [output_folder,'\sequential stream all ratio'];
saveas(gcf, filename, 'fig');

figure(h8);
set(gca,'xscale','log')
eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEastOutside', '''',')']);
filename = [output_folder,'\sequential cmd all ratio'];
saveas(gcf, filename, 'fig');

figure(h9);
set(gca,'xscale','log')
eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEastOutside', '''',')']);
filename = [output_folder,'\Sequential cmd size distribution all'];
saveas(gcf, filename, 'fig');

figure(h10);
set(gca,'xscale','log')
eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEastOutside', '''',')']);
filename = [output_folder,'\Sequential cmd size distribution read only'];
saveas(gcf, filename, 'fig');
end
