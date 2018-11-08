function req_size_record=sub_size_dist(lists_action,lists_cmd,options)
% calcuate the size distribution
% inputs
%
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
% 
%   req_size_record
%       req_size_dist: request size distribution for " total, write, read"
%       req_size_cdf: request size cdf for " total, write, read"
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

con0=size(lists_action,1);
% request size distribution
req_size_dist=zeros(1024,3); % total, write, read
idx_write=find(lists_cmd(:,3)==0);
idx_read=find(lists_cmd(:,3)==1);
total_write_num=size(idx_write,1);
total_read_num=con0-total_write_num;
total_num=[con0,total_write_num,total_read_num];
average_read_size=mean(lists_cmd(idx_read,2));
average_write_size=mean(lists_cmd(idx_write,2));
average_size=mean(lists_cmd(:,2));



for i=1:1024
    idx_size=find(lists_cmd(:,2)==i);
    if ~isempty(idx_size)
        req_size_dist(i,1)=size(idx_size,1);
    end
    
    idx_size_write=find(lists_cmd(idx_write,2)==i);
    if ~isempty(idx_size_write)
        req_size_dist(i,2)=size(idx_size_write,1);
    end
    
end
req_size_dist(:,3)=req_size_dist(:,1)-req_size_dist(:,2);
req_size_cdf=zeros(1024,3);
req_size_cdf(1,:)=req_size_dist(1,:);
for i=2:1024
    req_size_cdf(i,:)=req_size_cdf(i-1,:)+req_size_dist(i,:);
end
strs={'Combined', 'Write', 'Read'};
emin=0;
emax=10;


req_size_record.req_size_dist=req_size_dist;
req_size_record.req_size_cdf=req_size_cdf;


if isfield(options, 'plot_figure') && options.plot_figure==1
    for i=1:3
        idx_zero=find(req_size_dist(:,i)==0);
        req_size_dist(idx_zero,i)=NaN;
    end
    for i=1:3
        figure;
        hold on
        [haxes,hline1,hline2]=plotyy(1:1024, req_size_dist(:,i),1:1024, req_size_cdf(:,i)/total_num(i));
        xlabel(haxes(2),'Size (blocks)');
        ylabel(haxes(1),'Frequency');
        ylabel(haxes(2),'CDF');
        for j=1:2
            set(haxes(j),'xscale','log')
            set(haxes(j),'XTick',2.^(emin:emax))
        end
        set(hline1,'MarkerSize',6);
        set(hline2,'MarkerSize',4);
        set(hline1,'LineStyle','^')
        set(hline2,'LineStyle','-')
        %set(hline2,'LineSize',2)
        %legend('Frequency','CDF');
        title([strs{i}, ' Request Size Distribution']);
        set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        saveas(gcf,['size_dist_',strs{i},'.eps'], 'psc2');
        saveas(gcf,['size_dist_',strs{i},'.fig']);
    end
end

if options.export_report
    options.section_name='Size Distribution';
    generate_ppt(options)
    string0=['Total request number (C/W/R) =' int2str(total_num(1)), ' ', int2str(total_num(2)), ' ', int2str(total_num(3))];
    saveppt2(options.report_name,'f',0,'t',string0)
    size_sets=[1, 128,256,512,1024,1025];
    a=size(size_sets,2);
    size_sets_value=zeros(3,a);
    for j0=1:3
        idx_NaN=find(req_size_dist(:,j0)==NaN);
        req_size_dist(idx_zero,j0)=0;
        for i0=1:a-1
            size_sets_value(j0,i0)=sum(req_size_dist(size_sets(i0):size_sets(i0+1)-1,j0));
        end
    end
    for j0=1:3
        size_sets_value(j0,:)=(size_sets_value(j0,:))/total_num(j0);
    end
    
    string0=['ratio [1,127] [128,255][256 511][512 1023][1024]', char(10),...
        'Combined  ', num2str(size_sets_value(1,1)), '  ', num2str(size_sets_value(1,2)), ' ',num2str(size_sets_value(1,3)), ' ',num2str(size_sets_value(1,4)),' ', num2str(size_sets_value(1,5)), char(10),...
        'Write  ',num2str(size_sets_value(2,1)), '  ', num2str(size_sets_value(2,2)), ' ',num2str(size_sets_value(2,3)),' ', num2str(size_sets_value(2,4)), ' ',num2str(size_sets_value(2,5)), char(10),...
        'read = ', num2str(size_sets_value(3,1)), '  ', num2str(size_sets_value(3,2)), ' ',num2str(size_sets_value(3,3)),' ', num2str(size_sets_value(3,4)), ' ',num2str(size_sets_value(3,5)) ];
    saveppt2(options.report_name,'f',0,'t',string0)
    
end