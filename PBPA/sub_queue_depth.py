from numpy import zeros, nonzero, shape, arange, transpose,ceil,c_, array,add,logical_and,dot,copy
from matplotlib.pylab import plot, xlabel, ylabel, title, legend, figure, hold, savefig, grid 
# from statistics import mode
from scipy.stats import mode 
from scipy import mean, median,std

class queue_record_class:
     def __init__(self,queue_length_c,queue_length,queue_length_ave2):
         self.queue_length_c=copy(queue_length_c)
         self.queue_length=copy(queue_length)
         self.queue_length_ave2=queue_length_ave2

    
def sub_queue_depth(lists_action=None,lists_cmd=None,options=None,*args,**kwargs):
    '''
 [queue_length_c, queue_length]=sub_queue_depth(lists_action,lists_cmd,options)
 --> average queue depth for completion and arrival
 
 inputs
   lists_action: n samples x 2 array for arrival time and completion time; 
   lists_cmd: n samples x 3 for LBA, size, flags
   options: control parameters
       plot_fontsize: the figure's font size
       time_interval: the time interval for moving average windows
       plot_figure: >=1: plot the figure; otherwise not
       save_figure: >=1: save the figures
       export_report: >=1: export the figure/data into a ppt
       report_name: report name
 outputs
   queue_record: structure for queue    
      queue_length_c: queue_length for completion
      queue_length: queue_lenght for arrival 
      queue_length_ave2: average queue length (arrival) based on given time interval
 contact jun.xu99@gmail.com for questions
    '''
    
    if hasattr(options,'plot_fontsize'):
        plot_fontsize=options.plot_fontsize
    else:
        plot_fontsize=10
    
    if hasattr(options,'time_interval'):
        time_interval=options.time_interval
    else:
        time_interval=50
    
    if hasattr(options,'save_figure'):
        save_figure=options.save_figure
    else:
        save_figure=1
    
    if hasattr(options,'plot_figure'):
        plot_figure=options.plot_figure
    else:
        plot_figure=1
        
    a=shape(lists_action)[0]
    max_time=lists_action[a-1,0]
    ## method 1: based on the a queue
    if a > 1024:
        max_queue_length=1024*4
    else:
        max_queue_length=512
    
    queue_length_c=zeros((a,2))
    queue_length=zeros((a,2))
    
    
    for i in arange(1,a):
    
        idx_queue=nonzero(logical_and((lists_action[:,0] < lists_action[i,1]),(lists_action[:,1] > lists_action[i,1])))
    
        x=shape(idx_queue)[1]    
        queue_length_c[i,:]=[lists_action[i,0],x]
    
    if plot_figure == 1:
        figure()
        plot(queue_length_c[:,0],queue_length_c[:,1],marker='*',markersize=0.5)
        xlabel('time')
        ylabel('depth')
        title(('Estimated Device Queue Depth (completed); ave='+str(mean(queue_length_c[:,1]))))
        #set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        savefig('est_dev_queue_length_com.eps')
        savefig('est_dev_queue_length_com.png')
        savefig('est_dev_queue_length_com.jpg')       
    xi=0
    # we shall sort lists_action based on lists_action[:,0], increasing order
    for i in arange(1,a).reshape(-1):
        idx_queue=nonzero(lists_action[0:i,1] > lists_action[i,0])  
        #idx_queue=nonzero(logical_and((lists_action[:,0] < lists_action[i,0]) , (lists_action[:,1] > lists_action[i,0])))
        x=shape(idx_queue)[1]
        queue_length[i,:]=[lists_action[i,0],x]
    
    if plot_figure == 1:
        figure()
        plot(queue_length[:,0],queue_length[:,1],marker='*',markersize=0.5)
        xlabel('time')
        ylabel('depth')
        title(('Estimated Device Queue Depth (arrival); ave='+str(mean(queue_length[:,1]))))
        savefig('est_dev_queue_length_arr.eps')
        savefig('est_dev_queue_length_arr.png')
        savefig('est_dev_queue_length_arr.jpg')        
        #set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
    
    max_num=int(ceil(max_time / time_interval))
    queue_length_ave=zeros((max_num + 5,2))
    queue_length_ave2=zeros((max_num,2))
    for i in arange(0,max_num).reshape(-1):
        cur_time=dot((i - 1),time_interval)
        end_time=dot(i,time_interval)
        idx=nonzero(logical_and((queue_length[:,0] > cur_time),(queue_length[:,0] <= end_time)))
        dq=0
        if shape(idx)[1]>1:            
            for j0 in arange(shape(idx)[1]):
                j=idx[0][j0]
                if j== 0:
                    dq=dot((queue_length[j,0]),queue_length[j,1])
                else:
                    dq=dq + dot((queue_length[j,0] - queue_length[j - 1,0]),queue_length[j,1])                
            queue_length_ave2[i,:]=[end_time,dq /(queue_length[idx[0][-1],0] - queue_length[idx[0][0],0]) ]
        elif shape(idx)[1]>0:
            queue_length_ave2[i,:]=[end_time,queue_length[idx[0][0],1]]
        else:
            queue_length_ave2[i,:]=[end_time,0]
    
    if plot_figure == 1:
        figure()
        plot(queue_length_ave2[1:max_num,0],queue_length_ave2[1:max_num,1])
        xlabel('time (s)')
        ylabel('depth')
        # the avearge value may be different from previous one, as this one is
        # time weighted. a more precise way shall consider the head and tail
        title(('Estimated Average Device Queue Depth (time weighted) = '+str(mean(queue_length_ave2[1:max_num,1]))+' @'+str(time_interval)+'seconds interval'))
        #set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        savefig('est_dev_queue_depth.eps')
        savefig('est_dev_queue_depth.png')
        savefig('est_dev_queue_depth.jpg')  
        
    queue_record=queue_record_class(queue_length_c,queue_length,queue_length_ave2)
    if options!=None:
        options.section_name = 'Queue Depth'
    
    return queue_record
    
    
    # generate_ppt(options)
    #     cur_time=0;
