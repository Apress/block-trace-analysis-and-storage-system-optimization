function time_wow_record=sub_time_wow(lists_cmd,options)
%
% time_wow_record=sub_time_wow(lists_cmd,options)
% timed/ordered update ratio - WOW
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
%   time_wow_record: structure for statistics of timed WOW
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

% options.access_type=0;
% options.drive_max_lba=2*1024^4/512;
[update_stat]=write_update_time(lists_cmd, 0,options);
time_wow_record=update_stat;

if plot_figure==1
    
    f_cdf=figure;
    figure(f_cdf);
    hold on;
    plot(1:update_stat.idx_size,update_stat.write_ratio,'r:')
    plot(1:update_stat.idx_size,update_stat.update_ratio,'b-')
    if options.access_type==0
        xlabel('# of write operations');
    elseif options.access_type==2
        xlabel('# of total operations');
    end
    ylabel('Percentage of blocks written/updated');
    title('Write Update CDF (blocks)')
    legend('blocks written','blocks updated')
    grid on;
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
    saveas(gcf,'timed_update1.eps', 'psc2');
    saveas(gcf,'timed_update1.fig');
    
    figure;
    hold on;
    plot(1:update_stat.idx_size,update_stat.write_cmd_ratio,'r:')
    plot(1:update_stat.idx_size,update_stat.hit_ratio,'b-')
    if options.access_type==0;
        xlabel('# of write operations');
    elseif options.access_type==2;
        xlabel('# of total operations');
    end
    
    ylabel('Percentage of command written/updated');
    title('Write Update CDF (commands) ')
    legend('commands written','commands updated')
    grid on;
    set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
    saveas(gcf,'timed_update2.eps', 'psc2');
    saveas(gcf,'timed_update2.fig');
end


if options.export_report
    options.section_name='Timed WOW'
    generate_ppt(options)
    
    string0=string_generate([[1:update_stat.idx_size]',update_stat.write_ratio],30);
    string0=['Write Update CDF (blocks written)=',string0];
    saveppt2(options.report_name,'f',0,'t',string0);
    
    string0=string_generate([[1:update_stat.idx_size]',update_stat.update_ratio],30);
    string0=['Write Update CDF (blocks updated)=',string0];
    saveppt2(options.report_name,'f',0,'t',string0);
    
    string0=string_generate([[1:update_stat.idx_size]',update_stat.write_cmd_ratio],30);
    string0=['Write Update CDF (cmd written)=',string0];
    saveppt2(options.report_name,'f',0,'t',string0);
    
    string0=string_generate([[1:update_stat.idx_size]',update_stat.hit_ratio],30);
    string0=['Write Update CDF (cmd updated)=',string0];
    saveppt2(options.report_name,'f',0,'t',string0);
end