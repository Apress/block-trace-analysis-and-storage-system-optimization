function sequence_stat=sub_sequence_analysis(lists_action,lists_cmd,options)
% sequence_stat=sub_sequence_analysis(lists_action,lists_cmd,options)
% sequential analysis (stream/commands/size/queue length)
%
% inputs
%   lists_action: n samples x 2 array for arrival time and completion time;
%   lists_cmd: n samples x 3 for LBA, size, flags
%   options: control parameters
%       plot_fontsize: the figure's font size
%       time_interval: the time interval for moving average windows
%       plot_figure: >=1: plot the figure; otherwise not; default 1
%       save_figure: >=1: save the figures
%       export_report: >=1: export the figure/data into a ppt
%       report_name: report name
%       output_foldername: the output folder name for figures and report; default =''
%       offset_time:  some trace is not started from zone. in this case. need to find the starting time of first event.
%       near_sequence: default =0, i.e., strictly sequential without any gap
%       S2_threshold =32; % limit the minimun number which is counted as sequence stream
%       S2_threshold2 =64;
%       max_stream_length=1024;
%       seq_size_threshold=1024; % the size constrain --> change inside the function
% outputs
%   sequence_stat: structure for statistics of request sequence
%
% Author: jun.xu99@gmail.com and junpeng.niu@wdc.com


if isfield(options, 'plot_fontsize')
    plot_fontsize=options.plot_fontsize;
else
    plot_fontsize=10;
end

if isfield(options, 'save_figure')
    save_figure=options.save_figure;
else
    save_figure=1;
end

if isfield(options, 'near_sequence')
    near_sequence=options.near_sequence;
else
    near_sequence=0;
end

if isfield(options, 'S2_threshold')
    S2_threshold=options.S2_threshold;
else
    S2_threshold=32;
end

if isfield(options, 'S2_threshold2')
    S2_threshold2=options.S2_threshold2;
else
    S2_threshold2=64;
end
if isfield(options, 'plot_figure')
    plot_figure=options.plot_figure;
else
    plot_figure=1;
end

if isfield(options, 'seq_size_threshold')
    seq_size_threshold=options.seq_size_threshold;
else
    seq_size_threshold=1024;
end

if isfield(options, 'max_stream_length')
    max_stream_length=options.max_stream_length;
else
    max_stream_length=1024;
end

if near_sequence==0
    options.section_name='Strict Sequence';
else
    options.section_name='Near Sequence';
end

if isfield(options, 'export_report')
    export_report=options.export_report;
else
    export_report=1;
end


queue_len_setting=2.^(0:1:8);
file_id=1;
num_queue_setting=size(queue_len_setting,2);
total_trace_files=1;
cmd_count_read_only = zeros(total_trace_files, num_queue_setting);
stream_count_read_only = zeros(total_trace_files, num_queue_setting);

cmd_count_write_only = zeros(total_trace_files, num_queue_setting);
stream_count_write_only = zeros(total_trace_files, num_queue_setting);
cmd_count_all = zeros(total_trace_files, num_queue_setting);
stream_count_all = zeros(total_trace_files, num_queue_setting);

ratio_cmd_count_read_only = zeros(total_trace_files, num_queue_setting);
ratio_stream_count_read_only = zeros(total_trace_files, num_queue_setting);
ratio_cmd_count_write_only = zeros(total_trace_files, num_queue_setting);
ratio_stream_count_write_only = zeros(total_trace_files, num_queue_setting);
ratio_cmd_count_all = zeros(total_trace_files, num_queue_setting);
ratio_stream_count_all = zeros(total_trace_files, num_queue_setting);

average_seq_cmd_size_read_only = zeros(total_trace_files, num_queue_setting);
average_seq_cmd_size_write_only = zeros(total_trace_files, num_queue_setting);
average_seq_cmd_size_all = zeros(total_trace_files, num_queue_setting);
average_seq_cmd_size_read_only_s = zeros(total_trace_files, num_queue_setting);
average_seq_cmd_size_write_only_s = zeros(total_trace_files, num_queue_setting);
average_seq_cmd_size_all_s = zeros(total_trace_files, num_queue_setting);

