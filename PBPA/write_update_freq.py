from numpy import zeros, nonzero, shape, arange, transpose, dot, uint8, uint16, uint32, c_,r_,sum,squeeze,mod,min,max,uint64
import psutil
    

class update_stat_class:
    def __init__(self,freq_hit=None,freq_cdf=None,freq_idx=None,total_access_lba=None,c_freq_cdf=None,c_freq_cdf_total=None,cmd_freq_record=None):
        self.freq_hit = freq_hit
        self.freq_cdf = freq_cdf
        self.freq_idx = freq_idx
        self.total_access_lba = total_access_lba
        self.c_freq_cdf=c_freq_cdf
        self.c_freq_cdf_total=c_freq_cdf_total
        self.cmd_freq_record=cmd_freq_record
    
def write_update_freq(traces=None,access_type=None,options=None):

    # access_type: decide if only consider read 1/write 0 or combine 2
# options.drive_max_lba=2*1024^4/512;
# trace format: 1 LBA, 2 size, 3 operation type (1read 0 write)
    
    total_cmd,b=shape(traces)
    idx_write=nonzero((traces[:,2] == 0))
    idx_write_size=shape(idx_write)[1]
    #trace_write=uint64(traces[idx_write,:])
    # clear('traces')
    #total_write_size=sum(trace_write[:,1])
    
    
    trace_write=squeeze(traces[transpose(idx_write),:])
    total_write_size=sum(trace_write[:,1])
    trace_write=c_[trace_write,zeros((idx_write_size,1),dtype='int')] # make the trace_write still integer
    trace_write[:,3]=trace_write[:,0] + trace_write[:,1] - 1
    min_lba=min(trace_write[:,0])
    #min_lba=min(trace_write(:,1));
    trace_write[:,(0,3)]=trace_write[:,(0,3)] - min_lba
                
    max_lba=max(trace_write[:,3])+1
    
    
    # the following variable "eats" a big amount of memory. the structure can
    # be either a sparse matrix or a normal matrix
    # due to the memory limitation, we have to set it as uint16 or uint8. If
    # the trace is very long, it may exceed the max value.
    # hit_count=0
    
   
    systemview=psutil.virtual_memory()
    if systemview.available > dot((max_lba + 1024),8):
        LBA_count=zeros((max_lba ,1))
    else:
        if systemview.available > dot((max_lba + 1024),4):
            LBA_count=(zeros((max_lba ,1),dtype=uint32))
        else:
            if systemview.available > dot((max_lba + 1024),2):
                LBA_count=(zeros((max_lba ,1),dtype=uint16))
            else:
                if systemview.available > (max_lba + 1024):
                    LBA_count=(zeros((max_lba ,1),dtype=uint8))
                else:
                    # LBA_count=sparse(max_lba + 1024,1)
                     ## later we will change to use sparse matrix scipy.sparse.hstack
                    print('some issues with small memory size')
                    print ('the future version will use sparse matrix; due to different access mode of sparse matrix with the normal array, the sparse matrix is not implemented')
                    return None
    
    #update_size=0
       
    
    max_freq=1024
    cmd_freq_record=zeros((max_freq,1))
    #write_cmd_hit=zeros((1000,1))
    
    print('Starting the pre-procssing: find the access frequency of each LBA')
    
    for cmd_id in arange(0,idx_write_size).reshape(-1):
        # the following step is time-consuming for sparse matrix
        LBA_count[trace_write[cmd_id,0] :trace_write[cmd_id,3]+1 ]=LBA_count[trace_write[cmd_id,0] :trace_write[cmd_id,3]+1 ] + 1
        freq=uint32(max(LBA_count[trace_write[cmd_id,0] :trace_write[cmd_id,3] ]))
        if freq > max_freq:
            cmd_freq_record=r_[cmd_freq_record,zeros((1024,1))]
            max_freq=max_freq + 1024
        cmd_freq_record[freq-1]=cmd_freq_record[freq-1] + 1
        if mod(cmd_id,5000) == 0:
            # toc;
            print('Pre-Processing data...'+str(float(cmd_id)/idx_write_size)+' completed')
            # tic;
    print('Pre-Processing data... completed')    
        
    max_freq=int(max(LBA_count))
    total_updated_blocks=sum(LBA_count)
    
    if total_write_size != total_updated_blocks:
        print('Warming!!! something wrong as the total block size is not matched: total_write_size='+str(total_write_size)+' and total_updated_blocks='+str(total_updated_blocks))
    
    if idx_write_size != sum(cmd_freq_record):
        print('Warming!!! something wrong as the total requrest number is not matched')
    
    # reduce the size of LBA_count in order to enhance speed
    idx_0=nonzero(LBA_count > 0)        
    LBA_count=LBA_count[idx_0]
    
    print('Starting the post-procssing: find the blocks for each access frequency')
    
    freq_hit=zeros((max_freq,1),dtype=uint32)
    
    for i in arange(0,max_freq):
        if cmd_freq_record[i] == 0:
            continue
        idx_freq=nonzero(LBA_count[:] == (i+1))
        freq_hit[i]=(shape(idx_freq)[1]*(i+1))
    
    
    freq_cdf=zeros((max_freq,1))
    for i in arange(0,max_freq).reshape(-1):
        if i == 0:
            freq_cdf[i]=freq_hit[i]
        else:
            freq_cdf[i]=freq_cdf[i - 1] + freq_hit[i]
    
    freq_cdf=freq_cdf / total_write_size
    idx_acces_lba=nonzero(LBA_count > 0)
    total_access_lba=shape(idx_acces_lba)[1]
    
    #    update_stat.freq_hit = copy(freq_hit)
    #    update_stat.freq_cdf = copy(freq_cdf)
    #    update_stat.freq_idx = copy(arange(1,max_freq))
    #    update_stat.total_access_lba = copy(total_access_lba)
    idx=nonzero(cmd_freq_record > 0)
    
    cmd_freq_record = (cmd_freq_record[idx])
    c_freq_cdf=zeros((shape(idx)[1],1))
    c_freq_cdf[0]=cmd_freq_record[0]
    for i in arange(1,shape(idx)[1]).reshape(-1):
        c_freq_cdf[i]=c_freq_cdf[i - 1] + cmd_freq_record[i]
    
    c_freq_cdf=c_freq_cdf / idx_write_size
    #    update_stat.c_freq_cdf = copy(c_freq_cdf)
    #    update_stat.c_freq_cdf_total = copy(c_freq_cdf[idx])
    #    update_stat.cmd_freq_record = copy(cmd_freq_record)
    
    
    update_stat=update_stat_class(freq_hit,freq_cdf,arange(1,max_freq+1),total_access_lba,c_freq_cdf,c_freq_cdf[shape(idx)[1]-1],cmd_freq_record)

    return update_stat