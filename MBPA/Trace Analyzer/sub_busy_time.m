function time_record=sub_busy_time(lists_action,options)
% [total_busy_time,device_busy_percent]=sub_busy_time(lists_action,options)
% --> calculate the device busy time;
% 
% inputs
%   lists_action: n samples x 2 array for arrival time and completion time;
%   options: control parameters
% outputs
%   total_busy_time: total busy time
%   device_busy_percent: total busy time / total time
%
% Author: jun.xu99@gmail.com 
%
total_busy_time=0;
con0=size(lists_action,1);
int_start_time=lists_action(1,1); % record the start time of an interval
int_end_time=lists_action(1,2);

% calculate the total busy time
for i=2:con0
    if int_end_time<lists_action(i,1)
        total_busy_time=total_busy_time+int_end_time-int_start_time;
        int_start_time=lists_action(i,1);
        % the next entered request may be completed before the current one;
    end
    if int_end_time<lists_action(i,2)
        int_end_time=lists_action(i,2);
    end
end

% make sure the starting time is from zero; otherwise you need to adjust
% the trace or let the denominator as (lists_action(con0,2)-lists_action(1,2))
% device_busy_percent=total_busy_time/lists_action(con0,2)
device_busy_percent=total_busy_time/(lists_action(con0,2)-lists_action(1,2));

time_record.total_busy_time=total_busy_time;
time_record.device_busy_percent=device_busy_percent;

if options.export_report
    options.section_name='Busy Time'
    generate_ppt(options)
    string0=['Total busy time = ', num2str(total_busy_time), ' seconds ', char(10), 'Total time = ',num2str(lists_action(con0,2)), ' seconds ',char(10), 'Busy time ratio = ', num2str(device_busy_percent)];
    saveppt2(options.report_name,'f',0,'t',string0)
end