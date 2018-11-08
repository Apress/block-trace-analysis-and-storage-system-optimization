function average_record= sub_iops(lists_action,lists_cmd,options)
% [IOPS_ave, throuput_ave,req_size_ave]= sub_iops(lists_action,lists_cmd,options)
% --> average IOPS/throughput/request (read/write/total)
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
%       output_foldername: the output folder name for figures and report
%       offset_time:  some trace is not started from zone. in this case. need to find the starting time of first event. 
% outputs
%   average_record: structure 
%      IOPS_ave: average value of IOPS at time_interval
%      throuput_ave: average value of throughput at time_interval
%      req_size_ave: average request size  at time_interval
%
% Author: jun.xu99@gmail.com 

con0=size(lists_action,1);

if isfield(options, 'time_interval') 
    time_interval=options.time_interval;
else
    time_interval=5;
end

if isfield(options, 'offset_time') 
    offset_time=options.offset_time;
else
    offset_time=0;
end

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

max_time=lists_action(con0,1);
max_num=ceil((max_time-offset_time)/time_interval);
if max_num<10
    disp('Warning! the time_interval might be too large; too few points are calcuated.')
end
IOPS_ave=zeros(max_num,4); % time, total,  write, read,
throuput_ave=zeros(max_num,4);
req_size_ave=zeros(max_num,4);
start_pos=1;

for i=1:max_num
    start_time=(i-1)*time_interval+offset_time;
    end_time=i*time_interval+offset_time;
    idx_interval=find((lists_action(start_pos:con0,2)>start_time) &(lists_action(start_pos:con0,2)<=end_time));
    
    if isempty(idx_interval)
        IOPS_ave(i,:)=[end_time, 0,0,0];
        req_size_ave(i,:)=[end_time, 0,0,0];
        throuput_ave(i,:)=[end_time,0,0,0];
        continue;
    end
    %start_pos=idx_interval(size(idx_interval,1));
    idx_interval_ac=idx_interval+start_pos-1;
    idx_read=find(lists_cmd(idx_interval_ac,3)==1);
    idx_write=find(lists_cmd(idx_interval_ac,3)==0);
    size_t=size(idx_interval,1);
    size_r=size(idx_read,1);
    size_w=size(idx_write,1);
    IOPS_ave(i,:)=[end_time,size_t/time_interval,size_w/time_interval,size_r/time_interval]; % time, total, write, read
    
    if size_t>0
        rs_t=sum(lists_cmd(idx_interval_ac,2))/size_t; % request size read
    else
        rs_t=0;
    end
    if size_r>0
        rs_r=sum(lists_cmd(idx_interval_ac(idx_read),2))/size_r;
    else
        rs_r=0;
    end
    if size_w>0
        rs_w=sum(lists_cmd(idx_interval_ac(idx_write),2))/(size_w);
    else
        rs_w=0;
    end
    req_size_ave(i,:)=[end_time,rs_t,rs_w,rs_r];
    
    tp_t=sum(lists_cmd(idx_interval_ac,2))/time_interval; % throughput read
    tp_r=sum(lists_cmd(idx_interval_ac(idx_read),2))/time_interval;
    throuput_ave(i,:)=[end_time,tp_t,tp_t-tp_r,tp_r];
    
    %         if i==65
    %             'disp'
    %         end
    %startpos=idx_interval_ac(size_t);
end
%     idx=find(IOPS_ave(:,2)==0);
%     IOPS_ave(idx,2)=NaN;

average_record.IOPS_ave=IOPS_ave;
average_record.throuput_ave=throuput_ave;
average_record.req_size_ave=req_size_ave;

if plot_figure==1
    
    if isfield(options,'output_foldername')
        output_foldername=options.output_foldername;
    else
        output_foldername='';
    end
    
    figure;
    hold on;
    plot(IOPS_ave(:,1),IOPS_ave(:,2),'r:');
    plot(IOPS_ave(:,1),IOPS_ave(:,3),'b-');
    plot(IOPS_ave(:,1),IOPS_ave(:,4),'k-.');
    xlabel('time (s)');
    ylabel('IOPS');
    legend('Combined','Write','Read');
    title(['Estimated IOPS @', num2str(time_interval), 'seconds interval'])
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize);
    filename=[output_foldername 'iops_',num2str(time_interval)];
    if save_figure
        saveas(gcf,[filename,'.eps'], 'psc2');
        saveas(gcf,[filename,'.fig']);
    end
    
    %     idx=find(throuput_ave(:,2)==0);
    %     throuput_ave(idx,2)=NaN;
    
    figure;
    hold on
    plot(throuput_ave(:,1),throuput_ave(:,2)/2048,'r:');
    plot(throuput_ave(:,1),throuput_ave(:,3)/2048,'b-');
    plot(throuput_ave(:,1),throuput_ave(:,4)/2048,'k-.');
    xlabel('time (s)');
    ylabel('throuput (MBPS)');
    legend('Combined','Write','Read');
    title(['Estimated Average Throughput @', num2str(time_interval), 'seconds interval'])
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize);
    filename=[output_foldername 'throughput_',num2str(time_interval)];
    if save_figure
        saveas(gcf,[filename,'.eps'], 'psc2');
        saveas(gcf,[filename,'.fig']);
    end
    
    %     idx=find(req_size_ave(:,2)==0);
    %     req_size_ave(idx,2)=NaN;
    
    figure;
    hold on
    plot(req_size_ave(:,1),req_size_ave(:,2)/2048,'r:');
    plot(req_size_ave(:,1),req_size_ave(:,3)/2048,'b-');
    plot(req_size_ave(:,1),req_size_ave(:,4)/2048,'k-.');
    xlabel('time (s)');
    ylabel('MB');
    legend('Combined','Write','Read');
    title(['Estimated Average Request Size @', num2str(time_interval), 'seconds interval'])
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize);
    
    filename=[output_foldername 'reqsize_',num2str(time_interval)];
    if save_figure
        saveas(gcf,[filename,'.eps'], 'psc2');
        saveas(gcf,[filename,'.fig']);
    end
end

if options.export_report
    options.section_name='IOPS and Throughput'
    generate_ppt(options)
    string0=[
        'IOPS average (C/W/R) = ', num2str(mean(IOPS_ave(:,2))), '  ', num2str(mean(IOPS_ave(:,3))), ' ', num2str(mean(IOPS_ave(:,4))), char(10),...
        'Throughput average (C/W/R) = ',num2str(mean(throuput_ave(:,2))), '  ', num2str(mean(throuput_ave(:,3))), '  ', num2str(mean(throuput_ave(:,4))), char(10),...
        'Request Size average (C/W/R) = ', num2str(mean(req_size_ave(:,2))),'  ', num2str(mean(req_size_ave(:,3))), '  ', num2str(mean(req_size_ave(:,4))), ];
    saveppt2(options.report_name,'f',0,'t',string0)
end


