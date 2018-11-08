from numpy import zeros, nonzero, shape, arange, transpose, dot, uint8, uint16, uint32, c_,sum,squeeze, ceil,logical_and,add,copy,mod,mean,array
from matplotlib.pylab import plot, xlabel, ylabel, title, legend, figure, hold, savefig, grid 
# from statistics import mode
from scipy.stats import mode 
from scipy import mean, median,std
from sequential_stream_track import sequential_stream_track
from plt_plugins import change_fontsize
from near_sequential_stream_track import near_sequential_stream_track

class sequence_stat_class:
    def __init__(self,average_seq_cmd_size_write_only=None,average_seq_cmd_size_write_only_limited=None,average_seq_stream_size_write_only_limited=None,average_seq_cmd_size_write_only_s=None,average_seq_cmd_size_write_only_s2=None,average_seq_cmd_size_read_only=None,average_seq_cmd_size_read_only_limited=None,average_seq_stream_size_read_only_limited=None,average_seq_cmd_size_read_only_s=None,average_seq_cmd_size_read_only_s2=None,ratio_cmd_count_read_only=None, ratio_cmd_count_read_only_limited=None, ratio_cmd_count_write_only=None, ratio_cmd_count_write_only_limited=None,ratio_cmd_count_all=None,ratio_cmd_count_all_limited=None):
        self.average_seq_cmd_size_write_only=average_seq_cmd_size_write_only
        self.average_seq_cmd_size_write_only_limited=average_seq_cmd_size_write_only_limited
        self.average_seq_stream_size_write_only_limited=average_seq_stream_size_write_only_limited
        self.average_seq_cmd_size_write_only_s=average_seq_cmd_size_write_only_s
        self.average_seq_cmd_size_write_only_s2=average_seq_cmd_size_write_only_s2
        self.average_seq_cmd_size_read_only=average_seq_cmd_size_read_only
        self.average_seq_cmd_size_read_only_limited=average_seq_cmd_size_read_only_limited
        self.average_seq_stream_size_read_only_limited=average_seq_stream_size_read_only_limited
        self.average_seq_cmd_size_read_only_s=average_seq_cmd_size_read_only_s
        self.average_seq_cmd_size_read_only_s2=average_seq_cmd_size_read_only_s2
        self.ratio_cmd_count_read_only=ratio_cmd_count_read_only
        self.ratio_cmd_count_read_only_limited=ratio_cmd_count_read_only_limited
        self.ratio_cmd_count_write_only_limited=ratio_cmd_count_write_only_limited
        self.ratio_cmd_count_write_only=ratio_cmd_count_write_only
        self.ratio_cmd_count_all=ratio_cmd_count_all
        self.ratio_cmd_count_all_limited=ratio_cmd_count_all_limited
        #self.ratio_stream_count_all_limited=ratio_stream_count_all_limited
        
       
