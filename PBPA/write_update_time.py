from numpy import zeros, nonzero, shape, arange, transpose, dot, uint8, uint16, uint32, c_,sum,squeeze, max
# from matplotlib.pylab import plot, xlabel, ylabel, title, legend, figure, hold, savefig 
# from statistics import mode

# from scipy import mean, median,std
import psutil
    

class update_stat_class:
    def __init__(self,update_average_size=None,hit_ratio=None,write_cmd_ratio=None,idx_write_size=None,write_average_size=None,write_ratio=None,update_ratio=None,idx_size=None):
        self.update_average_size=update_average_size
        self.hit_ratio=hit_ratio
        self.write_cmd_ratio=write_cmd_ratio
        self.idx_write_size=idx_write_size
        self.write_average_size=write_average_size
        self.write_ratio=write_ratio
        self.update_ratio=update_ratio
        self.idx_size=idx_size;
        
                
def write_update_time(traces=None,access_type=None,options=None):
    '''
    # access_type: decide if only consider read 1/write 0 or combine 2
    '''
    
    total_cmd,b=shape(traces)
    idx_write=nonzero((traces[1:total_cmd,2] == 0))
    idx_write_size=shape(idx_write)[1]
    
    trace_write=squeeze(traces[transpose(idx_write),:])
    total_write_size=sum(trace_write[:,1])
    trace_write=c_[trace_write,zeros((idx_write_size,1),dtype='int64')]
    trace_write[:,3]=trace_write[:,0] + trace_write[:,1] - 1
    #min_lba=min(trace_write(:,1));
    max_lba=max(trace_write[:,3])+1
    #act_lba=max_lba-min_lba+1;
    
    # if isfield(options, 'freq_together')
    #     freq_together=options.freq_together;
    # else
    #     freq_together=0;
    # end
    
    systemview=psutil.virtual_memory()
    if systemview.available > dot((max_lba ),8):
        LBA_count=zeros((max_lba ,1))
    else:
        if systemview.available > dot((max_lba ),4):
            LBA_count=(zeros((max_lba ,1),dtype=uint32))
        else:
            if systemview.available > dot((max_lba ),2):
                LBA_count=(zeros((max_lba ,1),dtype=uint16))
            else:
                if systemview.available > (max_lba ):
                    LBA_count=(zeros((max_lba ,1),dtype=uint8))
                else:
                    # LBA_count=sparse(max_lba + 1024,1)
                    print('some issues with small memory size')
                    print ('the future version will use sparse matrix; due to different access mode of sparse matrix with the normal array, the sparse matrix is not implemented')
                    return -1
    # an alternative approach is to create the list dynamically 
    # or sort the LBA first, and then create the array for all the unique LBAs; however, the find access may be quite time consuming; any good function for sequenced list (bi-sect)?
    
    #LBA_count=(zeros(act_lba,1,'uint8'));
    # LBA_count=(zeros(max_lba+1,1,'uint8')); # need to count LBA 0;
    
    write_size=0    
    update_size=0    
    hit_count=0    
    write_count=0
    
    print('Starting the pre-procssing: find the access frequency of each LBA')
    
    if options.access_type == 0:
        write_ratio=zeros((idx_write_size,1))
        update_ratio=zeros((idx_write_size,1))
        hit_ratio=zeros((idx_write_size,1))
        write_cmd_ratio=zeros((idx_write_size,1))
        for cmd_id in arange(0,idx_write_size).reshape(-1):
            LBA_count[trace_write[cmd_id,0] :trace_write[cmd_id,3] + 1]=LBA_count[trace_write[cmd_id,0] :trace_write[cmd_id,3] + 1] + 1
            # times --> updated LBAs.
            idx_update=nonzero(LBA_count[trace_write[cmd_id,0] :trace_write[cmd_id,3] + 1] >= 2)
            # hit.
            write_size=write_size + trace_write[cmd_id,1]
            if shape(idx_update)[1]>0:
                hit_count=hit_count + 1
                update_size=update_size + shape(idx_update)[1]
            write_count=write_count + 1
            hit_ratio[cmd_id]=hit_count
            write_ratio[cmd_id]=write_size
            update_ratio[cmd_id]=update_size
            if cmd_id % 2000 == 0:
                print(str(float(cmd_id) / idx_write_size)+' has been processed')
            write_cmd_ratio[cmd_id]=write_count
    else:
        if options.access_type == 2:
            y=zeros((total_cmd,1),dtype='int64');
            traces=c_[traces,y]
            traces[:,3]=traces[:,0] + traces[:,1] - 1
            write_ratio=zeros((total_cmd,1))
            update_ratio=zeros((total_cmd,1))
            hit_ratio=zeros((total_cmd,1))
            write_cmd_ratio=zeros((total_cmd,1))
            for cmd_id in arange(0,total_cmd).reshape(-1):
                if traces[cmd_id,2] == 0:
                    LBA_count[traces[cmd_id,0] :traces[cmd_id,3] + 1]=LBA_count[traces[cmd_id,0] :traces[cmd_id,3] + 1] + 1
                    idx_update=nonzero(LBA_count[traces[cmd_id,0] :traces[cmd_id,3] + 1] >= 2)
                    # hit.
                    write_size=write_size + traces[cmd_id,1]
                    if (shape(idx_update)[1]>0):
                        hit_count=hit_count + 1
                        update_size=update_size + shape(idx_update)[1]
                    write_count=write_count + 1
                hit_ratio[cmd_id]=hit_count
                write_ratio[cmd_id]=write_size
                update_ratio[cmd_id]=update_size
                write_cmd_ratio[cmd_id]=write_count
                if cmd_id % 2000 == 0:
                    # toc;
                    print(str(float(cmd_id) / total_cmd)+' has been processed')
                    # tic;
    #raw_input("Press Enter to continue...1")
    
    print('Total processed '+str(cmd_id)+' requests')
    print('Starting the post-procssing: find the blocks for each access frequency')
    
    #raw_input("Press Enter to continue...2")
    
    max_freq=max(LBA_count)
    idx_update=nonzero(LBA_count > 1)
    total_updated_blocks=sum(LBA_count[idx_update])
    
    if update_size != total_updated_blocks - shape(idx_update)[0]:
        'something wrong as the update size is not matched'
    
    all_access_lba=sum(traces[:,1])
    
    #raw_input("Press Enter to continue...3")
    
    update_stat=update_stat_class(write_ratio = (write_ratio / all_access_lba),update_ratio = (update_ratio / all_access_lba))
    
     #   update_stat.write_ratio = (write_ratio / all_access_lba)
     #   update_stat.update_ratio = (update_ratio / all_access_lba)
    if options.access_type == 0:
        update_stat.idx_size = (idx_write_size)
    else:
        if options.access_type == 2:
            update_stat.idx_size = (total_cmd)
    
    
    # update_stat=update_stat_class(update_average_size,hit_ratio,write_cmd_ratio,idx_write_size,write_average_size)
    update_stat.update_average_size=update_size/hit_count;
    update_stat.hit_ratio=hit_ratio/total_cmd;
    update_stat.write_cmd_ratio=write_cmd_ratio/total_cmd;
    update_stat.idx_write_size=idx_write_size;
    update_stat.write_average_size=total_write_size/idx_write_size;
            
    return update_stat


    # if freq_together==1
