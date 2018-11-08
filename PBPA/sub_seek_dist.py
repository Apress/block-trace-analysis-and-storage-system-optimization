from numpy import zeros, nonzero, shape, arange, transpose
from matplotlib.pylab import plot, xlabel, ylabel, title, legend, figure, hold, savefig 
# from statistics import mode
from scipy.stats import mode 
from scipy import mean, median,std

from seek_distance_stack import seek_distance_stack

class seek_dist_record_class:
   def __init__(self, queue_len_setting, seek_all=[], seek_write_only=[],seek_read_only=[]):
     self.queue_len_setting = queue_len_setting
     self.seek_all = seek_all
     self.seek_write_only=seek_write_only
     self.seek_read_only=seek_read_only

def sub_seek_dist(lists_cmd,options):
    ''' 
  seek_dist_record=sub_seek_dist(lists_cmd,options)
  seek distance calcuation
 
  inputs
    lists_cmd: n samples x 3 for LBA, size, flags
    options: control parameters
        plot_fontsize: the figure's font size
        plot_figure: >=1: plot the figure; otherwise not; default 1
        save_figure: >=1: save the figures
        export_report: >=1: export the figure/data into a ppt
        report_name: report name
        output_foldername: the output folder name for figures and report; default =''
        offset_time:  some trace is not started from zone. in this case. need to find the starting time of first event.
        spec_stack=[10,20,30];  % a vector specify the stack distance, for which we can collect the statistical value and output to the ppt file. for very large dataset ; otherwise specify some small numbers
  outputs
    seek_dist_record: structure for statistics of seek distance
 
  Author: jun.xu99@gmail.com
  '''


    if hasattr(options, 'plot_fontsize'):
         plot_fontsize=options.plot_fontsize
    else:
         plot_fontsize=10;
    
    
    if hasattr(options, 'save_figure'):
         save_figure=options.save_figure
    else:
         save_figure=1;

    if hasattr(options, 'plot_figure'):
         plot_figure=options.plot_figure;
    else:
         plot_figure=1;
     
    
    if hasattr(options,'queue_len_setting'):
        queue_len_setting=options.queue_len_setting
    else:
        queue_len_setting=2 ** (arange(0,8,1))
        
    
    num_queue_setting=shape(queue_len_setting)[0]
    
    if hasattr(options, 'plot_flags'):
        plot_flags=options.plot_flags;
    else:
        plot_flags=['r','k--','b-.','b:','y--','r:','y:','r-.','k-.','y','g:'];
    
    
    if len(plot_flags)<num_queue_setting:
        print('Error! The figure flags for legend is smaller than required');
        return;
    
    
    seek_write_only = zeros(( num_queue_setting, 10)); # 1 total R/W IO number, 2 sequnce number, 3 mean, 4 mean abs, 5 median, 6 mode, 7 mode couter, 8 min abs, 9 max abs, 10 std abs
    seek_read_only = zeros((num_queue_setting, 10));
    seek_all = zeros((num_queue_setting, 10));
    
    
    for queue_id in arange(0, num_queue_setting):
        print('Now check queue ID = '+str(queue_id))
        # write
        seq_cmd_count,write_cmd_count,total_cmd,queued_lba_distance=seek_distance_stack(queue_len_setting[queue_id],lists_cmd,0,0)
        if write_cmd_count > 0:
            x,xi=mode(queued_lba_distance)
            seek_write_only[queue_id,:]=[total_cmd - write_cmd_count,seq_cmd_count,mean(queued_lba_distance),mean(abs(queued_lba_distance)),median(queued_lba_distance),x,xi,min(abs(queued_lba_distance)),max(abs(queued_lba_distance)),std(abs(queued_lba_distance))]
        # read
        seq_cmd_count,read_cmd_count,total_cmd,queued_lba_distance=seek_distance_stack(queue_len_setting[queue_id],lists_cmd,1,0)
        if read_cmd_count > 0:
            x,xi=mode(queued_lba_distance)
            seek_read_only[queue_id,:]=[total_cmd - read_cmd_count,seq_cmd_count,mean(queued_lba_distance),mean(abs(queued_lba_distance)),median(queued_lba_distance),x,xi,min(abs(queued_lba_distance)),max(abs(queued_lba_distance)),std(abs(queued_lba_distance))]
        # combined
        seq_cmd_count,all_cmd_count,total_cmd,queued_lba_distance=seek_distance_stack(queue_len_setting[queue_id],lists_cmd,2,0)
        if all_cmd_count:
            x,xi=mode(queued_lba_distance)
            # write command number, sequential command number, average queue LBA distance, average absolute queue LBA distance, median, mode value,mode frequency,min, max, std
            seek_all[queue_id,:]=[total_cmd - all_cmd_count,seq_cmd_count,mean(queued_lba_distance),mean(abs(queued_lba_distance)),median(queued_lba_distance),x,xi,min(abs(queued_lba_distance)),max(abs(queued_lba_distance)),std(abs(queued_lba_distance))]
    
    seek_dist_record=[]
    seek_dist_record=seek_dist_record_class(queue_len_setting, seek_all, seek_write_only,seek_read_only)
    
    
    if plot_figure==1:
       
        figure();
        # hold(True)
        plot(transpose(queue_len_setting),seek_write_only[:,6],'b-')
        plot(transpose(queue_len_setting),seek_read_only[:,6],'r:')
        plot(transpose(queue_len_setting),seek_all[:,6],'k-.')
        xlabel('Queue length ');
        ylabel('Frequency');
        title('Mode Counter')
        legend(['write','read','combined'])
        savefig('sk_mode.eps');
        savefig('sk_mode.png');
        
        figure();
        # hold(True)
        plot(transpose(queue_len_setting),seek_write_only[:,2],'b-')
        plot(transpose(queue_len_setting),seek_read_only[:,2],'r:')
        plot(transpose(queue_len_setting),seek_all[:,2],'k-.')
        xlabel('Queue length ');
        ylabel('Value');
        title('Mean Value')
        legend(['write','read','combined'])
        savefig('sk_mean.eps');
        savefig('sk_mean.png');
        
        
        figure();
        # hold(True)
        plot(transpose(queue_len_setting),seek_write_only[:,3],'b-')
        plot(transpose(queue_len_setting),seek_read_only[:,3],'r:')
        plot(transpose(queue_len_setting),seek_all[:,3],'k-.')
        xlabel('Queue length ');
        ylabel('Value');
        title('Mean Absolute Value')
        legend(['write','read','combined'])
        savefig('sk_abs_mean.eps');
        savefig('sk_abs_mean.png');
        
        figure();
        # hold(True)
        plot(transpose(queue_len_setting),seek_write_only[:,8],'b-')
        plot(transpose(queue_len_setting),seek_read_only[:,8],'r:')
        plot(transpose(queue_len_setting),seek_all[:,8],'k-.')
        xlabel('Queue length ');
        ylabel('Value');
        title('Maximum Seek Distance')
        legend(['write','read','combined'])
        savefig('sk_max.eps');
        savefig('sk_max.png');
    
    
#    if options.export_report:
#        options.section_name='Seek Distance'
#        generate_ppt(options)
#        
#        string0=string_generate([queue_len_setting';seek_write_only(:,6)],20);
#        string0=['Mode value (write)=',string0];
#        saveppt2(options.report_name,'f',0,'t',string0);
#        
#        string0=string_generate([queue_len_setting';seek_write_only(:,7)],20);
#        string0=['Mode count (write)=',string0];
#        saveppt2(options.report_name,'f',0,'t',string0);
#        
#        string0=string_generate([queue_len_setting';seek_read_only(:,6)],20);
#        string0=['Mode value (read)=',string0];
#        saveppt2(options.report_name,'f',0,'t',string0);
#        
#        string0=string_generate([queue_len_setting';seek_read_only(:,7)],20);
#        string0=['Mode count (read)=',string0];
#        saveppt2(options.report_name,'f',0,'t',string0);

    return seek_dist_record