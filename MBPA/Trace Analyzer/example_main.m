%% main function to call all the sub-routines

% 1 average queue depth; 2: busy time; 3: average IOPS/throughput/request
% size; 4: size distribution 5: LBA vs time; 6: sequential analysis; 7: sequential analysis (queue length)
% 8: stack distance analysis - WOW
% 9: stack distance analysis - ROW
% 10: frequented update ratio - WOW
% 11: timed/ordered update ratio - WOW
% 12 seek distance

clear;
load .\data\test.mat;
options.export_report=1; % 1 generate; 0 no
options.report_name='test.ppt';

options.plot_fontsize=10;
options.time_interval=50;
options.plot_figure=1;
options.offset_time=0; % some trace is not started from zone. in this case. need to find the starting time of first event.

[lists_action,idx]=sortrows(lists_action,1);
lists_cmd=lists_cmd(idx,:);

% report title
if options.export_report
    saveppt2(options.report_name,'f',0,'t',[' Basic Workload Analysis Report'])
end

%% call individual sub-functions
%1 average queue depth for completion and arrival
queue_record=sub_queue_depth(lists_action,lists_cmd,options);

%2 calculate the device busy time;
time_record=sub_busy_time(lists_action,options);

%3 average IOPS/throughput/request
options.time_interval=1;
average_record= sub_iops(lists_action,lists_cmd,options);

options.time_interval=6;
average_record= sub_iops(lists_action,lists_cmd,options);

%4 calcuate the size distribution
req_size_dist=sub_size_dist(lists_action,lists_cmd,options);

%5 calcuate the LBA/size distribution
lba_stat_array=sub_lba_dist(lists_action,lists_cmd,options);

%6 sequential analysis (stream/commands/size/queue length)
options.near_sequence=0; % used for 6sequential analysis;
options.S2_threshold =32; % limit the minimun number which is counted as sequence stream
options.S2_threshold2 =64;
options.max_stream_length=1024;
options.seq_size_threshold=1024; % the size constrain --> change inside the function
sequence_stat=sub_sequence_analysis(lists_action,lists_cmd,options);

options.near_sequence=1; % used for 6sequential analysis;
options.S2_threshold =32; % limit the minimun number which is counted as sequence stream
options.S2_threshold2 =64;
options.max_stream_length=1024;
options.seq_size_threshold=1024; % the size constrain --> change inside the function
sequence_stat=sub_sequence_analysis(lists_action,lists_cmd,options);

%7
% sub_sequence_queue(lists_cmd,options)

%8 stack distance analysis - WOW
options.spec_stack=[10,20,30];  % for very large dataset ; otherwise specify some small numbers
stack_wow_record=sub_stack_wow(lists_cmd,options);

%9 stack distance analysis - ROW
stack_row_record=sub_stack_row(lists_cmd,options);

%10 frequented write update ratio - WOW
freq_wow_record=sub_freq_wow(lists_cmd,options);

%11 timed/ordered update ratio - WOW
time_wow_record=sub_time_wow(lists_cmd,options);

%12 seek distance calcuation
seek_dist_record=sub_seek_dist(lists_cmd,options);

%13 queue length and idle time
idle_queue_record=sub_idle_queue(lists_action,options);

