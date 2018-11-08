function stack_wow_record=sub_stack_wow(lists_cmd,options)
% stack_wow_record=sub_stack_wow(lists_cmd,options)
% stack distance analysis - Write On Write
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
%
% outputs
%   stack_wow_record: structure for statistics of statcked WOW
%       stack_dist_record_partial;  1/2 partial hit frequency and
%       overlapped size;  index shows the stack distance
%       stack_dist_record_full:  1/2: full hit frequency & overlapped request size;
%       size_dist: 1: full; 2: partial
%       lba_dist:   LBA distribution, 1: full, 2: partial, 3: lba range
%       cdf_record_full:  % 1: stack distance, 2: full hit frequency cdf,
%       3: full hit size/blocks cdf
%       cdf_record_partial:  % 1: stack distance, 2: partial hit frequency
%       cdf, 3: partial hit size/blocks cdf
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

if isfield(options, 'export_report')
    export_report=options.export_report;
else
    export_report=1;
end


% write on write
[stack_dist_record_partial,stack_dist_record_full,size_dist,lba_dist]=stack_distance(lists_cmd, 0);

min_max_stack=min(size(stack_dist_record_partial,2), size(stack_dist_record_full,2));

if isfield(options, 'spec_stack')
    spec_stack=options.spec_stack;
elseif min_max_stack>30
    spec_stack=[10 20 30];
elseif min_max_stack>20
    spec_stack=[5 10 15];
elseif min_max_stack>10
    spec_stack=[2 4 8];
elseif min_max_stack>5
    spec_stack=[1 3 5];
else
    spec_stack=[1];
end

f_cdf=figure;
hold on;
f_cdf_size=figure;
hold on;
step1=1;


stack_wow_record.stack_dist_record_partial=stack_dist_record_partial;% 1/2 partial hit frequency and overlapped size
stack_wow_record.stack_dist_record_full=stack_dist_record_full; % 1/2: full hit frequency & overlapped request size;
stack_wow_record.size_dist=size_dist; % 1: full; 2: partial
stack_wow_record.lba_dist=lba_dist;  % LBA distribution, 1: full, 2: partial, 3: lba range

