function seek_dist_record=sub_seek_dist(lists_cmd,options)
%
% seek_dist_record=sub_seek_dist(lists_cmd,options)
% seek distance calcuation
%
% inputs
%   lists_cmd: n samples x 3 for LBA, size, flags
%   options: control parameters
%       plot_fontsize: the figure's font size
%       plot_figure: >=1: plot the figure; otherwise not; default 1
%       save_figure: >=1: save the figures
%       export_report: >=1: export the figure/data into a ppt
%       report_name: report name
%       output_foldername: the output folder name for figures and report; default =''
%       offset_time:  some trace is not started from zone. in this case. need to find the starting time of first event.
%       spec_stack=[10,20,30];  % a vector specify the stack distance, for which we can collect the statistical value and output to the ppt file. for very large dataset ; otherwise specify some small numbers
% outputs
%   seek_dist_record: structure for statistics of seek distance
%
% Author: jun.xu99@gmail.com


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

if isfield(options, 'plot_figure')
    plot_figure=options.plot_figure;
else
    plot_figure=1;
end

if isfield(options, 'queue_len_setting')
    queue_len_setting=options.queue_len_setting;
else
    queue_len_setting=2.^(0:1:7);
end

num_queue_setting=size(queue_len_setting,2);

if isfield(options, 'plot_flags')
    plot_flags=options.plot_flags;
else
    plot_flags={'r','k--','b-.','b:','y--','r:','y:','r-.','k-.','y','g:'};
end

if size(plot_flags,2)<num_queue_setting
    'Error! The figure flags for legend is smaller than required';
    return;
end

seek_write_only = zeros( num_queue_setting, 10); % 1 total R/W IO number, 2 sequnce number, 3 mean, 4 mean abs, 5 median, 6 mode, 7 mode couter, 8 min abs, 9 max abs, 10 std abs
seek_read_only = zeros(num_queue_setting, 10);
seek_all = zeros(num_queue_setting, 10);


for queue_id=1 : num_queue_setting
    queue_id
    % write
    [seq_cmd_count, write_cmd_count, total_cmd,queued_lba_distance]=seek_distance_stack(queue_len_setting(queue_id), lists_cmd, 0,0);
    if write_cmd_count>0
        [x,xi]=mode(queued_lba_distance);
        seek_write_only(queue_id,:)=[total_cmd-write_cmd_count, seq_cmd_count, mean(queued_lba_distance), mean(abs(queued_lba_distance)), median(queued_lba_distance),x,xi,min(abs(queued_lba_distance)),max(abs(queued_lba_distance)), std(abs(queued_lba_distance))];
    end
    % read
    [seq_cmd_count, read_cmd_count, total_cmd,queued_lba_distance]=seek_distance_stack(queue_len_setting(queue_id), lists_cmd, 1,0);
    if read_cmd_count>0
        [x,xi]=mode(queued_lba_distance);
        seek_read_only(queue_id,:)=[total_cmd-read_cmd_count, seq_cmd_count, mean(queued_lba_distance), mean(abs(queued_lba_distance)), median(queued_lba_distance),x,xi,min(abs(queued_lba_distance)),max(abs(queued_lba_distance)), std(abs(queued_lba_distance))];
    end
    % combined
    
    [seq_cmd_count, all_cmd_count, total_cmd,queued_lba_distance]=seek_distance_stack(queue_len_setting(queue_id), lists_cmd, 2,0);
    if all_cmd_count
        [x,xi]=mode(queued_lba_distance);
        seek_all(queue_id,:)=[total_cmd-all_cmd_count, seq_cmd_count, mean(queued_lba_distance), mean(abs(queued_lba_distance)), median(queued_lba_distance),x,xi,min(abs(queued_lba_distance)),max(abs(queued_lba_distance)), std(abs(queued_lba_distance))];
    end
    
end

seek_dist_record.seek_all=seek_all;
seek_dist_record.seek_write_only=seek_write_only;
seek_dist_record.seek_read_only=seek_read_only;
seek_dist_record.queue_len_setting=queue_len_setting;

if plot_figure==1
   
    figure;
    hold on;
    plot(queue_len_setting',seek_write_only(:,7),'b-');
    plot(queue_len_setting',seek_read_only(:,7),'r:');
    plot(queue_len_setting',seek_all(:,7),'k-.');
    xlabel('Queue length ');
    ylabel('Frequency');
    title('Mode Counter')
    legend('write','read','combined')
    saveas(gcf,'sk_mode.eps', 'psc2');
    saveas(gcf,'sk_mode.fig');
    
    figure;
    hold on;
    plot(queue_len_setting',seek_write_only(:,3),'b-');
    plot(queue_len_setting',seek_read_only(:,3),'r:');
    plot(queue_len_setting',seek_all(:,3),'k-.');
    xlabel('Queue length ');
    ylabel('Value');
    title('Mean Value')
    legend('write','read','combined')
    saveas(gcf,'sk_mean.eps', 'psc2');
    saveas(gcf,'sk_mean.fig');
    
    
    figure;
    hold on;
    plot(queue_len_setting',seek_write_only(:,4),'b-');
    plot(queue_len_setting',seek_read_only(:,4),'r:');
    plot(queue_len_setting',seek_all(:,4),'k-.');
    xlabel('Queue length ');
    ylabel('Value');
    title('Mean Absolute Value')
    legend('write','read','combined')
    saveas(gcf,'sk_abs_mean.eps', 'psc2');
    saveas(gcf,'sk_abs_mean.fig');
    
    figure;
    hold on;
    plot(queue_len_setting',seek_write_only(:,9),'b-');
    plot(queue_len_setting',seek_read_only(:,9),'r:');
    plot(queue_len_setting',seek_all(:,9),'k-.');
    xlabel('Queue length ');
    ylabel('Value');
    title('Maximum Seek Distance')
    legend('write','read','combined')
    saveas(gcf,'sk_max.eps', 'psc2');
    saveas(gcf,'sk_max.fig');
end

if options.export_report
    options.section_name='Seek Distance'
    generate_ppt(options)
    
    string0=string_generate([queue_len_setting';seek_write_only(:,6)],20);
    string0=['Mode value (write)=',string0];
    saveppt2(options.report_name,'f',0,'t',string0);
    
    string0=string_generate([queue_len_setting';seek_write_only(:,7)],20);
    string0=['Mode count (write)=',string0];
    saveppt2(options.report_name,'f',0,'t',string0);
    
    string0=string_generate([queue_len_setting';seek_read_only(:,6)],20);
    string0=['Mode value (read)=',string0];
    saveppt2(options.report_name,'f',0,'t',string0);
    
    string0=string_generate([queue_len_setting';seek_read_only(:,7)],20);
    string0=['Mode count (read)=',string0];
    saveppt2(options.report_name,'f',0,'t',string0);
end