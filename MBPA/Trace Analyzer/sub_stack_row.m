function stack_row_record=sub_stack_row(lists_cmd, options);
% stack_wow_record=sub_stack_row(lists_cmd,options)
% stack distance analysis - ROW
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
%   stack_wow_record: structure for statistics of statcked ROW
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

%% read on write
[stack_dist_record_partial,stack_dist_record_full]=stack_distance_row(lists_cmd, 1);
stack_row_record.stack_dist_record_partial=stack_dist_record_partial;
stack_row_record.stack_dist_record_full=stack_dist_record_full;


if plot_figure==1
    f_cdf=figure;
    hold on;
    f_cdf_size=figure;
    hold on;
    
    min_max_stack=min(size(stack_dist_record_partial,2), size(stack_dist_record_full,2));  
    if min_max_stack>50
        step1=10;
    elseif min_max_stack>20
        step1=5;
    elseif min_max_stack>10
        step1=2;
    else
        step1=1;
    end
    
    f2=figure;
    subplot(2,1,1)
    idx_nonzero=find(stack_dist_record_partial(:,1)>0,1,'last');
    plot(1:idx_nonzero,stack_dist_record_partial(1:idx_nonzero,1), 'r*','MarkerSize',1.5);
    total_partial_hit=sum(stack_dist_record_partial(1:idx_nonzero,1));
    average_partial_size=sum(stack_dist_record_partial(1:idx_nonzero,2))/total_partial_hit;
    xlabel('Stack distance ');
    ylabel('Frequency');
    title(['Read only: total partial hit = ',int2str(total_partial_hit),'; average overlap size = ', num2str(average_partial_size),' blocks']);
    %     sum(stack_dist_record_partial(1:4000,1))
    %     mean(stack_dist_record_partial(1:4000,2))
    sum(stack_dist_record_partial(:,1))
    mean(stack_dist_record_partial(:,2))
    
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
    
    figure(f2);
    subplot(2,1,2)
    idx_nonzero=find(stack_dist_record_full(:,1)>0,1,'last');
    plot(1:idx_nonzero,stack_dist_record_full(1:idx_nonzero), 'r*','MarkerSize',1.5);
    total_full_hit=sum(stack_dist_record_full(1:idx_nonzero,1));
    average_full_size=sum(stack_dist_record_full(1:idx_nonzero,2))/total_full_hit;
    xlabel('Stack distance ');
    ylabel('Frequency');
    title(['Read only: total full hit = ',int2str(total_full_hit),'; average overlap size = ', num2str(average_full_size),' blocks']);
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize);
    %     sum(stack_dist_record_full(1:4000,1))
    %     mean(stack_dist_record_full(1:4000,2))
    sum(stack_dist_record_full(:,1))
    mean(stack_dist_record_full(:,2))
    
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
    title('Read Hit CDF')
    legend('Partial', 'Full')
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize);
    if save_figure
    saveas(gcf,'stacked_row1.eps', 'psc2');
    saveas(gcf,'stacked_row1.fig');
    end
    
    figure(f_cdf_size);
    plot(cdf_record(:,1),cdf_record(:,3)/sum(stack_dist_record_full(1:idx_nonzero,2)),'b-')
    xlabel('Stack distance ');
    ylabel('CDF');
    title('Read Size CDF')
    legend('Partial', 'Full')
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize);
    if save_figure
    saveas(gcf,'stacked_row2.eps', 'psc2');
    saveas(gcf,'stacked_row2.fig');
    end
    
end

if export_report
    options.section_name='Stacked ROW'
    generate_ppt(options)
end