if plot_figure==1
    stack_wow_hit_record=zeros(size(spec_stack,2),4);
    
    f2=figure;
    subplot(2,1,1)
    idx_nonzero=find(stack_dist_record_partial(:,1)>0,1,'last');
    plot(1:idx_nonzero,stack_dist_record_partial(1:idx_nonzero,1), 'r*','MarkerSize',1.5);
    total_partial_hit=sum(stack_dist_record_partial(1:idx_nonzero,1));
    average_partial_size=sum(stack_dist_record_partial(1:idx_nonzero,2))/total_partial_hit;
    xlabel('Stack distance ');
    ylabel('Frequency');
    title(['Write only: total partial hit = ',int2str(total_partial_hit),'; average overlap size = ', num2str(average_partial_size),' blocks']);
    
    if ~isempty(stack_dist_record_partial)
        for kk0=1:size(spec_stack,2)
            stack_wow_hit_record(kk0,1)=sum(stack_dist_record_partial(1:spec_stack(kk0),1)); % hit command number
            stack_wow_hit_record(kk0,2)=mean(stack_dist_record_partial(1:spec_stack(kk0),2)); % hit command average size
        end
    end
    
    
    steps1=ceil(idx_nonzero/step1)+1;
    cdf_record=zeros(steps1,3); % time; hit cdf; size cdf
    cdf_record(2:steps1,1)=(1:steps1-1)*step1;
    for i=2:steps1-1
        cdf_record(i,2)=cdf_record(i-1,2)+sum(stack_dist_record_partial((i-2)*step1+1:(i-1)*step1,1));
        cdf_record(i,3)=cdf_record(i-1,3)+sum(stack_dist_record_partial((i-2)*step1+1:(i-1)*step1,2));
    end
    cdf_record(steps1,2)=cdf_record(i-1,2)+sum(stack_dist_record_partial((steps1-1)*step1+1:idx_nonzero,1));
    cdf_record(steps1,3)=cdf_record(i-1,3)+sum(stack_dist_record_partial((steps1-1)*step1+1:idx_nonzero,2));
    figure(f_cdf);
    plot(cdf_record(:,1),cdf_record(:,2)/total_partial_hit,'r-.')
    figure(f_cdf_size);
    plot(cdf_record(:,1),cdf_record(:,3)/sum(stack_dist_record_partial(1:idx_nonzero,2)),'r-.')
    
    stack_wow_record.cdf_record_partial=cdf_record;  % 1: stack distance, 2: partial hit frequency, 3: partial hit size/blocks
    
    figure(f2);
    subplot(2,1,2)
    idx_nonzero=find(stack_dist_record_full(:,1)>0,1,'last');
    plot(1:idx_nonzero,stack_dist_record_full(1:idx_nonzero), 'r*','MarkerSize',1.5);
    total_full_hit=sum(stack_dist_record_full(1:idx_nonzero,1));
    average_full_size=sum(stack_dist_record_full(1:idx_nonzero,2))/total_full_hit;
    xlabel('Stack distance ');
    ylabel('Frequency');
    title(['Write only: total full hit = ',int2str(total_full_hit),'; average overlap size = ', num2str(average_full_size),' blocks']);
    if ~isempty(stack_dist_record_full)
        for kk0=1:size(spec_stack,2)
            stack_wow_hit_record(kk0,3)= sum(stack_dist_record_full(1:spec_stack(kk0),1));
            stack_wow_hit_record(kk0,4)=mean(stack_dist_record_full(1:spec_stack(kk0),2));
        end
    end
    if save_figure
        saveas(gcf,'stack_dist_write.eps', 'psc2');
        saveas(gcf,'stack_dist_write.fig');
    end
    
    
    
    figure(f_cdf);
    steps1=ceil(idx_nonzero/step1)+1;
    cdf_record=zeros(steps1,3);
    cdf_record(2:steps1,1)=(1:steps1-1)*step1;
    for i=2:steps1-1
        cdf_record(i,2)=cdf_record(i-1,2)+sum(stack_dist_record_full((i-2)*step1+1:(i-1)*step1,1));
        cdf_record(i,3)=cdf_record(i-1,3)+sum(stack_dist_record_full((i-2)*step1+1:(i-1)*step1,2));
    end
    cdf_record(steps1,2)=cdf_record(i-1,2)+sum(stack_dist_record_full((steps1-1)*step1+1:idx_nonzero,1));
    cdf_record(steps1,3)=cdf_record(i-1,3)+sum(stack_dist_record_full((steps1-1)*step1+1:idx_nonzero,2));
    figure(f_cdf);
    plot(cdf_record(:,1),cdf_record(:,2)/total_full_hit,'b-')
    xlabel('Stack distance ');
    ylabel('CDF');
    title('Write Hit CDF')
    legend('Partial', 'Full')
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
    saveas(gcf,'stacked_update1.eps', 'psc2');
    saveas(gcf,'stacked_update1.fig');
    
    figure(f_cdf_size);
    plot(cdf_record(:,1),cdf_record(:,3)/sum(stack_dist_record_full(1:idx_nonzero,2)),'b-')
    xlabel('Stack distance ');
    ylabel('CDF');
    title('Write Size CDF')
    legend('Partial', 'Full')
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
    if save_figure
        saveas(gcf,'stacked_update2.eps', 'psc2');
        saveas(gcf,'stacked_update2.fig');
    end
    
    stack_wow_record.cdf_record_full=cdf_record;  % 1: stack distance, 2: full hit frequency, 3: full hit size/blocks
    
    figure;
    size_dist_idx=find(size_dist==0);
    size_dist_plot=size_dist;
    size_dist_plot(size_dist_idx)=NaN;
    subplot(2,1,1);
    hold on;
    plot(1:1024,size_dist_plot(:,2),'b*');
    xlabel('Block size ');
    ylabel('Partial Frequency');
    title('Write Partial Hit Distribution (size)')
    subplot(2,1,2)
    plot(1:1024,size_dist_plot(:,1),'r^');
    xlabel('Block size ');
    ylabel('Full Frequency');
    title('Write Full Hit Distribution (size)')
    % legend('Partial', 'Full')
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
    if save_figure
        saveas(gcf,'WU_size_dist.eps', 'psc2');
        saveas(gcf,'WU_size_dist.fig');
    end
    
    figure;
    hold on;
    
    % auto scale the LBA range, such that the zero tails in both sides are
    % not plotted.
    idx_l=find(lba_dist(:,2)>0,1,'first');
    idx_r=find(lba_dist(:,2)>0,1,'last');
    idx_part=[idx_l:idx_r];
    
    idx_l=find(lba_dist(:,1)>0,1,'first');
    idx_r=find(lba_dist(:,1)>0,1,'last');
    idx_full=[idx_l:idx_r];
    
    lba_dist_idx=find(lba_dist==0);
    lba_dist_plot=lba_dist;
    lba_dist_plot(lba_dist_idx)=NaN;
    
    
    subplot(2,1,1);
    plot(lba_dist(idx_part,3),lba_dist_plot(idx_part,2),'b*');
    xlabel('LBA range ');
    ylabel('Partial Frequency ');
    title('Write Partial Hit Distribution (LBA)')
    subplot(2,1,2);
    plot(lba_dist(idx_full,3),lba_dist_plot(idx_full,1),'r^');
    xlabel('LBA range ');
    ylabel('Full Frequency');
    title('Write Full Hit Distribution (LBA)')
    
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
    if save_figure
        saveas(gcf,'WU_LBA_dist.eps', 'psc2');
        saveas(gcf,'WU_LBA_dist.fig');
    end
