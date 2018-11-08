from matplotlib.pylab import plot, xlabel, ylabel, title, legend, figure, hold, savefig, grid, subplot 
from numpy import zeros, nonzero, shape, arange, transpose, dot, uint8, uint16, uint32, c_,sum,squeeze, ceil,logical_and,add,copy,mod,mean,array
from stack_distance import stack_distance

class stack_wow_record_class:
    def __init__(self,stack_dist_record_partial=None,stack_dist_record_full=None,size_dist=None,lba_dist=None,cdf_record_partial=None,cdf_record_full=None):
        self.stack_dist_record_partial = (stack_dist_record_partial)
        self.stack_dist_record_full = (stack_dist_record_full)
        self.size_dist = (size_dist)
        self.lba_dist = (lba_dist)
        self.cdf_record_partial=cdf_record_partial
        self.cdf_record_full=cdf_record_full

def sub_stack_wow(lists_cmd=None,options=None):
    '''
 stack_wow_record=sub_stack_wow(lists_cmd,options)
 stack distance analysis - WOW
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
       spec_stack=[10,20,30];  # a vector specify the stack distance, for which we can collect the statistical value and output to the ppt file. for very large dataset ; otherwise specify some small numbers
 outputs
   stack_wow_record: structure for statistics of statcked WOW
       stack_dist_record_partial;  1/2 partial hit frequency and
       overlapped size;  index shows the stack distance
       stack_dist_record_full:  1/2: full hit frequency & overlapped request size;
       size_dist: 1: full; 2: partial
       lba_dist:   LBA distribution, 1: full, 2: partial, 3: lba range
       cdf_record_full:  # 1: stack distance, 2: full hit frequency cdf,
       3: full hit size/blocks cdf
       cdf_record_partial:  # 1: stack distance, 2: partial hit frequency
       cdf, 3: partial hit size/blocks cdf
 contact jun.xu99@gmail.com for questions
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
    
    # write on write
    
    stack_dist_record_partial,stack_dist_record_full,size_dist,lba_dist=stack_distance(lists_cmd,0)
    
    min_max_stack=min(shape(stack_dist_record_partial)[0],shape(stack_dist_record_full)[0])
    
    if hasattr(options,'spec_stack'):
        spec_stack=options.spec_stack
    else:
        if min_max_stack > 30:
            spec_stack=[10,20,30]
        else:
            if min_max_stack > 20:
                spec_stack=[5,10,15]
            else:
                if min_max_stack > 10:
                    spec_stack=[2,4,8]
                else:
                    if min_max_stack > 5:
                        spec_stack=[1,3,5]
                    else:
                        spec_stack=1
                        print('stack is too short to be meaningful')
    
    
    
    step1=1
    stack_wow_record=stack_wow_record_class(stack_dist_record_partial,stack_dist_record_full,size_dist,lba_dist)
    
    
    if plot_figure == 1:
        stack_wow_hit_record=zeros((shape(spec_stack)[0],4))
        f2=figure()
        (ax1)=f2.add_subplot(211)
        idx_nonzero=nonzero(stack_dist_record_partial[:,1] > 0)
        ax1.plot(idx_nonzero,stack_dist_record_partial[idx_nonzero,0],'r*',markersize=1.5)
        total_partial_hit=sum(stack_dist_record_partial[idx_nonzero,0])
        total_partial_size=sum(stack_dist_record_partial[idx_nonzero,1])
        average_partial_size=total_partial_size / total_partial_hit
        ax1.set_xlabel('Stack distance ')
        ax1.set_ylabel('Frequency')
        ax1.set_title(('Write only: total partial hit = '+str(total_partial_hit)+'; average overlap size = '+str(average_partial_size)+' blocks'))
           
        
        if (shape(stack_dist_record_partial)[1]>0):
            for kk0 in arange(0,shape(spec_stack)[0]).reshape(-1):
                stack_wow_hit_record[kk0,0]=sum(stack_dist_record_partial[1:spec_stack[kk0],0])
                stack_wow_hit_record[kk0,1]=mean(stack_dist_record_partial[1:spec_stack[kk0],1])
                
        steps1=int(idx_nonzero[0][-1] / step1 + 1)
        cdf_record=zeros((steps1,3))
        cdf_record[1:steps1,0]=dot((arange(1,steps1 )),step1)
        for i in arange(1,steps1 - 1).reshape(-1):
            cdf_record[i,1]=cdf_record[i - 1,1] + sum(stack_dist_record_partial[dot((i - 1),step1) :dot((i ),step1),0])
            cdf_record[i,2]=cdf_record[i - 1,2] + sum(stack_dist_record_partial[dot((i - 1),step1) :dot((i ),step1),1])
        cdf_record[steps1-1,1]=cdf_record[i - 1,1] + sum(stack_dist_record_partial[dot((steps1 - 1),step1) :idx_nonzero[0][-1],0])
        cdf_record[steps1-1,2]=cdf_record[i - 1,2] + sum(stack_dist_record_partial[dot((steps1 - 1),step1) :idx_nonzero[0][-1],1])
        
        idx_part=idx_nonzero[0][-1];
        stack_wow_record.cdf_record_partial = copy(cdf_record)       
        
        (ax2)=f2.add_subplot(212)
        idx_nonzero=nonzero(stack_dist_record_full[:,1] > 0)
        ax2.plot(idx_nonzero,stack_dist_record_full[idx_nonzero,1],'r*',markersize=1.5)
        total_full_hit=sum(stack_dist_record_full[idx_nonzero,0])
        total_full_size=sum(stack_dist_record_full[idx_nonzero,1])
        average_full_size=total_full_size / total_full_hit
        ax2.set_xlabel('Stack distance ')
        ax2.set_ylabel('Frequency')
        ax2.set_title(('Write only: total full hit = '+str(total_full_hit)+'; average overlap size = '+str(average_full_size)+' blocks'))
        
        
        if (shape(stack_dist_record_full)[1]>0):
            for kk0 in arange(1,shape(spec_stack)[0]).reshape(-1):
                stack_wow_hit_record[kk0,2]=sum(stack_dist_record_full[1:spec_stack[kk0],0])
                stack_wow_hit_record[kk0,3]=mean(stack_dist_record_full[1:spec_stack[kk0],1])
        savefig('stack_dist_write.eps')
        savefig('stack_dist_write.png')
        
        
        steps1=int(ceil(idx_nonzero[0][-1] / step1) + 1)
        cdf_record=zeros((steps1,3))
        cdf_record[1:steps1,0]=dot((arange(1,steps1 )),step1)
        for i in arange(1,steps1 - 1).reshape(-1):
            cdf_record[i,1]=cdf_record[i - 1,1] + sum(stack_dist_record_full[dot((i - 1),step1) :dot((i ),step1),0])
            cdf_record[i,2]=cdf_record[i - 1,2] + sum(stack_dist_record_full[dot((i - 1),step1) :dot((i ),step1),1])
        cdf_record[steps1-1,1]=cdf_record[i - 1,1] + sum(stack_dist_record_full[dot((steps1 - 1),step1) :idx_nonzero[0][-1],0])
        cdf_record[steps1-1,2]=cdf_record[i - 1,2] + sum(stack_dist_record_full[dot((steps1 - 1),step1) :idx_nonzero[0][-1],1])
        
    
        f_cdf=figure()
        ax3 = f_cdf.add_subplot(111)
        ax3.plot(stack_wow_record.cdf_record_partial[:,0],stack_wow_record.cdf_record_partial[:,1] / total_partial_hit,'r-.')
        #figure(f_cdf)
        ax3.plot(cdf_record[:,0],cdf_record[:,1] / total_full_hit,'b-')
        ax3.set_xlabel('Stack distance ')
        ax3.set_ylabel('CDF')
        ax3.set_title('Write Hit CDF')
        ax3.legend(['Partial','Full'])
        #set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        savefig('stacked_update1.eps')
        savefig('stacked_update1.png')
        
        f_cdf_size=figure()
        ax4 = f_cdf_size.add_subplot(111)
        ax4.plot(stack_wow_record.cdf_record_partial[:,0],stack_wow_record.cdf_record_partial[:,2] /total_partial_size,'r-.')    
         #figure(f_cdf_size)
        ax4.plot(cdf_record[:,0],cdf_record[:,2] /total_full_size,'b-')
        ax4.set_xlabel('Stack distance ')
        ax4.set_ylabel('CDF')
        ax4.set_title('Write Size CDF')
        ax4.legend(['Partial','Full'])
        #set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        savefig('stacked_update2.eps')
        savefig('stacked_update2.png')
                
        stack_wow_record.cdf_record_full = copy(cdf_record)
        
        
        f1=figure()
    #        size_dist_idx=find(size_dist == 0)
        size_dist_plot=copy(size_dist)
    #        size_dist_plot[size_dist_idx]=NaN
        (ax1)=f1.add_subplot(211)
        #hold('on')
        idx_non0=nonzero(size_dist_plot[:,1]!=0)
        ax1.plot(idx_non0,size_dist_plot[idx_non0,1],'b*')
        ax1.set_xlabel('Block size ')
        ax1.set_ylabel('Partial Frequency')
        ax1.set_title('Write Partial Hit Distribution (size)')
        
        # subplot(2,1,2)
        (ax2)=f1.add_subplot(212)
        idx_non0=nonzero(size_dist_plot[:,0]!=0)
        ax2.plot(idx_non0,size_dist_plot[idx_non0,0],'r^')
        ax2.set_xlabel('Block size ')
        ax2.set_ylabel('Full Frequency')
        ax2.set_title('Write Full Hit Distribution (size)')
        # legend('Partial', 'Full')
        #set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        savefig('WU_size_dist.eps')
        savefig('WU_size_dist.png')  
        
        # not plotted.
        idx=nonzero(lba_dist[:,1] > 0)
        idx_l=idx[0]
        idx_r=idx[-1]
        idx_part=c_[idx_l,idx_r]
        
        idx=nonzero(lba_dist[:,0] > 0)
        idx_l=idx[0]
        idx_r=idx[-1]
        idx_full=c_[idx_l,idx_r]
        
        lba_dist_idx=nonzero(lba_dist == 0)
        lba_dist_plot=copy(lba_dist)
        #lba_dist_plot[lba_dist_idx]=NaN
        
        f3=figure()
        #hold('on')
        (ax1)=f3.add_subplot(211)
        ax1.plot(lba_dist[idx_part,2],lba_dist_plot[idx_part,1],'b*')
        ax1.set_xlabel('LBA range ')
        ax1.set_ylabel('Partial Frequency ')
        ax1.set_title('Write Partial Hit Distribution (LBA)')
        #subplot(2,1,2)
        (ax2)=f3.add_subplot(212)
        ax2.plot(lba_dist[idx_full,2],lba_dist_plot[idx_full,0],'r^')
        ax2.set_xlabel('LBA range ')
        ax2.set_ylabel('Full Frequency')
        ax2.set_title('Write Full Hit Distribution (LBA)')
        #set(findall(gcf,'-property','FontSize'),'FontSize',plot_fontsize)
        savefig('WU_LBA_dist.eps')
        savefig('WU_LBA_dist.png')
    
    return stack_wow_record
    

    