#     cur_idx=1;
#     interval_idx=0;
#     for i=1:con0
#         if lists_action(i,7)>cur_time+time_interval
#             act_time_interval=lists_action(i,7)-lists_action(cur_idx,7);
#             interval_idx=interval_idx+1;
#             queue_length_ave(interval_idx,:)=[lists_action(i,6),sum(queue_length(cur_idx:i,2))/(i-cur_idx+1)];
#             #queue_length_ave(interval_idx,:)=[lists_action(i,6),sum(queue_length(cur_idx:i,2))/time_interval];
#             cur_idx=i;
#             cur_time=lists_action(i,7);
#         else
    
    #         end
#     end
    
    #     figure;
#     plot(queue_length_ave(1:interval_idx,1),queue_length_ave(1:interval_idx,2));
#     xlabel('time (s)');
#     ylabel('depth');
#     title(['Estimated Average Device Queue Depth @', num2str(time_interval), 'seconds interval'])



#a1=a - max_queue_length
#for i in arange(1,a):
#    if i <= max_queue_length:
#        idx_tmp=1
#        idx_back=i - 1 + max_queue_length
#    else:
#        if i >= a1:
#            idx_tmp=i - max_queue_length
#            idx_back=a
#        else:
#            idx_tmp=i - max_queue_length
#            idx_back=i - 1 + max_queue_length
#            # the current --> in the queue
#    idx_queue=nonzero(logical_and((lists_action[idx_tmp:idx_back,0] <= lists_action[i,1]),(lists_action[idx_tmp:idx_back,1] > lists_action[i,1])))
#    idx_queue=nonzero(logical_and((lists_action[:,0] < lists_action[i,1]),(lists_action[:,1] > lists_action[i,1])))
    #queue_length_c[i,:]=[lists_action[i,1],len(idx_queue)]
    #idx_queue=nonzero(logical_and((lists_action[idx_tmp-1:idx_back-1,0] <= lists_action[i-1,1]), (lists_action[idx_tmp-1:idx_back-1,1] > lists_action[i-1,1])))