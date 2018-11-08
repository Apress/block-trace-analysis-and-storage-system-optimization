from numpy import zeros, nonzero, shape, arange, transpose, argsort, max, floor,logical_and,dot,c_,sum
from matplotlib.pylab import plot, xlabel, ylabel, title, legend, figure, hold, savefig, grid 
# from statistics import mode
from scipy.stats import mode 
from scipy import mean, median,std
# sub_idle_queue.m

class idle_queue_record_class:
    def __init__(self,queue_length=None,idle_time_array=None,total_idle_time=None,idle_time_array2=None, idle_time_cdf=None):
     self.queue_length=queue_length
     self.idle_time_array=idle_time_array
     self.total_idle_time=total_idle_time
     self.idle_time_array2=idle_time_array2
     self.idle_time_cdf=idle_time_cdf
     
def sub_idle_queue(lists_action=None,options=None):
    '''
    # sub_idle_queue(lists_action,options)
# calcuate the queue length and idle time
    
# inputs
#       lists_action: n samples x 2 array for arrival time and completion time;
#       options: control parameters
#          plot_fontsize: the figure's font size
#          time_interval: the time interval for moving average windows
#          plot_figure: >=1: plot the figure; otherwise not; default 1
#          save_figure: >=1: save the figures
#          export_report: >=1: export the figure/data into a ppt
#          report_name: report name
#          output_foldername: the output folder name for figures and report; default =''
#          offset_time:  some trace is not started from zone. in this case. need to find the starting time of first event.
# outputs
#   idle_queue_record: structure for statistics of idle time
# Author: jun.xu99@gmail.com
    '''
    
    if hasattr(options,'plot_fontsize'):
        plot_fontsize=options.plot_fontsize
    else:
        plot_fontsize=10
    
    if hasattr(options,'save_figure'):
        save_figure=options.save_figure
    else:
        save_figure=1
    
    if hasattr(options,'plot_figure'):
        plot_figure=options.plot_figure
    else:
        plot_figure=1
    
    if hasattr(options,'idle_threshold'):
        idle_threshold=options.idle_threshold
    else:
        idle_threshold=0.1
    
    ## reorder the completion time to find whether the sequence is matched compared with arrival time
    idx0=argsort(lists_action[:,1])
    trace0=lists_action[idx0,:]
    a=shape(lists_action)[0]
    queue_length0=(arange(0,a)).T - idx0
    idle_queue_record=idle_queue_record_class(queue_length = queue_length0)
     
    ## calcuate the idle time
