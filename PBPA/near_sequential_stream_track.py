from numpy import zeros, nonzero, shape, arange, transpose, dot, uint8, uint16, uint32, c_,r_,sum,squeeze, ceil,logical_and,add,copy,mod,mean,array,ones,logical_not
from matplotlib.pylab import plot, xlabel, ylabel, title, legend, figure, hold, savefig, grid 
# from statistics import mode
from scipy.stats import mode 
from scipy import mean, median,std


class ex_record_class:
    def __init__(self,cmd_number=None,stream_number=None):
        self.cmd_number = cmd_number
        self.stream_number = stream_number

def near_sequential_stream_track(q_len=None,traces=None,access_type=None,seq_size_threshold=None):
    '''
 [n_seq_cmd, n_seq_stream, n_read_cmd, n_total_cmd,size_dist,seq_stream_length_count,seq_stream_length_count_limited,ex_record]=near_sequential_stream_track(q_len, traces, access_type,seq_size_threshold)
 calculate the near sequential stream's stack
 
 input: 
   q_len: designed queue length 
   traces: nx3 matrix for IO events (start_lba, size, access mode)
   access_type: decide if only consider read 1/write 0 or combine 2
   seq_size_threshold: the threshold to role in sequential stream, i.e., if
   the stream size >=seq_size_threshold, the stream will be counted as a
   sequential stream
 output: 
   n_seq_cmd: number of sequential commands
   n_seq_stream: number of sequential streams
   n_read_cmd: number of read commands
   n_total_cmd: number of total commands
   size_dist: request size distribution for sequential commands
   seq_stream_length_count: 1 value at array index i corresponding to the number/frequecy of commands with sequence command length =i; 2: total request size in this index; --> 2/1 average request size
   seq_stream_length_count_limited: similar to above with constraint seq_size_threshold; only the stream request size is >= seq_size_threshold, it is counted. --> less than above
   ex_record: exception record

 Author: jun.xu99@gmail.com
    '''    
    total_cmd,b=shape(traces)
    queue_index=0
    
    print('Near Sequence analysis: Queue length ='+str(q_len)+' and access type ='+str(access_type))
    
    traces=traces.astype(uint32)
    
    LRU_queue=- ones((q_len,4),dtype=uint32)
    
    seq_cmd_count=0
    seq_stream_count=0
    max_stream_length=1024
    seq_stream_length_count=zeros((max_stream_length,2))    
    seq_stream_length_count_limited=zeros((max_stream_length,2))
    
    #    if logical_not(exist('seq_size_threshold','var')):
    #        #seq_size_threshold = 1024;
    #        pass
    
    max_size=max(traces[:,1])
    size_dist=zeros((max_size,1),dtype=uint16)
    
    idx_read=nonzero(traces[:,2] == 1)
    read_cmd_count=shape(idx_read)[0]
    near_distance=64
    
    ex_record=ex_record_class(0,0)    
    
    for cmd_id in arange(0,total_cmd).reshape(-1):
        #Get the trace information
        start_lba=traces[cmd_id,0]
        end_lba=traces[cmd_id,0] + traces[cmd_id,1] - 1
        access_mode=traces[cmd_id,2]
        #Here, only read or write?
        if (access_type == 0):
            if access_mode == 1:
                continue
        else:
            if access_type == 1:
                if access_mode == 0:
                    continue
        #We scan through the LRU queue to see whether this command can be connected
    #to sequential stream
        find_sequential=0
        for q_i in arange(0,queue_index).reshape(-1):
            if (start_lba >= LRU_queue[q_i,1] + 1) and (start_lba - LRU_queue[q_i,1] <= near_distance):
                if LRU_queue[q_i,2] == 1:
                    seq_cmd_count=seq_cmd_count + 1
                    LRU_queue[q_i,3]=LRU_queue[q_i,3] + 1
                    size_dist[traces[cmd_id,1]-1]=size_dist[traces[cmd_id,1]-1] + 1
                else:
                    LRU_queue[q_i,2]=1
                    LRU_queue[q_i,3]=2
                    seq_stream_count=seq_stream_count + 1
                    seq_cmd_count=seq_cmd_count + 2
                    first_cmd_length=int(LRU_queue[q_i,1] - LRU_queue[q_i,0] + 1)
                    size_dist[first_cmd_length-1]=size_dist[first_cmd_length-1] + 1
                    size_dist[traces[cmd_id,1]-1]=size_dist[traces[cmd_id,1]-1] + 1
                find_sequential=1
                LRU_queue[q_i,1]=end_lba
                break
        #######################################################################
    # if there is no sequential stream for attaching.
        if logical_not(find_sequential):
            queue_index=queue_index + 1
            if queue_index > q_len:
                queue_index=copy(q_len)
                if LRU_queue[0,3] > max_stream_length:
                    seq_stream_length_count=(r_[seq_stream_length_count,zeros((LRU_queue[0,3] - max_stream_length+1,2))])
                    seq_stream_length_count_limited=(r_[seq_stream_length_count_limited,zeros((LRU_queue[0,3] - max_stream_length+1,2))])
                    max_stream_length=LRU_queue[0,3]
            #             # used to record the exceptation over 1024
            #             if LRU_queue(1,4)>1024
            #                 ex_record.number=ex_record.number+1;
            #             end
            
                idx=int(LRU_queue[0,3])
                if idx> 0:                    
    #                    seq_stream_length_count[idx-1,0]=seq_stream_length_count[idx-1,0] + 1
    #                    seq_stream_length_count[idx-1,1]=seq_stream_length_count[idx-1,1] + LRU_queue[0,1] - LRU_queue[0,0] + 1
                    seq_stream_length_count[idx,0]=seq_stream_length_count[idx,0] + 1
                    seq_stream_length_count[idx,1]=seq_stream_length_count[idx,1] + LRU_queue[0,1] - LRU_queue[0,0] + 1
                    
                if (idx > 0) and (LRU_queue[0,1] - LRU_queue[0,0] + 1 >= seq_size_threshold):
    #                    seq_stream_length_count_limited[idx-1,0]=seq_stream_length_count_limited[idx-1,0] + 1
    #                    seq_stream_length_count_limited[idx-1,1]=seq_stream_length_count_limited[idx-1,1] + LRU_queue[0,1] - LRU_queue[0,0] + 1
                    seq_stream_length_count_limited[idx,0]=seq_stream_length_count_limited[idx,0] + 1
                    seq_stream_length_count_limited[idx,1]=seq_stream_length_count_limited[idx,1] + LRU_queue[0,1] - LRU_queue[0,0] + 1
                    ex_record.cmd_number = (ex_record.cmd_number + idx)
                LRU_queue[0:queue_index - 1,:]=LRU_queue[1:queue_index,:]
            LRU_queue[queue_index-1,0]=start_lba
            LRU_queue[queue_index-1,1]=end_lba
            LRU_queue[queue_index-1,2]=0
            LRU_queue[queue_index-1,3]=0            
            
    for j in arange(0,q_len).reshape(-1):
        if LRU_queue[j,3] > max_stream_length:
            seq_stream_length_count=(r_([seq_stream_length_count,zeros((LRU_queue[j,3] - max_stream_length,2))]))
            seq_stream_length_count_limited=(r_[seq_stream_length_count_limited,zeros((LRU_queue[j,3] - max_stream_length,2))])
            max_stream_length=LRU_queue[j,3]
    
    #     if LRU_queue(j,4)>0
    #         seq_stream_length_count(LRU_queue(j,4),1)=seq_stream_length_count(LRU_queue(j,4),1)+1;
    #         seq_stream_length_count(LRU_queue(j,4),2)=seq_stream_length_count(LRU_queue(j,4),2)+1+LRU_queue(q_i, 2)-LRU_queue(q_i, 1);
    #     end
    #     
    #     if (LRU_queue(q_i,4)>0) && (LRU_queue(q_i, 2)-LRU_queue(q_i, 1)+1>=seq_size_threshold)
    #         seq_stream_length_count_limited(LRU_queue(q_i,4),1)=seq_stream_length_count_limited(LRU_queue(q_i,4),1)+1;
    #         seq_stream_length_count_limited(LRU_queue(q_i,4),2)=seq_stream_length_count_limited(LRU_queue(q_i,4),2)+1+LRU_queue(q_i, 2)-LRU_queue(q_i, 1);
    #         ex_record.cmd_number=ex_record.cmd_number+LRU_queue(q_i,4);
    #     end
    
    n_seq_cmd=copy(seq_cmd_count)
    n_seq_stream=copy(seq_stream_count)
    n_read_cmd=copy(read_cmd_count)
    n_total_cmd=copy(total_cmd)
    ex_record.stream_number = copy(sum(seq_stream_length_count_limited[:,0]))
    
    return n_seq_cmd,n_seq_stream,n_read_cmd,n_total_cmd,size_dist,seq_stream_length_count,seq_stream_length_count_limited,ex_record
    
    