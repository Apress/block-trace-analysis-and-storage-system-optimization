function idle_queue_record=sub_idle_queue(lists_action,options)
% sub_idle_queue(lists_action,options)
% calcuate the queue length and idle time
%
% inputs
%   lists_action: n samples x 2 array for arrival time and completion time;
%   options: control parameters
%       plot_fontsize: the figure's font size
%       time_interval: the time interval for moving average windows
%       plot_figure: >=1: plot the figure; otherwise not; default 1
%       save_figure: >=1: save the figures
%       export_report: >=1: export the figure/data into a ppt
%       report_name: report name
%       output_foldername: the output folder name for figures and report; default =''
%       offset_time:  some trace is not started from zone. in this case. need to find the starting time of first event.
% outputs
%   idle_queue_record: structure for statistics of idle time
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

if isfield(options, 'idle_threshold')
    idle_threshold=options.idle_threshold;
else
    idle_threshold=0.1; % 100ms
end

%% reorder the completion time to find whether the sequence is matched compared with arrival time
[trace0,idx0]=sortrows(lists_action,2);
a=size(lists_action,1);
queue_length0=(1:a)'-idx0; % queue age: when the request arrives, how long it shall wait to execute. zero means that it is executed immediately.
idle_queue_record.queue_length=queue_length0;

%% calcuate the idle time
idx=find(queue_length0(:)==0);
a1=size(idx,1);
idle_time_array=zeros(a1,3);
idle_time_array2=zeros(a,2);
con0=0;
n_end=1;
for i=2:a
    % two cases when zero: there is no event at the queue (expected), and
    % there are some events but this request is executed first due to RPO.
    if queue_length0(i)<=0
% % can add a policy to calculatge endid in order to reduce the
% computational complexity
%         if i>n_end
%             endid=i-n_end;
%         else
%             endid=1;
%         end
        id0=find(lists_action(n_end:i-1,2)>lists_action(i,1));
        % all previous requests completed before current arrival time
        if isempty(id0)
            comp_time_max=max(lists_action(n_end:i-1,2));
            %it0=lists_action(i,6)-lists_action(i-1,7);
            it0=lists_action(i,1)-comp_time_max;
            if it0>0
                con0=con0+1;
                idle_time_array(con0,1)=lists_action(i,1); % idle starting time
                idle_time_array(con0,2)=it0; %
                idle_time_array(con0,3)=comp_time_max; %
                idle_time_array2(i,2)=it0;
            end
        end
        idle_time_array2(i,1)=lists_action(i-1,2);
    end
end

idle_time_array=idle_time_array(1:con0,:);
total_idle_time=sum(idle_time_array(:,2));

idle_queue_record.idle_time_array=idle_time_array;
idle_queue_record.total_idle_time=total_idle_time;
idle_queue_record.idle_time_array2=idle_time_array2;


max_idle=max(idle_time_array(:,2));
idle_time_interval=[0:5:max_idle*1000+10]/1000;

a2=size(idle_time_interval,2);
idle_time_set=zeros(a2,3);
for i=1:a2-1
    idx=find(idle_time_array(:,2)<=idle_time_interval(i+1) & idle_time_array(:,2)>idle_time_interval(i));
    idle_time_set(i+1,:)=[idle_time_interval(i+1),size(idx,1), sum(idle_time_array(idx,2))];
end

idle_time_cdf=idle_time_set;
for i=2:a2
    idle_time_cdf(i,2:3)=idle_time_cdf(i-1,2:3)+idle_time_cdf(i,2:3);
end
idle_time_cdf(:,2)=idle_time_cdf(:,2)/con0;
idle_time_cdf(:,3)=idle_time_cdf(:,3)/total_idle_time;

idle_queue_record.idle_time_cdf=idle_time_cdf;

if plot_figure==1
    
    figure;
    plot(lists_action(:,2),queue_length0(:),'*','MarkerSize',1);
    xlabel('time');
    ylabel('queue age');
    title('Estimated Device Queue Age');
    saveas(gcf,'est_dev_queue_age.eps', 'psc2');
    saveas(gcf,'est_dev_queue_age.fig');
    saveas(gcf,'est_dev_queue_age.jpg');
    
    figure;
    plot(idle_time_array(:,1),idle_time_array(:,2),'*','MarkerSize',0.5)
    xlabel('time');
    ylabel('idle time length');
    title('Estimated Device Idle Time');
    saveas(gcf,'est_dev_idle_time.eps', 'psc2');
    saveas(gcf,'est_dev_idle_time.fig');
    saveas(gcf,'est_dev_idle_time.jpg');
    
    idle_time_array_cdf=idle_time_array;
    for i=2:con0
        idle_time_array_cdf(i,2)=idle_time_array_cdf(i,2)+idle_time_array_cdf(i-1,2);
    end
    
    fig0=figure;
    plot(idle_time_array_cdf(:,1),idle_time_array_cdf(:,2),'*','MarkerSize',0.5)
    xlabel('time');
    ylabel('total idle time length');
    title('Accumulated Estimated Device Idle Time');
    saveas(gcf,'est_dev_acc_idle_time.eps', 'psc2');
    saveas(gcf,'est_dev_acc_idle_time.fig');
    saveas(gcf,'est_dev_acc_idle_time.jpg');
    
    %idle_time_interval=[0:5:500,510:10:1000,1100:100:5900,6000:1000:20000]/1000;
    %idle_time_interval=[0:5:500]/1000;

    
    fig1=figure;
    plot(idle_time_cdf(:,1),idle_time_cdf(:,2),'-');
    xlabel('idle time length (s)');
    ylabel('CDF');
    title('CDF of Estimated Device Idle Time (Frequency)');
    saveas(gcf,'est_dev_cdf_idle_time_f.eps', 'psc2');
    saveas(gcf,'est_dev_cdf_idle_time_f.fig');
    saveas(gcf,'est_dev_cdf_idle_time_f.jpg');
    
    %     fig3=figure;
    %     plot(idle_time_cdf(:,1),idle_time_cdf(:,2),'-');
    %     axis([0 0.4 0 1])
    %     xlabel('idle time length (s)');
    %     ylabel('CDF');
    %     title('CDF of Estimated Device Idle Time (Frequency)');
        
    fig2=figure;
    plot(idle_time_cdf(:,1),idle_time_cdf(:,3),'-');
    xlabel('idle time length (s)');
    ylabel('CDF');
    title('CDF of Estimated Device Idle Time');
    saveas(gcf,'est_dev_cdf_idle_time.eps', 'psc2');
    saveas(gcf,'est_dev_cdf_idle_time.fig');
    saveas(gcf,'est_dev_cdf_idle_time.jpg');
end

set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)

if options.export_report
    options.section_name='Idle Time'
    generate_ppt(options)
    % saveppt2(options.report_name,'figure',[fig0 fig1 fig2 fig3],'columns',2,'scale',true,'stretch',true, 'title','Idle time')
end