def sub_sequence_analysis(lists_action=None,lists_cmd=None,options=None):
    '''
sequential analysis (stream/commands/size/queue length)     
sequence_stat=sub_sequence_analysis(lists_action,lists_cmd,options)
   
  input parameters:
       lists_action: n samples x 2 array for arrival time and completion time;
       lists_cmd: n samples x 3 for LBA, size, flags
       options: control parameters
           plot_fontsize: the figure's font size
           time_interval: the time interval for moving average windows
           plot_figure: >=1: plot the figure; otherwise not; default 1
           save_figure: >=1: save the figures
           export_report: >=1: export the figure/data into a ppt
           report_name: report name
           output_foldername: the output folder name for figures and report; default =''
           offset_time:  some trace is not started from zone. in this case. need to find the starting time of first event.
           near_sequence: default =0, i.e., strictly sequential without any gap
           S2_threshold =32; # limit the minimun number which is counted as sequence stream
           S2_threshold2 =64;
           max_stream_length=1024;
           seq_size_threshold=1024; # the size constrain --> change inside the function
 output parameters
   sequence_stat: structure for statistics of request sequence
  
  Authors jun.xu99@gmail.com and junpeng.niu@wdc.com 
    '''
    
    if hasattr(options,'plot_fontsize'):
        plot_fontsize=options.plot_fontsize
    else:
        plot_fontsize=10
    
    if hasattr(options,'plot_figure'):
        plot_figure=options.plot_figure
    else:
        plot_figure=1
        
    if hasattr(options,'save_figure'):
        save_figure=options.save_figure
    else:
        save_figure=1
    
    if hasattr(options,'near_sequence'):
        near_sequence=options.near_sequence
    else:
        near_sequence=0
    
    if hasattr(options,'S2_threshold'):
        S2_threshold=options.S2_threshold
    else:
        S2_threshold=32
    
    if hasattr(options,'S2_threshold2'):
        S2_threshold2=options.S2_threshold2
    else:
        S2_threshold2=64
    
    if hasattr(options,'seq_size_threshold'):
        seq_size_threshold=options.seq_size_threshold
    else:
        seq_size_threshold=1024
    
    if hasattr(options,'max_stream_length'):
        max_stream_length=options.max_stream_length
    else:
        max_stream_length=1024
    
    if near_sequence == 0:
        options.section_name = ('Strict Sequence')
    else:
        options.section_name = ('Near Sequence')
    
    
    queue_len_setting=2 ** (arange(0,8,1))
    
    num_queue_setting=shape(queue_len_setting)[0]
    total_trace_files=1
    cmd_count_read_only=zeros((total_trace_files,num_queue_setting))
    cmd_count_read_only_limited=zeros((total_trace_files,num_queue_setting))
    stream_count_read_only=zeros((total_trace_files,num_queue_setting))
    stream_count_read_only_limited=zeros((total_trace_files,num_queue_setting))
    
    cmd_count_write_only=zeros((total_trace_files,num_queue_setting))
    stream_count_write_only=zeros((total_trace_files,num_queue_setting))
    cmd_count_write_only_limited=zeros((total_trace_files,num_queue_setting))
    stream_count_write_only_limited=zeros((total_trace_files,num_queue_setting))
    
    cmd_count_all=zeros((total_trace_files,num_queue_setting))
    cmd_count_all_limited=zeros((total_trace_files,num_queue_setting))
    stream_count_all=zeros((total_trace_files,num_queue_setting))
    stream_count_all_limited=zeros((total_trace_files,num_queue_setting))
    
    ratio_cmd_count_read_only=zeros((total_trace_files,num_queue_setting))
    ratio_stream_count_read_only=zeros((total_trace_files,num_queue_setting))
    ratio_cmd_count_write_only=zeros((total_trace_files,num_queue_setting))
    ratio_stream_count_write_only=zeros((total_trace_files,num_queue_setting))
    ratio_cmd_count_all=zeros((total_trace_files,num_queue_setting))
    ratio_stream_count_all=zeros((total_trace_files,num_queue_setting))
    
    ratio_cmd_count_read_only_limited=zeros((total_trace_files,num_queue_setting))
    ratio_stream_count_read_only_limited=zeros((total_trace_files,num_queue_setting))
    ratio_cmd_count_write_only_limited=zeros((total_trace_files,num_queue_setting))
    ratio_stream_count_write_only_limited=zeros((total_trace_files,num_queue_setting))
    ratio_cmd_count_all_limited=zeros((total_trace_files,num_queue_setting))
    ratio_stream_count_all_limited=zeros((total_trace_files,num_queue_setting))
    
    average_seq_cmd_size_read_only=zeros((total_trace_files,num_queue_setting))
    average_seq_cmd_size_write_only=zeros((total_trace_files,num_queue_setting))
    average_seq_cmd_size_all=zeros((total_trace_files,num_queue_setting))
    average_seq_cmd_size_read_only_s=zeros((total_trace_files,num_queue_setting))
    average_seq_cmd_size_write_only_s=zeros((total_trace_files,num_queue_setting))
    average_seq_cmd_size_all_s=zeros((total_trace_files,num_queue_setting))
    average_seq_cmd_size_read_only_s2=zeros((total_trace_files,num_queue_setting))
        
    average_seq_cmd_size_read_only_limited=zeros((total_trace_files,num_queue_setting))
    average_seq_cmd_size_write_only_limited=zeros((total_trace_files,num_queue_setting))
    average_seq_cmd_size_all_limited=zeros((total_trace_files,num_queue_setting))
    average_seq_cmd_size_read_only_s_limited=zeros((total_trace_files,num_queue_setting))
    average_seq_cmd_size_write_only_s_limited=zeros((total_trace_files,num_queue_setting))
    average_seq_cmd_size_all_s_limited=zeros((total_trace_files,num_queue_setting))
    average_seq_stream_size_read_only_limited=zeros((total_trace_files,num_queue_setting))
    average_seq_stream_size_all_limited=zeros((total_trace_files,num_queue_setting))
    average_seq_stream_size_write_only_limited=zeros((total_trace_files,num_queue_setting))
    
    average_seq_cmd_size_all_s2=zeros((total_trace_files,num_queue_setting))
    average_seq_cmd_size_write_only_s2=zeros((total_trace_files,num_queue_setting))
    
    
    if plot_figure == 1:
        hh1f=figure()
        hh1=hh1f.add_subplot(1,1,1)
        #hold('on')
        hh2f=(figure())
        hh2=hh2f.add_subplot(1,1,1)
        #hold('on')
        hh3f=(figure())
        hh3=hh3f.add_subplot(1,1,1)
        #hold('on')
        hl1f=(figure())
        hl1=hl1f.add_subplot(1,1,1)
        #hold('on')
        hl2f=(figure())
        hl2=hl2f.add_subplot(1,1,1)
        #hold('on')
        hl3f=(figure())
        hl3=hl3f.add_subplot(1,1,1)
        #hold('on')
        legend_str=''
        plot_flags=(['r','b--','b-.','r:','y--','r:','k:','y:','k-.'])
    
    file_id=0
    # seq_stream_length_count_read_only:  value at array index i corresponding to
    # the number/frequecy of commands with sequence command length =i;
    # seq_stream_length_count_read_only_limited: besides the above
    # condition, it also satisfies the mininum total request size of
    # this stream is larger than 1024
    # n_cmd: sequential commands number
    # n_seq: sequential stream number
    # n_read: total read number
    # n_total: total command number
    # size_dist_read_only: request size disribution    
    for queue_id in arange(0,num_queue_setting).reshape(-1):

        queue_len=queue_len_setting[queue_id]
        if near_sequence == 1:
            n_cmd,n_seq,n_read,n_total,size_dist_read_only,seq_stream_length_count_read_only,seq_stream_length_count_read_only_limited,record_read=near_sequential_stream_track(queue_len,lists_cmd,1,seq_size_threshold)
        else:
            n_cmd,n_seq,n_read,n_total,size_dist_read_only,seq_stream_length_count_read_only,seq_stream_length_count_read_only_limited,record_read=sequential_stream_track(queue_len,lists_cmd,1,seq_size_threshold)
        cmd_count_read_only[file_id,queue_id]=n_cmd
        stream_count_read_only[file_id,queue_id]=n_seq
        cmd_count_read_only_limited[file_id,queue_id]=record_read.cmd_number
        stream_count_read_only_limited[file_id,queue_id]=record_read.stream_number
        ratio_cmd_count_read_only_limited[file_id,queue_id]=record_read.cmd_number / n_read
        ratio_cmd_count_read_only[file_id,queue_id]=n_cmd / n_read
        ratio_stream_count_read_only[file_id,queue_id]=n_seq / n_read
        idx=shape(size_dist_read_only)[0]
        average_seq_cmd_size_read_only[file_id,queue_id]=(dot((arange(1,idx+1)),size_dist_read_only)) / sum(size_dist_read_only)
        average_seq_cmd_size_read_only_limited[file_id,queue_id]=sum(seq_stream_length_count_read_only_limited[:,1]) / record_read.cmd_number
        average_seq_stream_size_read_only_limited[file_id,queue_id]=sum(seq_stream_length_count_read_only_limited[:,1]) / stream_count_read_only_limited[file_id,queue_id]
        average_seq_cmd_size_read_only_s[file_id,queue_id]=(dot((arange(S2_threshold,idx+1)),size_dist_read_only[S2_threshold-1:idx])) / sum(size_dist_read_only[S2_threshold-1:idx])
        average_seq_cmd_size_read_only_s2[file_id,queue_id]=(dot((arange(S2_threshold2,idx+1)),size_dist_read_only[S2_threshold2-1:idx])) / sum(size_dist_read_only[S2_threshold2-1:idx])
        #         if idxs>max_stream_length
    #             idx_ex=find(seq_stream_length_count_read_only(max_stream_length+1:idxs)>0);
    #             idx_ex_ac=max_stream_length+idx_ex;
    #             seq_stream_length_count_read_only_adjust=seq_stream_length_count_read_only(1:max_stream_length);
        #         end
    #         frequency_cmd_count_read_only(file_id, queue_id)=sum(seq_stream_length_count_read_only(S2_threshold:1024));
        ## all
        if near_sequence == 1:
            n_cmd_all,n_seq_all,n_read,n_total,size_dist_all,seq_stream_length_count_all,seq_stream_length_count_all_limited,record_all=near_sequential_stream_track(queue_len,lists_cmd,2,seq_size_threshold)
        else:
            n_cmd_all,n_seq_all,n_read,n_total,size_dist_all,seq_stream_length_count_all,seq_stream_length_count_all_limited,record_all=sequential_stream_track(queue_len,lists_cmd,2,seq_size_threshold)
            
        cmd_count_all[file_id,queue_id]=n_cmd_all
        stream_count_all[file_id,queue_id]=n_seq_all
        ratio_cmd_count_all[file_id,queue_id]=n_cmd_all / n_total
        cmd_count_all_limited[file_id,queue_id]=record_all.cmd_number
        stream_count_all_limited[file_id,queue_id]=record_all.stream_number
        ratio_cmd_count_all_limited[file_id,queue_id]=record_all.cmd_number / n_total
        ratio_stream_count_all[file_id,queue_id]=n_seq_all / n_total
        idx=shape(size_dist_all)[0]
        average_seq_cmd_size_all[file_id,queue_id]=(dot((arange(1,idx+1)),size_dist_all)) / sum(size_dist_all)
        average_seq_cmd_size_all_limited[file_id,queue_id]=sum(seq_stream_length_count_all_limited[:,1]) / record_all.cmd_number
        average_seq_stream_size_all_limited[file_id,queue_id]=sum(seq_stream_length_count_all_limited[:,1]) / stream_count_all_limited[file_id,queue_id]
        average_seq_cmd_size_all_s[file_id,queue_id]=(dot((arange(S2_threshold,idx+1)),size_dist_all[S2_threshold-1:idx])) / sum(size_dist_all[S2_threshold-1:idx])
        average_seq_cmd_size_all_s2[file_id,queue_id]=(dot((arange(S2_threshold2,idx+1)),size_dist_all[S2_threshold2-1:idx])) / sum(size_dist_all[S2_threshold2-1:idx])
        
        
        if near_sequence == 1:
            n_cmd_write_only,n_seq_write_only,n_read,n_total,size_dist_write_only,seq_stream_length_count_write_only,seq_stream_length_count_write_only_limited,record_write=near_sequential_stream_track(queue_len,lists_cmd,0,seq_size_threshold)
        else:
            n_cmd_write_only,n_seq_write_only,n_read,n_total,size_dist_write_only,seq_stream_length_count_write_only,seq_stream_length_count_write_only_limited,record_write=sequential_stream_track(queue_len,lists_cmd,0,seq_size_threshold)
        cmd_count_write_only[file_id,queue_id]=n_cmd_write_only
        stream_count_write_only[file_id,queue_id]=n_seq_write_only
        n_write=n_total - n_read
        #print([n_total,n_write,n_read])
        ratio_cmd_count_write_only[file_id,queue_id]=n_cmd_write_only / n_write
        cmd_count_write_only_limited[file_id,queue_id]=record_write.cmd_number
        stream_count_write_only_limited[file_id,queue_id]=record_write.stream_number
        ratio_cmd_count_write_only_limited[file_id,queue_id]=record_write.cmd_number / n_write
        ratio_stream_count_write_only[file_id,queue_id]=n_seq_write_only / n_write
        idx=shape(size_dist_write_only)[0]
        average_seq_cmd_size_write_only[file_id,queue_id]=(dot((arange(1,idx+1)),size_dist_write_only)) / sum(size_dist_write_only)
        average_seq_cmd_size_write_only_limited[file_id,queue_id]=sum(seq_stream_length_count_write_only_limited[:,1]) / cmd_count_write_only_limited[file_id,queue_id]
        average_seq_stream_size_write_only_limited[file_id,queue_id]=sum(seq_stream_length_count_write_only_limited[:,1]) / stream_count_write_only_limited[file_id,queue_id]
        average_seq_cmd_size_write_only_s[file_id,queue_id]=(dot((arange(S2_threshold,idx+1)),size_dist_write_only[S2_threshold-1:idx])) / sum(size_dist_write_only[S2_threshold-1:idx])
        average_seq_cmd_size_write_only_s2[file_id,queue_id]=(dot((arange(S2_threshold2,idx+1)),size_dist_write_only[S2_threshold2-1:idx])) / sum(size_dist_write_only[S2_threshold2-1:idx])
    
    
        if plot_figure == 1:
            
            #figure(hh1)
            idx=nonzero(seq_stream_length_count_read_only[:,0] > 0)
            if shape(idx)[1]>1:
                idx=idx[0][-1]
                hh1.plot(arange(2,idx+2),seq_stream_length_count_read_only[1:idx+1,0],plot_flags[queue_id],label=str(queue_len_setting[queue_id]))
            #figure(hh2)
            idx=nonzero(seq_stream_length_count_write_only[:,0] > 0)
            if shape(idx)[1]>1:
                idx=idx[0][-1]
                hh2.plot(arange(2,idx+2),seq_stream_length_count_write_only[1:idx+1,0],plot_flags[queue_id],label=str(queue_len_setting[queue_id]))
            #figure(hh3)
            idx=nonzero(seq_stream_length_count_all[:,0] > 0)
            if shape(idx)[1]>1:
                idx=idx[0][-1]
                hh3.plot(arange(2,idx+2),seq_stream_length_count_all[1:idx+1,0],plot_flags[queue_id],label=str(queue_len_setting[queue_id]))
            #figure(hl1)
            idx=nonzero(seq_stream_length_count_read_only_limited[:,0] > 0)
            if shape(idx)[1]>1:
                idx=idx[0][-1]
                hl1.plot(arange(2,idx+2),seq_stream_length_count_read_only_limited[1:idx+1,0],plot_flags[queue_id],label=str(queue_len_setting[queue_id]))
            #figure(hl2)
            idx=nonzero(seq_stream_length_count_write_only_limited[:,0] > 0)
            if shape(idx)[1]>1:
                idx=idx[0][-1]
                hl2.plot(arange(2,idx+2),seq_stream_length_count_write_only_limited[1:idx+1,0],plot_flags[queue_id],label=str(queue_len_setting[queue_id]))
            #figure(hl3)
            idx=nonzero(seq_stream_length_count_all_limited[:,0] > 0)
            if shape(idx)[1]>1:
                idx=idx[0][-1]
                hl3.plot(arange(2,idx+2),seq_stream_length_count_all_limited[1:idx+1,0],plot_flags[queue_id],label=str(queue_len_setting[queue_id]))
            if queue_id == num_queue_setting:
                legend_str=((legend_str+' '+str(queue_len_setting[queue_id])+' '))
            else:
                legend_str=((legend_str+' '+str(queue_len_setting[queue_id])+',' ))
    
    sequence_stat=sequence_stat_class()
    sequence_stat.average_seq_cmd_size_write_only = copy(average_seq_cmd_size_write_only)
    sequence_stat.average_seq_cmd_size_write_only_limited = copy(average_seq_cmd_size_write_only_limited)
    sequence_stat.average_seq_stream_size_write_only_limited = copy(average_seq_stream_size_write_only_limited)
    sequence_stat.average_seq_cmd_size_write_only_s = copy(average_seq_cmd_size_write_only_s)
    sequence_stat.average_seq_cmd_size_write_only_s2 = copy(average_seq_cmd_size_write_only_s2)
    sequence_stat.average_seq_cmd_size_read_only = copy(average_seq_cmd_size_read_only)
    sequence_stat.average_seq_cmd_size_read_only_limited = copy(average_seq_cmd_size_read_only_limited)
    sequence_stat.average_seq_stream_size_read_only_limited = copy(average_seq_stream_size_read_only_limited)
    sequence_stat.average_seq_cmd_size_read_only_s = copy(average_seq_cmd_size_read_only_s)
    sequence_stat.average_seq_cmd_size_read_only_s2 = copy(average_seq_cmd_size_read_only_s2)
    
    sequence_stat.ratio_cmd_count_read_only=ratio_cmd_count_read_only
    sequence_stat.ratio_cmd_count_read_only_limited=ratio_cmd_count_read_only_limited
    sequence_stat.ratio_cmd_count_write_only_limited=ratio_cmd_count_write_only_limited
    sequence_stat.ratio_cmd_count_write_only=ratio_cmd_count_write_only
    sequence_stat.ratio_cmd_count_all=ratio_cmd_count_all
    sequence_stat.ratio_cmd_count_all_limited=ratio_cmd_count_all_limited
    
    if plot_figure == 1:
        if near_sequence == 1:
            t_str='Near Sequential'
        else:
            t_str='Sequential'
        # figure(hh1)
        hh1.set_xlabel('Number of requests in queue')
        hh1.set_ylabel('Frequency')
        hh1.set_title((t_str+' Stream Read Only w/o constraint'))
        hh1.set_xscale('log')
        # set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        change_fontsize(hh1,plot_fontsize)
        handles, labels = hh1.get_legend_handles_labels()
        hh1.legend(handles, labels)     
        savefig(('seq_stream_read.eps'))
        savefig('seq_stream_read.png')
        
        #figure(hh2)
        hh2.set_xlabel('Number of requests in queue')
        hh2.set_ylabel('Frequency')
        hh2.set_title((t_str+' Stream Write Only w/o constraint'))
        hh2.set_xscale('log')
        # set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        handles, labels = hh2.get_legend_handles_labels()
        hh2.legend(handles, labels)      
        change_fontsize(hh2,plot_fontsize)
        savefig('seq_stream_write.eps')
        savefig('seq_stream_write.png')
        
        #figure(hh3)
        hh3.set_xlabel('Number of requests in queue')
        hh3.set_ylabel('Frequency')
        hh3.set_title((t_str+' Stream Combined w/o constraint'))
        hh3.set_xscale('log')
        change_fontsize(hh3,plot_fontsize)
        handles, labels = hh3.get_legend_handles_labels()
        hh3.legend(handles, labels)      
        #     set(findall(gcf,'-property','FontSize'),'FontSize',20)
        savefig('seq_stream_com.eps')
        savefig('seq_stream_com.png')
    
        #figure(hl1)
        hl1.set_xlabel('Number of requests in queue')
        hl1.set_ylabel('Frequency')
        hl1.set_title(t_str+' Stream Read Only with Size Contraint')
        hl1.set_xscale('log')
        #set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        change_fontsize(hl1,plot_fontsize)
        handles, labels = hl1.get_legend_handles_labels()
        hl1.legend(handles, labels)      
        savefig(('seq_stream_read_size'+'_'+str(seq_size_threshold)+'.eps'))
        savefig(('seq_stream_read_size'+'_'+str(seq_size_threshold)+'.png'))
        
        #figure(hl2)
        hl2.set_xlabel('Number of requests in queue')
        hl2.set_ylabel('Frequency')
        hl2.set_title(t_str+' Stream Write Only with Size Contraint')
        hl2.set_xscale('log')
        #set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        change_fontsize(hl2,plot_fontsize)
        handles, labels = hl2.get_legend_handles_labels()
        hl2.legend(handles, labels)      
        savefig(('seq_stream_write_size'+'_'+str(seq_size_threshold)+'.eps'))
        savefig(('seq_stream_write_size'+'_'+str(seq_size_threshold)+'.png'))
        
        #figure(hl3)
        hl3.set_xlabel('Number of requests in queue')
        hl3.set_ylabel('Frequency')
        hl3.set_title(t_str+' Stream Combined with Size Contraint')
        #eval(cat('legend(',legend_str,',','\'','Location','\'',',','\'','NorthEast','\'',')'))
        #set(gca,'xscale','log')
        hl3.set_xscale('log')
        #set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        change_fontsize(hl3,plot_fontsize)
        handles, labels = hl3.get_legend_handles_labels()
        hl3.legend(handles, labels)      
        savefig(('seq_stream_com_size'+'_'+str(seq_size_threshold)+'.eps'))
        savefig(('seq_stream_com_size'+'_'+str(seq_size_threshold)+'.png'))
        
        x1=figure()
        ax1=x1.add_subplot(1,1,1)
        #hold('on')
        k=0
        ax1.plot(queue_len_setting,stream_count_write_only[k,0:num_queue_setting],plot_flags[0],label='write')
        ax1.plot(queue_len_setting,stream_count_read_only[k,0:num_queue_setting],plot_flags[1],label='read')
        ax1.plot(queue_len_setting,stream_count_all[k,0:num_queue_setting],plot_flags[2],label='combined')
        ax1.set_xlabel('queue length')
        ax1.set_ylabel('number of streams')
        #legend('write','read','combined')
        handles, labels = ax1.get_legend_handles_labels()
        ax1.legend(handles, labels)     
        ax1.set_title(t_str+' stream detection (frequency)')
        
        
        x2=figure()
        ax2=x2.add_subplot(1,1,1)
        #hold('on')
        k=0
        ax2.plot(queue_len_setting,stream_count_write_only_limited[k,0:num_queue_setting],plot_flags[0],label='write')
        ax2.plot(queue_len_setting,stream_count_read_only_limited[k,0:num_queue_setting],plot_flags[1],label='read')
        ax2.plot(queue_len_setting,stream_count_all_limited[k,0:num_queue_setting],plot_flags[2],label='combined')
        ax2.set_xlabel('queue length')
        ax2.set_ylabel('number of streams')
        #legend('write','read','combined')
        handles, labels = ax2.get_legend_handles_labels()
        ax2.legend(handles, labels)     
        ax2.set_title(t_str+' stream detection with size constraint (frequency)')
    
     
        x3=figure()
        ax3=x3.add_subplot(1,1,1)
        #hold('on')
        k=0
        ax3.plot(queue_len_setting,cmd_count_write_only[k,0:num_queue_setting],plot_flags[0],label='write')
        ax3.plot(queue_len_setting,cmd_count_read_only[k,0:num_queue_setting],plot_flags[1],label='read')
        ax3.plot(queue_len_setting,cmd_count_all[k,0:num_queue_setting],plot_flags[2],label='combined')
        ax3.set_xlabel('queue length')
        ax3.set_ylabel('number of streams')
        #legend('write','read','combined')
        handles, labels = ax3.get_legend_handles_labels()
        ax3.legend(handles, labels)     
        ax3.set_title(t_str+' command detection (frequency)')
        
        x4=figure()
        ax4=x4.add_subplot(1,1,1)
        #hold('on')
        k=0
        ax4.plot(queue_len_setting,cmd_count_write_only_limited[k,0:num_queue_setting],plot_flags[0],label='write')
        ax4.plot(queue_len_setting,cmd_count_read_only_limited[k,0:num_queue_setting],plot_flags[1],label='read')
        ax4.plot(queue_len_setting,cmd_count_all_limited[k,0:num_queue_setting],plot_flags[2],label='combined')
        ax4.set_xlabel('queue length')
        ax4.set_ylabel('number of streams')
        #legend('write','read','combined')
        handles, labels = ax4.get_legend_handles_labels()
        ax4.legend(handles, labels) 
        ax4.set_title(t_str+' command detection with size constraint (frequency)')
    
        x5=figure()
        ax5=x5.add_subplot(1,1,1)
        #hold('on')
        k=0
