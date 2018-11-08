function [queue_record]=sub_queue_depth(lists_action,lists_cmd,options)
% [queue_length_c, queue_length]=sub_queue_depth(lists_action,lists_cmd,options)
% --> average queue depth for completion and arrival
% 
% inputs
%   lists_action: n samples x 2 array for arrival time and completion time; 
%   lists_cmd: n samples x 3 for LBA, size, flags
%   options: control parameters
%       plot_fontsize: the figure's font size
%       time_interval: the time interval for moving average windows
%       plot_figure: >=1: plot the figure; otherwise not
%       save_figure: >=1: save the figures
%       export_report: >=1: export the figure/data into a ppt
%       report_name: report name
% outputs
%   queue_record: structure for queue    
%      queue_length_c: queue_length for completion
%      queue_length: queue_lenght for arrival
%
% Author: jun.xu99@gmail.com

if isfield(options, 'plot_fontsize') 
    plot_fontsize=options.plot_fontsize;
else
    plot_fontsize=10;
end
if isfield(options, 'time_interval') 
    time_interval=options.time_interval;
else
    time_interval=50;
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

if isfield(options, 'export_report')
    export_report=options.export_report;
else
    export_report=1;
end

a=size(lists_action,1);
max_time=lists_action(a,1);

%% method 1: based on the a queue
% if a>1024*2
%     max_queue_length=512*4; % increase to 512, no difference
% else
%     max_queue_length=128;
% end
% a1=a-max_queue_length;
% for i=2:a
%     if i<=max_queue_length
%         idx_tmp=1;
%         idx_back=i-1+max_queue_length;
%     elseif i>=a1
%         idx_tmp=i-max_queue_length;
%         idx_back=a;
%     else
%         idx_tmp=i-max_queue_length;
%         idx_back=i-1+max_queue_length;
%         % the requests enters the queue before the current & leave after
%         % the current --> in the queue
%     end
%     idx_queue=find((lists_action(idx_tmp:idx_back,1)<=lists_action(i,2)) & (lists_action(idx_tmp:idx_back,2)>lists_action(i,2)));
%     queue_length_c(i,:)=[lists_action(i,2) size(idx_queue,1)];
% end

for i=2:a
    idx_queue=find((lists_action(:,1)<=lists_action(i,2)) & (lists_action(:,2)>lists_action(i,2)));
    queue_length_c(i,:)=[lists_action(i,2) size(idx_queue,1)];
end

if plot_figure
    figure;
    plot(queue_length_c(:,1),queue_length_c(:,2),'*','MarkerSize', 0.5)
    xlabel('time');
    ylabel('depth');
    title(['Estimated Device Queue Depth (completed); ave=', num2str(mean(queue_length_c(:,2)))])
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize);
end

%% the following algorithm is related to queue length; sometimes, may not present the actual value if queue length is not large enough
% for i=2:a
%     if i<=max_queue_length
%         idx_tmp=1;
%     else
%         idx_tmp=i-max_queue_length;
%         % the requests enters the queue before the current & leave after
%         % the current --> in the queue
%     end
%     idx_queue=find((lists_action(idx_tmp:i-1,1)<=lists_action(i,1)) & (lists_action(idx_tmp:i-1,2)>lists_action(i,1)));
%     queue_length(i,:)=[lists_action(i,1) size(idx_queue,1)];
% end

xi=1;
for i=2:a
    ra=xi:i-1;
    idx_queue=find((lists_action(ra,2)>lists_action(i,1)));
    x=size(idx_queue,1);
    if x>0
        %xi=idx_queue(1)+xi;
        % xi=ra(idx_queue(1));
    end
    queue_length(i,:)=[lists_action(i,1) x];
end

if isfield(options, 'plot_figure') && options.plot_figure==1    
    figure;
    plot(queue_length(:,1),queue_length(:,2),'*','MarkerSize', 0.5)
    xlabel('time');
    ylabel('depth');
    title(['Estimated Device Queue Depth (arrival); ave=', num2str(mean(queue_length(:,2)))])
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize);
    
end

max_num=ceil(max_time/time_interval);
queue_length_ave=zeros(max_num+5,2);
queue_length_ave2=zeros(max_num,2);

for i=1:max_num
    cur_time=(i-1)*time_interval;
    end_time=i*time_interval;
    idx=find((queue_length(:,1)>cur_time) & (queue_length(:,1)<=end_time));
    dq=0;
    for j=[idx']
        if j==1       
            dq=(queue_length(j,1)*queue_length(j,2));
        else
            dq=dq+(queue_length(j,1)-queue_length(j-1,1))*queue_length(j,2);
        end
    end
    queue_length_ave2(i,:)=[end_time, dq/(time_interval)];
end

if plot_figure
    figure;
    plot(queue_length_ave2(1:max_num,1),queue_length_ave2(1:max_num,2));
    xlabel('time (s)');
    ylabel('depth');
    title(['Estimated Average Device Queue Depth = ', num2str(mean(queue_length_ave2(1:max_num,2))), ' @', num2str(time_interval), 'seconds interval'])
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize);    
end

queue_record.queue_length_c=queue_length_c; 
queue_record.queue_length=queue_length;


if export_report
    options.section_name='Queue Depth';
    generate_ppt(options)
end


%     cur_time=0;
%     cur_idx=1;
%     interval_idx=0;
%     for i=1:con0
%         if lists_action(i,7)>cur_time+time_interval
%             act_time_interval=lists_action(i,7)-lists_action(cur_idx,7);
%             interval_idx=interval_idx+1;
%             queue_length_ave(interval_idx,:)=[lists_action(i,6),sum(queue_length(cur_idx:i,2))/(i-cur_idx+1)];
%             %queue_length_ave(interval_idx,:)=[lists_action(i,6),sum(queue_length(cur_idx:i,2))/time_interval];
%             cur_idx=i;
%             cur_time=lists_action(i,7);
%         else
%
%         end
%     end

%     figure;
%     plot(queue_length_ave(1:interval_idx,1),queue_length_ave(1:interval_idx,2));
%     xlabel('time (s)');
%     ylabel('depth');
%     title(['Estimated Average Device Queue Depth @', num2str(time_interval), 'seconds interval'])
