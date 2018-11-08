from numpy import zeros, nonzero, shape, max, size, ones, min, abs,arange,argmin
    
def seek_distance_stack(q_len,traces,access_type,options):
    '''
input parameters:
    q_len: queue length used in queue
    trace: nX3 matrix; 1 LBA, 2: size, 3: access type read 1/write 0 
    access_type: decide if only consider read 1/write 0 or combined 2
    options: 0: next; 1: closest (not implemented)
output parameters:
    seq_cmd_count: the number of sequential commands
    read_cmd_count: the number of read commands
    total_cmd: total number of commands
    queued_lba_distance: used for calcuate the mode and its counts
    '''
    
    total_cmd=shape(traces)[0]
    queue_index=0
    q_len=int(q_len)
    
    LRU_queue=- ones((q_len,4))
    
    max_lba=max(traces[:,0])
    seq_cmd_count=0
    seq_stream_count=0
    max_stream_length=1024
    max_size=max(traces[:,1])
    size_dist=zeros((max_size,1))
    
    idx_read=nonzero(traces[:,2] == 1)
    read_cmd_count=shape(idx_read)[0]
    if access_type == 0:
        idx_write=nonzero(traces[:,2] == 0)
        size_idx=shape(idx_write)[1]
    else:
        if access_type == 1:
            idx_read=nonzero(traces[:,2] == 1)
            size_idx=shape(idx_read)[1]
        else:
            size_idx=(total_cmd)
    
    queued_lba_distance=zeros((size_idx,1))
    io_counter=-1
    for cmd_id in arange(0,total_cmd):
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
        io_counter=io_counter + 1
        #to sequential stream
        find_sequential=0
        sk_dist=zeros((queue_index,1))
        for q_i in arange(0,queue_index):
            if start_lba == LRU_queue[q_i,1] + 1:
                queued_lba_distance[io_counter]=0
                seq_cmd_count=seq_cmd_count + 1
                break
            else:
                sk_dist[q_i]=abs(start_lba - LRU_queue[q_i,1] - 1)
            Y=min(sk_dist)
            I=argmin(sk_dist)
            sk_disk_ac=start_lba - LRU_queue[I,1]
            if sk_disk_ac > 0:
                queued_lba_distance[io_counter]=sk_disk_ac - 1
            else:
                queued_lba_distance[io_counter]=sk_disk_ac + 1
        #######################################################################
        # if there is no sequential stream for attaching.
        queue_index=queue_index + 1
        if queue_index > q_len:
            queue_index=q_len
            LRU_queue[0:queue_index - 1,:]=LRU_queue[1:queue_index,:]
        queue_index=int(queue_index)
        LRU_queue[queue_index-1,0]=start_lba
        LRU_queue[queue_index-1,1]=end_lba
        LRU_queue[queue_index-1,2]=0
        LRU_queue[queue_index-1,3]=0
    
    return seq_cmd_count, read_cmd_count, total_cmd,queued_lba_distance