#        ax5.plot(queue_len_setting,ratio_stream_count_write_only[k,0:num_queue_setting],plot_flags[0],label='write')
#        ax5.plot(queue_len_setting,ratio_stream_count_read_only[k,0:num_queue_setting],plot_flags[1],label='read')
#        ax5.plot(queue_len_setting,ratio_stream_count_all[k,0:num_queue_setting],plot_flags[2],label='combined')
        ax5.plot(queue_len_setting,stream_count_write_only[k,0:num_queue_setting]/n_write,plot_flags[0],label='write')
        ax5.plot(queue_len_setting,stream_count_read_only[k,0:num_queue_setting]/n_read,plot_flags[1],label='read')
        ax5.plot(queue_len_setting,stream_count_all[k,0:num_queue_setting]/n_total,plot_flags[2],label='combined')        
        ax5.set_xlabel('queue length')
        ax5.set_ylabel('number of streams')
        #legend('write','read','combined')
        handles, labels = ax5.get_legend_handles_labels()
        ax5.legend(handles, labels)    
        ax5.set_title((t_str+' stream detection with size constraint (ratio)'))
    
        x6=figure()
        ax6=x6.add_subplot(1,1,1)
        #hold('on')
        k=0
#        ax6.plot(queue_len_setting,ratio_cmd_count_write_only[k,0:num_queue_setting],plot_flags[0],label='write')
#        ax6.plot(queue_len_setting,ratio_cmd_count_read_only[k,0:num_queue_setting],plot_flags[1],label='read')
#        ax6.plot(queue_len_setting,ratio_cmd_count_all[k,0:num_queue_setting],plot_flags[2],label='combined')
        ax6.plot(queue_len_setting,cmd_count_write_only[k,0:num_queue_setting]/n_write,plot_flags[0],label='write')
        ax6.plot(queue_len_setting,cmd_count_read_only[k,0:num_queue_setting]/n_read,plot_flags[1],label='read')
        ax6.plot(queue_len_setting,cmd_count_all[k,0:num_queue_setting]/n_total,plot_flags[2],label='combined')        
        ax6.set_xlabel('queue length')
        ax6.set_ylabel('number of streams')
        #legend('write','read','combined')
        if near_sequence == 1:
            ax6.set_title('Near sequential command detection (ratio)')
            # set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
            change_fontsize(ax6,plot_fontsize)
            handles, labels = ax6.get_legend_handles_labels()
            ax6.legend(handles, labels)        
            savefig('near_seq_cmd_ratio.eps')
            savefig('near_seq_cmd_ratio.png')
        else:
            ax6.set_title('Sequential command detection (ratio)')
            #set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
            change_fontsize(ax6,plot_fontsize)
            handles, labels = ax6.get_legend_handles_labels()
            ax6.legend(handles, labels)        
            savefig('seq_cmd_ratio.eps.eps')
            savefig('seq_cmd_ratio.png')       
      
    
        x7=figure()
        ax7=x7.add_subplot(1,1,1)
        #hold('on')
        k=0
