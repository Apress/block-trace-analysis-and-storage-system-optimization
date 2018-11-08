function lba_stat_array=sub_lba_dist(lists_action,lists_cmd,options)
% lba_stat_array=sub_lba_dist(lists_action,lists_cmd,options)
% stat_record=sub_lba_dist(lists_action,lists_cmd,options)
% --> calcuate the size distribution
%
% inputs
%   lists_action: n samples x 2 array for arrival time and completion time;
%   lists_cmd: n samples x 3 for LBA, size, flags ( (0 write, 1 read))
%   access_type: 0 write, 1 read, 2 all
%   options: control parameters
%       lba_size_set: how many LBA range sets
%
% outputs
%   lba_stat_array: cells structure; LBA statistics for write/read/all
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

if isfield(options, 'lba_size_set')
    %lba_size_set=options.lba_size_set;
else
    options.lba_size_set=50;
end


%5: LBA vs time;

if plot_figure==1
    
    idx_read=find(lists_cmd(:,3)==1);
    idx_write=find(lists_cmd(:,3)==0);
    figure;
    subplot(2,1,1);
    plot(lists_action(idx_read,1),lists_cmd(idx_read,1),'r*','MarkerSize',1);
    ylabel('LBA');
    title('read')
    
    subplot(2,1,2);
    plot(lists_action(idx_write,1),lists_cmd(idx_write,1),'b+','MarkerSize',1);
    ylabel('LBA');
    xlabel('time (s)')
    title('write')
    
    saveas(gcf,'lba_all.eps', 'psc2');
    saveas(gcf,'lba_all.fig');
    saveas(gcf,'lba_all.jpg');
    
    
    for i=0:2
        [stat_record]=lba_size_dist(lists_cmd, i,options);
        
        figure;
        x=1:1024;
        y=stat_record.lba_size_idx;
        if isempty(y)
            continue
        end
        [X,Y]=meshgrid(x,y);
        mesh(X,Y,stat_record.lba_size_dist);
        colorbar;
        ylabel('LBA Range');
        xlabel('Request size');
        zlabel('Frequency');
        if i==0
            title('LBA & Size Disribution - Write ')
        elseif i==1
            title('LBA & Size Disribution - Read ')
        else
            title('LBA & Size Disribution - Combined ')
        end
        set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        grid on;
        if i==1
            saveas(gcf,'lba_size_freq_read.eps', 'psc2');
            saveas(gcf,'lba_size_freq_read.fig');
            saveas(gcf,'lba_size_freq_read.jpg');
        elseif i==0
            saveas(gcf,'lba_size_freq_write.eps', 'psc2');
            saveas(gcf,'lba_size_freq_write.fig');
            saveas(gcf,'lba_size_freq_write.jpg');
        else
            saveas(gcf,'lba_size_freq_com.eps', 'psc2');
            saveas(gcf,'lba_size_freq_com.fig');
            saveas(gcf,'lba_size_freq_com.jpg');
        end
        lba_stat_array{i+1}=stat_record;
    end
end


if options.export_report
    options.section_name='LBA Distribution'
    generate_ppt(options)
end