end

if export_report
    options.section_name='Stacked WOW'
    generate_ppt(options)
    
    cdf_record2=cdf_record(:,2)/total_full_hit;
    set0=[0.1:0.1:0.8,0.85:0.05:1];
    idx8=[];
    for i8=1:size(set0,2)
        idx80=find(cdf_record2>=set0(i8),1,'first');
        idx8=[idx8 idx80];
    end
    cdf_record2=[cdf_record(idx8,1) cdf_record2(idx8)];
    string0=string_generate(cdf_record2,size(cdf_record2,1));
    string0=['Stacked WOW ()=',string0];
    saveppt2(options.report_name,'f',0,'t',string0);
    
    string0=string_generate([total_partial_hit, average_partial_size, total_full_hit, average_full_size],size([total_partial_hit, average_partial_size, total_full_hit, average_full_size],1));
    string0=['overall partial/full hit numbers/average size()=', char(10), string0];
    saveppt2(options.report_name,'f',0,'t',string0);
    
    string0=string_generate([spec_stack;    stack_wow_hit_record'],size([spec_stack;  stack_wow_hit_record'],1));
    string0=['stacked distance and hit numbers/average size()=', char(10), string0];
    saveppt2(options.report_name,'f',0,'t',string0);
    stack_wow_record.stack_wow_hit_record=stack_wow_hit_record;
end


% legend('Partial', 'Full')