#        ax7.plot(queue_len_setting,ratio_cmd_count_write_only_limited[k,0:num_queue_setting],plot_flags[0],label='write')
#        ax7.plot(queue_len_setting,ratio_cmd_count_read_only_limited[k,0:num_queue_setting],plot_flags[1],label='read')
#        ax7.plot(queue_len_setting,ratio_cmd_count_all_limited[k,0:num_queue_setting],plot_flags[2],label='combined')
        ax7.plot(queue_len_setting,cmd_count_write_only_limited[k,0:num_queue_setting]/n_write,plot_flags[0],label='write')
        ax7.plot(queue_len_setting,cmd_count_read_only_limited[k,0:num_queue_setting]/n_read,plot_flags[1],label='read')
        ax7.plot(queue_len_setting,cmd_count_all_limited[k,0:num_queue_setting]/n_total,plot_flags[2],label='combined')        
        ax7.set_xlabel('queue length')
        ax7.set_ylabel('number of streams')
        #legend('write','read','combined')
        if near_sequence == 1:
            ax7.set_title('Near sequential command detection with constraint (ratio)')
            # set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
            handles, labels = ax7.get_legend_handles_labels()
            ax7.legend(handles, labels)
            change_fontsize(ax7,plot_fontsize)
            savefig('near_seq_cmd_ratio_size'+'_'+str(seq_size_threshold)+'.eps')
            savefig(('near_seq_cmd_ratio_size'+'_'+str(seq_size_threshold)+'.png'))
        else:
            ax7.set_title(('Sequential command detection with constaint (ratio)'))
            #set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
            change_fontsize(ax7,plot_fontsize)
            handles, labels = ax7.get_legend_handles_labels()
            ax7.legend(handles, labels)
            savefig(('seq_cmd_ratio_size'+'_'+str(seq_size_threshold)+'.eps'))
            savefig(('seq_cmd_ratio_size'+'_'+str(seq_size_threshold)+'.png'))     
           
    
          
        x8=figure()
        ax8=x8.add_subplot(1,1,1)
        #hold('on')
        ax8.plot(queue_len_setting,average_seq_cmd_size_write_only[k,0:num_queue_setting],plot_flags[0],label='write')
        ax8.plot(queue_len_setting,average_seq_cmd_size_read_only[k,0:num_queue_setting],plot_flags[1],label='read')
        ax8.plot(queue_len_setting,average_seq_cmd_size_all[k,0:num_queue_setting],plot_flags[2],label='combined')
        ax8.set_xlabel('queue length')
        ax8.set_ylabel('average size (blocks)')
        handles, labels = ax8.get_legend_handles_labels()
        ax8.legend(handles, labels)    #legend('write','read','combined')
        ax8.set_title('Sequential command (average size)')
    
    
    
        x9=figure()
        ax9=x9.add_subplot(1,1,1)
        #hold('on')
        ax9.plot(queue_len_setting,average_seq_cmd_size_write_only_limited[k,0:num_queue_setting],plot_flags[0],label='write')
        ax9.plot(queue_len_setting,average_seq_cmd_size_read_only_limited[k,0:num_queue_setting],plot_flags[1],label='read')
        ax9.plot(queue_len_setting,average_seq_cmd_size_all_limited[k,0:num_queue_setting],plot_flags[2],label='combined')
        ax9.set_xlabel('queue length')
        ax9.set_ylabel('average size (blocks)')
        #legend('write','read','combined')
        handles, labels = ax9.get_legend_handles_labels()
        ax9.legend(handles, labels)
        ax9.set_title('Sequential command with size constraint (average size)')
      
        x10=figure()
        ax10=x10.add_subplot(1,1,1)
        #hold('on')
        ax10.plot(queue_len_setting,average_seq_stream_size_write_only_limited[k,0:num_queue_setting],plot_flags[0],label='write')
        ax10.plot(queue_len_setting,average_seq_stream_size_read_only_limited[k,0:num_queue_setting],plot_flags[1],label='read')
        ax10.plot(queue_len_setting,average_seq_stream_size_all_limited[k,0:num_queue_setting],plot_flags[2],label='combined')
        ax10.set_xlabel('queue length')
        ax10.set_ylabel('average size (blocks)')
        #legend('write','read','combined')
        handles, labels = ax10.get_legend_handles_labels()
        ax10.legend(handles, labels)
        ax10.set_title('Sequential Stream with size constraint (average size)')

    return sequence_stat

        #     hold on;
    #     plot(queue_len_setting,average_seq_cmd_size_write_only_s(k,1:num_queue_setting), plot_flags{1});
    #     plot(queue_len_setting,average_seq_cmd_size_read_only_s(k,1:num_queue_setting), plot_flags{2});
    #     plot(queue_len_setting,average_seq_cmd_size_all_s(k,1:num_queue_setting), plot_flags{3});
    #     xlabel('queue length');
    #     ylabel('average size (blocks)');
    #     legend('write','read','combined');
    #     title(['Sequential command (average size)']);
        #     figure;
    #     hold on;
    #     plot(queue_len_setting,average_seq_cmd_size_write_only_s2(k,1:num_queue_setting), plot_flags{1});
    #     plot(queue_len_setting,average_seq_cmd_size_read_only_s2(k,1:num_queue_setting), plot_flags{2});
    #     plot(queue_len_setting,average_seq_cmd_size_all_s2(k,1:num_queue_setting), plot_flags{3});
    #     xlabel('queue length');
    #     ylabel('average size (blocks)');
    #     legend('write','read','combined');
    #     title(['Sequential command (average size)']);
    