#     # reduce the size of LBA_count in order to enhance speed
#     idx_0=find(LBA_count>0); # may use large size of memory
#     LBA_count=LBA_count(idx_0);
#     clear idx_0;
#     ##
#     max_freq=max(LBA_count);
#     total_updated_blocks=sum(LBA_count);
#     
#     freq_hit=zeros(max_freq,1,'double');
#     hbar=waitbar(0,'Starting');
#     for i=1:max_freq
#         #tic
#         idx_freq=find(LBA_count==i);
#         freq_hit(i)=(size(idx_freq,1)*double(i));  # it is strange here, as i is not automatically converted into double
#         #toc;
#         pause(0.001)
#         waitbar(i/max_freq,hbar,'Post-Processing...')
#     end
#     close(hbar);
#     
#     freq_cdf=zeros(max_freq,1);
#     for i=1:max_freq
#         if i==1
#             freq_cdf(i)=freq_hit(i);
#         else
#             freq_cdf(i)=freq_cdf(i-1)+freq_hit(i);
#         end
#     end
#     freq_cdf=freq_cdf/total_write_size;
#     idx_acces_lba= find(LBA_count>0);
#     total_access_lba=size(idx_acces_lba,1);
#     
#     update_stat.freq_hit=freq_hit;
#     update_stat.freq_cdf=freq_cdf;
#     update_stat.freq_idx=1:max_freq;
#     update_stat.total_access_lba=total_access_lba;
#     ##
#     toc
# end