%     %% read
%     [stack_dist_record_partial,stack_dist_record_full]=stack_distance(lists_cmd, 1);
%     f_cdf=figure;
%     hold on;
%     f_cdf_size=figure;
%     hold on;
%     step1=10;
%
%     f2=figure;
%     subplot(2,1,1)
%     idx_nonzero=find(stack_dist_record_partial(:,1)>0,1,'last');
%     plot(1:idx_nonzero,stack_dist_record_partial(1:idx_nonzero,1), 'r*','MarkerSize',1.5);
%     total_partial_hit=sum(stack_dist_record_partial(1:idx_nonzero,1));
%     average_partial_size=sum(stack_dist_record_partial(1:idx_nonzero,2))/total_partial_hit;
%     xlabel('Stack distance ');
%     ylabel('Frequency');
%     title(['Read only: total partial hit = ',int2str(total_partial_hit),'; average overlap size = ', num2str(average_partial_size),' blocks']);
%     sum(stack_dist_record_partial(1:4000,1))
%     mean(stack_dist_record_partial(1:4000,2))
%
%
%     steps1=ceil(idx_nonzero/step1)+1;
%     cdf_record=zeros(steps1,3); % time; hit cdf; size cdf
%     cdf_record(2:steps1,1)=(1:steps1-1)*step1;
%     for i=2:steps1-1
%         cdf_record(i,2)=cdf_record(i-1,2)+sum(stack_dist_record_partial((i-2)*step1+1:(i-1)*step1,1));
%         cdf_record(i,3)=cdf_record(i-1,3)+sum(stack_dist_record_partial((i-2)*step1+1:(i-1)*step1,2));
%     end
%     cdf_record(steps1,2)=cdf_record(i-1,2)+sum(stack_dist_record_partial((steps1-1)*step1+1:idx_nonzero,1));
%     cdf_record(steps1,3)=cdf_record(i-1,3)+sum(stack_dist_record_partial((steps1-1)*step1+1:idx_nonzero,2));
%     figure(f_cdf);
%     plot(cdf_record(:,1),cdf_record(:,2)/total_partial_hit,'r-.')
%     figure(f_cdf_size);
%     plot(cdf_record(:,1),cdf_record(:,3)/sum(stack_dist_record_partial(1:idx_nonzero,2)),'r-.')
%
%     figure(f2);
%     subplot(2,1,2)
%     idx_nonzero=find(stack_dist_record_full(:,1)>0,1,'last');
%     plot(1:idx_nonzero,stack_dist_record_full(1:idx_nonzero), 'r*','MarkerSize',1.5);
%     total_full_hit=sum(stack_dist_record_full(1:idx_nonzero,1));
%     average_full_size=sum(stack_dist_record_full(1:idx_nonzero,2))/total_full_hit;
%     xlabel('Stack distance ');
%     ylabel('Frequency');
%     title(['Read only: total full hit = ',int2str(total_full_hit),'; average overlap size = ', num2str(average_full_size),' blocks']);
%     sum(stack_dist_record_full(1:4000,1))
%     mean(stack_dist_record_full(1:4000,2))
%
%     figure(f_cdf);
%     steps1=ceil(idx_nonzero/step1)+1;
%     cdf_record=zeros(steps1,3);
%     cdf_record(2:steps1,1)=(1:steps1-1)*step1;
%     for i=2:steps1-1
%         cdf_record(i,2)=cdf_record(i-1,2)+sum(stack_dist_record_full((i-2)*step1+1:(i-1)*step1,1));
%         cdf_record(i,3)=cdf_record(i-1,3)+sum(stack_dist_record_full((i-2)*step1+1:(i-1)*step1,2));
%     end
%     cdf_record(steps1,2)=cdf_record(i-1,2)+sum(stack_dist_record_full((steps1-1)*step1+1:idx_nonzero,1));
%     cdf_record(steps1,3)=cdf_record(i-1,3)+sum(stack_dist_record_full((steps1-1)*step1+1:idx_nonzero,2));
%     figure(f_cdf);
%     plot(cdf_record(:,1),cdf_record(:,2)/total_full_hit,'b-')
%     xlabel('Stack distance ');
%     ylabel('CDF');
%     title('Read Hit CDF')
%     legend('Partial', 'Full')
%     figure(f_cdf_size);
%     plot(cdf_record(:,1),cdf_record(:,3)/sum(stack_dist_record_full(1:idx_nonzero,2)),'b-')
%     xlabel('Stack distance ');
%     ylabel('CDF');
%     title('Read Size CDF')
%     legend('Partial', 'Full')