#    if options.export_report:
#        options.section_name = copy(cat(options.section_name,char(10),'seq_size_threshold=',int2str(max_stream_length)))
#        generate_ppt(options)
#        string0=string_generate(cat([queue_len_setting],[ratio_cmd_count_write_only[1,1:num_queue_setting]]).T,size(queue_len_setting,2))
#        string0=matlabarray(cat('without size constraint (cmd): write=',string0))
#        saveppt2(options.report_name,'f',0,'t',string0)
#        string0=string_generate(cat([queue_len_setting],[ratio_cmd_count_read_only[1,1:num_queue_setting]]).T,size(queue_len_setting,2))
#        string0=matlabarray(cat('without size constraint (cmd): read=',string0))
#        saveppt2(options.report_name,'f',0,'t',string0)
#        string0=string_generate(cat([queue_len_setting],[ratio_cmd_count_write_only_limited[1,1:num_queue_setting]]).T,size(queue_len_setting,2))
#        string0=matlabarray(cat('without size constraint (cmd): write=',string0))
#        saveppt2(options.report_name,'f',0,'t',string0)
#        string0=string_generate(cat([queue_len_setting],[ratio_cmd_count_read_only_limited[1,1:num_queue_setting]]).T,size(queue_len_setting,2))
#        string0=matlabarray(cat('without size constraint (cmd): read=',string0))
#        saveppt2(options.report_name,'f',0,'t',string0)
    