#    idx=nonzero(queue_length0 == 0)
#    a1=shape(idx)[1]
    idle_time_array=zeros((a,3))
    idle_time_array2=zeros((a,2))
    con0=-1
    n_end=1
    
    for i in arange(1,a).reshape(-1):
    # two cases when zero: there is no event at the queue (expected), and
    # there are some events but this request is executed first due to RPO.
        #id0=nonzero(lists_action[endid:i ,1] >= lists_action[i,1])
        id0=nonzero(lists_action[0:i,1] > lists_action[i,0])  
        if shape(id0)[1]==0:  # only if the queue is zero, it mean the current request may have idle time between some earlier request            
            comp_time_max=max(lists_action[0:i,1])
            it0=lists_action[i,0] - comp_time_max
            if it0 > 0:
                con0=con0 + 1
                idle_time_array[con0,0]=lists_action[i,0] # ending time of idle
                idle_time_array[con0,2]=comp_time_max # starting time of idle
                idle_time_array[con0,1]=it0
                idle_time_array2[i,1]=it0
        idle_time_array2[i,0]=lists_action[i - 1,1]
    
    idle_time_array=idle_time_array[0:con0+1,:]
    total_idle_time=sum(idle_time_array[:,1])
    idle_queue_record.idle_time_array = (idle_time_array)
    idle_queue_record.total_idle_time = (total_idle_time)
    idle_queue_record.idle_time_array2 = (idle_time_array2)
    
    max_idle=max(idle_time_array[:,1])
    idle_time_interval=floor(arange(0,dot(max_idle,1000) + 10,5)) / 1000                           
    a2=shape(idle_time_interval)[0]
    
    idle_time_set=zeros((a2,3))
    for i in arange(0,a2 - 1).reshape(-1):
        # idx=nonzero((idle_time_array[:,1] <= (idle_time_interval[i + 1]) and (idle_time_array[:,1]) > idle_time_interval[i]))
        idx=nonzero(logical_and(idle_time_array[:,1] <= idle_time_interval[i + 1], idle_time_array[:,1] > idle_time_interval[i]))
        idle_time_set[i + 1,:]=c_[idle_time_interval[i + 1],shape(idx)[1], sum(idle_time_array[idx,1])]
        
    idle_time_cdf=idle_time_set.copy()
    for i in arange(1,a2).reshape(-1):
        idle_time_cdf[i,1:3]=idle_time_cdf[i - 1,1:3] + idle_time_cdf[i,1:3]
    idle_time_cdf[:,1]=idle_time_cdf[:,1] / con0
    idle_time_cdf[:,2]=idle_time_cdf[:,2] / total_idle_time
    idle_queue_record.idle_time_cdf = idle_time_cdf   
    
    if plot_figure == 1:
        figure()
        plot(lists_action[:,0],(queue_length0),marker='*',markersize=1)
        xlabel('time')
        ylabel('queue age')
        title('Estimated Device Queue Age')
        savefig('est_dev_queue_age.eps')
        savefig('est_dev_queue_age.png')
        savefig('est_dev_queue_age.jpg')
        figure()
        plot(idle_time_array[:,0],idle_time_array[:,1],marker='*',markersize=0.5)
        xlabel('time')
        ylabel('idle time length')
        title('Estimated Device Idle Time')
        savefig('est_dev_idle_time.eps')
        savefig('est_dev_idle_time.png')
        savefig('est_dev_idle_time.jpg')
        
        idle_time_array_cdf=idle_time_array.copy()
        for i in arange(1,con0).reshape(-1):
            idle_time_array_cdf[i,1]=idle_time_array_cdf[i,1] + idle_time_array_cdf[i - 1,1]
            
        fig0=figure()
        plot(idle_time_array_cdf[:,0],idle_time_array_cdf[:,1],marker='*',markersize=0.5)
        xlabel('time')
        ylabel('total idle time length')
        title('Accumulated Estimated Device Idle Time')
        savefig('est_dev_acc_idle_time.eps')
        savefig('est_dev_acc_idle_time.png')
        savefig('est_dev_acc_idle_time.jpg')
        #idle_time_interval=[0:5:500]/1000;       
        
        
        fig1=figure()
        plot(idle_time_cdf[:,0],idle_time_cdf[:,1],'-')
        xlabel('idle time length (s)')
        ylabel('CDF')
        title('CDF of Estimated Device Idle Frequency')
        savefig('est_dev_cdf_idle_time_f.eps')
        savefig('est_dev_cdf_idle_time_f.png')
        savefig('est_dev_cdf_idle_time_f.jpg')
    #     plot(idle_time_cdf(:,1),idle_time_cdf(:,2),'-');
    #     axis([0 0.4 0 1])
    #     xlabel('idle time length (s)');
    #     ylabel('CDF');
    #     title('CDF of Estimated Device Idle Time (Frequency)');
        fig2=figure()
        plot(idle_time_cdf[:,0],idle_time_cdf[:,2],'-')
        xlabel('idle time length (s)')
        ylabel('CDF')
        title('CDF of Estimated Device Idle Time')
        savefig('est_dev_cdf_idle_time.eps')
        savefig('est_dev_cdf_idle_time.png')
        savefig('est_dev_cdf_idle_time.jpg')
    

#    if options.export_report:
#        options.section_name = copy('Idle Time')
#        generate_ppt(options)
   
    return idle_queue_record