if plot_figure==1
    hh1=figure;
    hold on;
    hh2=figure;
    hold on;
    hh3=figure;
    hold on;
    
    hl1=figure;
    hold on;
    hl2=figure;
    hold on;
    hl3=figure;
    hold on;
    legend_str=[];
    plot_flags={'r','b--','b-.','r:','y--','r:','k:','y:','k-.'};
end

for queue_id=1 : num_queue_setting
    % seq_stream_length_count_read_only:  value at array index i corresponding to
    % the number/frequecy of commands with sequence command length =i;
    % seq_stream_length_count_read_only_limited: besides the above
    % condition, it also satisfies the mininum total request size of
    % this stream is larger than 1024
    % n_cmd: sequential commands number
    % n_seq: sequential stream number
    % n_read: total read number
    % n_total: total command number
    % size_dist_read_only: request size disribution
    queue_len = queue_len_setting(queue_id);
    
    %% read
    if near_sequence==1
        [n_cmd, n_seq, n_read, n_total,size_dist_read_only,seq_stream_length_count_read_only,seq_stream_length_count_read_only_limited,record_read] = near_sequential_stream_track(queue_len, lists_cmd, 1, seq_size_threshold); % read only
    else
        [n_cmd, n_seq, n_read, n_total,size_dist_read_only,seq_stream_length_count_read_only,seq_stream_length_count_read_only_limited,record_read] = sequential_stream_track(queue_len, lists_cmd, 1,seq_size_threshold); % read only
    end
    cmd_count_read_only(file_id, queue_id) = n_cmd;
    stream_count_read_only(file_id, queue_id) = n_seq;
    cmd_count_read_only_limited(file_id, queue_id) = record_read.cmd_number;
    stream_count_read_only_limited(file_id, queue_id) = record_read.stream_number;
    ratio_cmd_count_read_only_limited(file_id, queue_id) = record_read.cmd_number / n_read;
    ratio_cmd_count_read_only(file_id, queue_id) = n_cmd / n_read;
    ratio_stream_count_read_only(file_id, queue_id) = n_seq / n_read;
    idx=size(size_dist_read_only,1);
    average_seq_cmd_size_read_only(file_id, queue_id)=((1:idx)*size_dist_read_only)/sum(size_dist_read_only); % average read requests command's size in the sequence stream
    average_seq_cmd_size_read_only_limited(file_id, queue_id)=sum(seq_stream_length_count_read_only_limited(:,2))/record_read.cmd_number; % % average read requests command's size in the sequence stream with size constraint
    average_seq_stream_size_read_only_limited(file_id, queue_id)=sum(seq_stream_length_count_read_only_limited(:,2))/stream_count_read_only_limited(file_id, queue_id); % average stream size
    average_seq_cmd_size_read_only_s(file_id, queue_id)=((S2_threshold:idx)*size_dist_read_only(S2_threshold:idx))/sum(size_dist_read_only(S2_threshold:idx));
    average_seq_cmd_size_read_only_s2(file_id, queue_id)=((S2_threshold2:idx)*size_dist_read_only(S2_threshold2:idx))/sum(size_dist_read_only(S2_threshold2:idx));
    %         idxs=size(seq_stream_length_count_read_only,1);
    %         if idxs>max_stream_length
    %             idx_ex=find(seq_stream_length_count_read_only(max_stream_length+1:idxs)>0);
    %             idx_ex_ac=max_stream_length+idx_ex;
    %             seq_stream_length_count_read_only_adjust=seq_stream_length_count_read_only(1:max_stream_length);
    %
    %         end
    %         frequency_cmd_count_read_only(file_id, queue_id)=sum(seq_stream_length_count_read_only(S2_threshold:1024));
    
    %% all
    if near_sequence==1
        [n_cmd_all, n_seq_all, n_read, n_total,size_dist_all,seq_stream_length_count_all,seq_stream_length_count_all_limited,record_all] = near_sequential_stream_track(queue_len, lists_cmd, 2,seq_size_threshold); % all commands
        
    else
        [n_cmd_all, n_seq_all, n_read, n_total,size_dist_all,seq_stream_length_count_all,seq_stream_length_count_all_limited,record_all] = sequential_stream_track(queue_len, lists_cmd, 2,seq_size_threshold); % all commands
    end
    cmd_count_all(file_id, queue_id) = n_cmd_all;
    stream_count_all(file_id, queue_id) = n_seq_all;
    ratio_cmd_count_all(file_id, queue_id) = n_cmd_all / n_total;
    
    cmd_count_all_limited(file_id, queue_id) = record_all.cmd_number;
    stream_count_all_limited(file_id, queue_id) = record_all.stream_number;
    ratio_cmd_count_all_limited(file_id, queue_id) = record_all.cmd_number / n_total;
    
    ratio_stream_count_all(file_id, queue_id) = n_seq_all / n_total;
    idx=size(size_dist_all,1);
    average_seq_cmd_size_all(file_id, queue_id)=((1:idx)*size_dist_all)/sum(size_dist_all);
    average_seq_cmd_size_all_limited(file_id, queue_id)=sum(seq_stream_length_count_all_limited(:,2))/record_all.cmd_number;
    average_seq_stream_size_all_limited(file_id, queue_id)=sum(seq_stream_length_count_all_limited(:,2))/stream_count_all_limited(file_id, queue_id);
    
    average_seq_cmd_size_all_s(file_id, queue_id)=((S2_threshold:idx)*size_dist_all(S2_threshold:idx))/sum(size_dist_all(S2_threshold:idx));
    average_seq_cmd_size_all_s2(file_id, queue_id)=((S2_threshold2:idx)*size_dist_all(S2_threshold2:idx))/sum(size_dist_all(S2_threshold2:idx));
    
    
    %% write
    if near_sequence==1
        [n_cmd_write_only, n_seq_write_only, n_read, n_total,size_dist_write_only,seq_stream_length_count_write_only,seq_stream_length_count_write_only_limited,record_write] = near_sequential_stream_track(queue_len, lists_cmd, 0,seq_size_threshold); % write commands
        
    else
        [n_cmd_write_only, n_seq_write_only, n_read, n_total,size_dist_write_only,seq_stream_length_count_write_only,seq_stream_length_count_write_only_limited,record_write] = sequential_stream_track(queue_len, lists_cmd, 0,seq_size_threshold); % write commands
    end
    cmd_count_write_only(file_id, queue_id) = n_cmd_write_only;
    stream_count_write_only(file_id, queue_id) = n_seq_write_only;
    n_write=n_total-n_read;
    ratio_cmd_count_write_only(file_id, queue_id) = n_cmd_write_only / n_write;
    
    cmd_count_write_only_limited(file_id, queue_id) = record_write.cmd_number;
    stream_count_write_only_limited(file_id, queue_id) = record_write.stream_number;
    ratio_cmd_count_write_only_limited(file_id, queue_id) = record_write.cmd_number / n_write;
    
    ratio_stream_count_write_only(file_id, queue_id) = n_seq_write_only / n_write;
    idx=size(size_dist_write_only,1);
    average_seq_cmd_size_write_only(file_id, queue_id)=((1:idx)*size_dist_write_only)/sum(size_dist_write_only);
    average_seq_cmd_size_write_only_limited(file_id, queue_id)=sum(seq_stream_length_count_write_only_limited(:,2))/record_write.cmd_number;
    average_seq_stream_size_write_only_limited(file_id, queue_id)=sum(seq_stream_length_count_write_only_limited(:,2))/stream_count_write_only_limited(file_id, queue_id);
    average_seq_cmd_size_write_only_s(file_id, queue_id)=((S2_threshold:idx)*size_dist_write_only(S2_threshold:idx))/sum(size_dist_write_only(S2_threshold:idx));
    average_seq_cmd_size_write_only_s2(file_id, queue_id)=((S2_threshold2:idx)*size_dist_write_only(S2_threshold2:idx))/sum(size_dist_write_only(S2_threshold2:idx));
    
    
    if plot_figure==1
        figure(hh1);
        idx=find(seq_stream_length_count_read_only(:,1)>0,1,'last');
        %plot(1:idx,seq_stream_length_count_read_only(1:idx,1),plot_flags{queue_id});
        plot(2:idx,seq_stream_length_count_read_only(2:idx,1),plot_flags{queue_id});
        
        figure(hh2);
        idx=find(seq_stream_length_count_write_only(:,1)>0,1,'last');
        %plot(1:idx,seq_stream_length_count_write_only(1:idx,1),plot_flags{queue_id});
        plot(2:idx,seq_stream_length_count_write_only(2:idx,1),plot_flags{queue_id});
        
        figure(hh3);
        idx=find(seq_stream_length_count_all(:,1)>0,1,'last');
        %plot(1:idx,seq_stream_length_count_all(1:idx,1),plot_flags{queue_id});
        plot(2:idx,seq_stream_length_count_all(2:idx,1),plot_flags{queue_id});
        
        figure(hl1);
        idx=find(seq_stream_length_count_read_only_limited(:,1)>0,1,'last');
        %plot(1:idx,seq_stream_length_count_read_only_limited(1:idx,1),plot_flags{queue_id});
        plot(2:idx,seq_stream_length_count_read_only_limited(2:idx,1),plot_flags{queue_id});
        
        figure(hl2);
        idx=find(seq_stream_length_count_write_only_limited(:,1)>0,1,'last');
        %plot(1:idx,seq_stream_length_count_write_only_limited(1:idx,1),plot_flags{queue_id});
        plot(2:idx,seq_stream_length_count_write_only_limited(2:idx,1),plot_flags{queue_id});
        
        figure(hl3);
        idx=find(seq_stream_length_count_all_limited(:,1)>0,1,'last');
        %plot(1:idx,seq_stream_length_count_all_limited(1:idx,1),plot_flags{queue_id});
        plot(2:idx,seq_stream_length_count_all_limited(2:idx,1),plot_flags{queue_id});
        if queue_id==num_queue_setting
            legend_str=[legend_str,'''',int2str(queue_len_setting(queue_id)),''''];
        else
            legend_str=[legend_str,'''',int2str(queue_len_setting(queue_id)),'''',','];
        end
    end
    
end

sequence_stat.average_seq_cmd_size_write_only=average_seq_cmd_size_write_only;
sequence_stat.average_seq_cmd_size_write_only_limited=average_seq_cmd_size_write_only_limited;
sequence_stat.average_seq_stream_size_write_only_limited=average_seq_stream_size_write_only_limited;
sequence_stat.average_seq_cmd_size_write_only_s=average_seq_cmd_size_write_only_s;
sequence_stat.average_seq_cmd_size_write_only_s2=average_seq_cmd_size_write_only_s2;
sequence_stat.average_seq_cmd_size_read_only=average_seq_cmd_size_read_only;
sequence_stat.average_seq_cmd_size_read_only_limited=average_seq_cmd_size_read_only_limited;
sequence_stat.average_seq_stream_size_read_only_limited=average_seq_stream_size_read_only_limited;
sequence_stat.average_seq_cmd_size_read_only_s=average_seq_cmd_size_read_only_s;
sequence_stat.average_seq_cmd_size_read_only_s2=average_seq_cmd_size_read_only_s2;


if plot_figure
    
    if near_sequence==1
        t_str='Near Sequential';
    else
        t_str='Sequential';
    end
    
    
    figure(hh1);
    xlabel('Number of requests in queue')
    ylabel('Frequency');
    title([t_str, ' Stream Read Only w/o constraint'])
    eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEast', '''',')']);
    set(gca,'xscale','log')
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
    saveas(gcf,['seq_stream_read.eps'], 'psc2')
    saveas(gcf,'seq_stream_read.fig')
    
    figure(hh2);
    xlabel('Number of requests in queue')
    ylabel('Frequency');
    title([t_str, ' Stream Write Only w/o constraint'])
    eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEast', '''',')']);
    set(gca,'xscale','log')
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
    saveas(gcf,'seq_stream_write.eps', 'psc2')
    saveas(gcf,'seq_stream_write.fig')
    
    figure(hh3);
    xlabel('Number of requests in queue')
    ylabel('Frequency');
    title([t_str, ' Stream Combined w/o constraint'])
    eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEast', '''',')']);
    set(gca,'xscale','log')
    %     set(findall(gcf,'-property','FontSize'),'FontSize',20)
    %     saveas(gcf,'seq_stream_com.eps', 'psc2')
    %     saveas(gcf,'seq_stream_com.fig')
    
    figure(hl1);
    xlabel('Number of requests in queue')
    ylabel('Frequency');
    title([t_str,' Stream Read Only with Size Contraint'])
    eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEast', '''',')']);
    set(gca,'xscale','log')
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
    saveas(gcf,['seq_stream_read_size','_',int2str(seq_size_threshold),'.eps'], 'psc2')
    saveas(gcf,['seq_stream_read_size','_',int2str(seq_size_threshold),'.fig'])
    
    figure(hl2);
    xlabel('Number of requests in queue')
    ylabel('Frequency');
    title([t_str,' Stream Write Only with Size Contraint'])
    eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEast', '''',')']);
    set(gca,'xscale','log')
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
    saveas(gcf,['seq_stream_write_size','_',int2str(seq_size_threshold),'.eps'], 'psc2')
    saveas(gcf,['seq_stream_write_size','_',int2str(seq_size_threshold),'.fig'])
    
    figure(hl3);
    xlabel('Number of requests in queue')
    ylabel('Frequency');
    title([t_str,' Stream Combined with Size Contraint'])
    eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEast', '''',')']);
    set(gca,'xscale','log')
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
    saveas(gcf,['seq_stream_com_size','_',int2str(seq_size_threshold),'.eps'], 'psc2')
    saveas(gcf,['seq_stream_com_size','_',int2str(seq_size_threshold),'.fig'])
    
    figure;
    hold on;
    k=1;
    plot(queue_len_setting,stream_count_write_only(k,1:num_queue_setting), plot_flags{1});
    plot(queue_len_setting,stream_count_read_only(k,1:num_queue_setting), plot_flags{2});
    plot(queue_len_setting,stream_count_all(k,1:num_queue_setting), plot_flags{3});
    xlabel('queue length');
    ylabel('number of streams');
    legend('write','read','combined');
    title([t_str,' stream detection (frequency)']);
    
    
    figure;
    hold on;
    k=1;
    plot(queue_len_setting,stream_count_write_only_limited(k,1:num_queue_setting), plot_flags{1});
    plot(queue_len_setting,stream_count_read_only_limited(k,1:num_queue_setting), plot_flags{2});
    plot(queue_len_setting,stream_count_all_limited(k,1:num_queue_setting), plot_flags{3});
    xlabel('queue length');
    ylabel('number of streams');
    legend('write','read','combined');
    title([t_str,' stream detection with size constraint (frequency)']);
    
    figure;
    hold on;
    %plot(queue_len_setting,stream_count_read_only(k,1:num_queue_setting)*2+cmd_count_read_only(k,1:num_queue_setting), plot_flags{k});
    plot(queue_len_setting,cmd_count_write_only(k,1:num_queue_setting), plot_flags{1});
    plot(queue_len_setting,cmd_count_read_only(k,1:num_queue_setting), plot_flags{2});
    plot(queue_len_setting,cmd_count_all(k,1:num_queue_setting), plot_flags{3});
    xlabel('queue length');
    ylabel('number of sequential commands');
    legend('write','read','combined');
    title([t_str,' command detection (frequency)']);
    
    figure;
    hold on;
    %plot(queue_len_setting,stream_count_read_only(k,1:num_queue_setting)*2+cmd_count_read_only(k,1:num_queue_setting), plot_flags{k});
    plot(queue_len_setting,cmd_count_write_only_limited(k,1:num_queue_setting), plot_flags{1});
    plot(queue_len_setting,cmd_count_read_only_limited(k,1:num_queue_setting), plot_flags{2});
    plot(queue_len_setting,cmd_count_all_limited(k,1:num_queue_setting), plot_flags{3});
    xlabel('queue length');
    ylabel('number of sequential commands');
    legend('write','read','combined');
    title([t_str,' command detection with size constraint(frequency)']);
    
    figure;
    hold on;
    plot(queue_len_setting,ratio_stream_count_write_only(k,1:num_queue_setting), plot_flags{1});
    plot(queue_len_setting,ratio_stream_count_read_only(k,1:num_queue_setting), plot_flags{2});
    plot(queue_len_setting,ratio_stream_count_all(k,1:num_queue_setting), plot_flags{3});
    xlabel('queue length');
    ylabel('Sequential streams ratio');
    legend('write','read','combined');
    title([t_str, ' stream detection with size constraint (ratio)']);
    
    figure;
    hold on;
    %plot(queue_len_setting,ratio_stream_count_read_only(k,1:num_queue_setting)*2+cmd_count_read_only(k,1:num_queue_setting), plot_flags{k});
    plot(queue_len_setting,ratio_cmd_count_write_only(k,1:num_queue_setting), plot_flags{1});
    plot(queue_len_setting,ratio_cmd_count_read_only(k,1:num_queue_setting), plot_flags{2});
    plot(queue_len_setting,ratio_cmd_count_all(k,1:num_queue_setting), plot_flags{3});
    xlabel('queue length');
    ylabel('sequential commands ratio');
    legend('write','read','combined');
    if near_sequence==1
        title(['Near sequential command detection (ratio)']);
        set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        saveas(gcf,'near_seq_cmd_ratio.eps', 'psc2')
        saveas(gcf,'near_seq_cmd_ratio.fig')
    else
        title(['Sequential command detection (ratio)']);
        set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        saveas(gcf,'seq_cmd_ratio.eps.eps', 'psc2')
        saveas(gcf,'seq_cmd_ratio.fig')
    end
    
    figure;
    hold on;
    %plot(queue_len_setting,ratio_stream_count_read_only(k,1:num_queue_setting)*2+cmd_count_read_only(k,1:num_queue_setting), plot_flags{k});
    plot(queue_len_setting,ratio_cmd_count_write_only_limited(k,1:num_queue_setting), plot_flags{1});
    plot(queue_len_setting,ratio_cmd_count_read_only_limited(k,1:num_queue_setting), plot_flags{2});
    plot(queue_len_setting,ratio_cmd_count_all_limited(k,1:num_queue_setting), plot_flags{3});
    xlabel('queue length');
    ylabel('sequential commands ratio');
    legend('write','read','combined');
    if near_sequence==1
        title(['near sequential command detection with size constraint(ratio)']);
        set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        saveas(gcf,['near_seq_cmd_ratio_size','_',int2str(seq_size_threshold),'.eps'], 'psc2')
        saveas(gcf,['near_seq_cmd_ratio_size','_',int2str(seq_size_threshold),'.fig'])
    else
        title(['Sequential command detection with size constraint(ratio)']);
        set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        saveas(gcf,['seq_cmd_ratio_size','_',int2str(seq_size_threshold),'.eps'], 'psc2')
        saveas(gcf,['seq_cmd_ratio_size','_',int2str(seq_size_threshold),'.fig'])
    end
    
    figure;
    hold on;
    plot(queue_len_setting,average_seq_cmd_size_write_only(k,1:num_queue_setting), plot_flags{1});
    plot(queue_len_setting,average_seq_cmd_size_read_only(k,1:num_queue_setting), plot_flags{2});
    plot(queue_len_setting,average_seq_cmd_size_all(k,1:num_queue_setting), plot_flags{3});
    xlabel('queue length');
    ylabel('average size (blocks)');
    legend('write','read','combined');
    title(['Sequential command (average size)']);
    
    figure;
    hold on;
    plot(queue_len_setting,average_seq_cmd_size_write_only_limited(k,1:num_queue_setting), plot_flags{1});
    plot(queue_len_setting,average_seq_cmd_size_read_only_limited(k,1:num_queue_setting), plot_flags{2});
    plot(queue_len_setting,average_seq_cmd_size_all_limited(k,1:num_queue_setting), plot_flags{3});
    xlabel('queue length');
    ylabel('average size (blocks)');
    legend('write','read','combined');
    title(['Sequential command with size constraint (average size)']);
    
    figure;
    hold on;
    plot(queue_len_setting,average_seq_stream_size_write_only_limited(k,1:num_queue_setting), plot_flags{1});
    plot(queue_len_setting,average_seq_stream_size_read_only_limited(k,1:num_queue_setting), plot_flags{2});
    plot(queue_len_setting,average_seq_stream_size_all_limited(k,1:num_queue_setting), plot_flags{3});
    xlabel('queue length');
    ylabel('average size (blocks)');
    legend('write','read','combined');
    title(['Sequential Stream with size constraint (average size)']);
    
    
    %     figure;
    %     hold on;
    %     plot(queue_len_setting,average_seq_cmd_size_write_only_s(k,1:num_queue_setting), plot_flags{1});
    %     plot(queue_len_setting,average_seq_cmd_size_read_only_s(k,1:num_queue_setting), plot_flags{2});
    %     plot(queue_len_setting,average_seq_cmd_size_all_s(k,1:num_queue_setting), plot_flags{3});
    %     xlabel('queue length');
    %     ylabel('average size (blocks)');
    %     legend('write','read','combined');
    %     title(['Sequential command (average size)']);
    %
    %     figure;
    %     hold on;
    %     plot(queue_len_setting,average_seq_cmd_size_write_only_s2(k,1:num_queue_setting), plot_flags{1});
    %     plot(queue_len_setting,average_seq_cmd_size_read_only_s2(k,1:num_queue_setting), plot_flags{2});
    %     plot(queue_len_setting,average_seq_cmd_size_all_s2(k,1:num_queue_setting), plot_flags{3});
    %     xlabel('queue length');
    %     ylabel('average size (blocks)');
    %     legend('write','read','combined');
    %     title(['Sequential command (average size)']);
    
end


if export_report    
    options.section_name=[options.section_name, char(10), 'seq_size_threshold=', int2str(max_stream_length)];
    generate_ppt(options)
    
    string0=string_generate([queue_len_setting; ratio_cmd_count_write_only(1,1:num_queue_setting)]',size(queue_len_setting,2));
    string0=['without size constraint (cmd): write=',string0];
    saveppt2(options.report_name,'f',0,'t',string0);
    
    string0=string_generate([queue_len_setting; ratio_cmd_count_read_only(1,1:num_queue_setting)]',size(queue_len_setting,2));
    string0=['without size constraint (cmd): read=',string0];
    saveppt2(options.report_name,'f',0,'t',string0);
    
    string0=string_generate([queue_len_setting; ratio_cmd_count_write_only_limited(1,1:num_queue_setting)]',size(queue_len_setting,2));
    string0=['without size constraint (cmd): write=',string0];
    saveppt2(options.report_name,'f',0,'t',string0);
    
    string0=string_generate([queue_len_setting; ratio_cmd_count_read_only_limited(1,1:num_queue_setting)]',size(queue_len_setting,2));
    string0=['without size constraint (cmd): read=',string0];
    saveppt2(options.report_name,'f',0,'t',string0);
end;
