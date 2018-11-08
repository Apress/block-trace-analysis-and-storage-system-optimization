from numpy import zeros, nonzero, shape, arange, transpose, dot, uint8, uint16, uint32, c_,sum,squeeze, ceil,logical_and,add,copy,mod

def stack_distance(traces=None,access_type=None):
    '''
    calculate the stack_distance
    stack_distance(traces=None,access_type=None)
    input parameters:
        traces: the trace array with first columne for LBA, second for size, and last for operation flags
    output parameters:
        stack_dist_record_partial: the array to record partial hit
        stack_dist_record_full: the array to record full hit
        size_dist: the array to record size distribution
        lba_dist: the array to record lba distribution
    Author: jun.xu99@gmail.com
    '''
    # access_type: decide if only consider read 1/write 0 or combine 2
    print('Processing stack distance ...')
    total_cmd,b=shape(traces)
    END_LBA=traces[:,0] + traces[:,1] - 1
#    stack_dist_record_full=zeros((total_cmd,3))
#    stack_dist_record_partial=zeros((total_cmd,3))
    stack_dist_record_full=zeros((total_cmd,2))
    stack_dist_record_partial=zeros((total_cmd,2))
    size_dist=zeros((1024,2))
    
    lba_dist_set_size=1000
    if access_type == 0:
        idx_write=nonzero(traces[:,2] == 0)
        max_lba=max(END_LBA[idx_write])
    else:
        if access_type == 1:
            idx_read=nonzero(traces[:,2] == 1)
            max_lba=max(END_LBA[idx_read])
        else:
            max_lba=max(END_LBA)
    
    interval=(float(max_lba) / lba_dist_set_size)
    lba_dist=zeros((lba_dist_set_size,3))
    
    lba_dist[:,2]=arange(0,(max_lba ),interval)    
    
    for cmd_id in arange(0,total_cmd).reshape(-1):
        #Get the trace information
        start_lba=traces[cmd_id,0]
        end_lba=END_LBA[cmd_id]
        access_mode=traces[cmd_id,2]
        #Here, only read or write?
        if (access_type == 0):
            if access_mode == 1:
                continue
        else:
            if access_type == 1:
                if access_mode == 0:
                    continue
        hit_type=0
       
        
        idx_write=nonzero((traces[cmd_id + 1:total_cmd,2] == 0))
        idx_write_act=add(idx_write , cmd_id+1)
        idx=nonzero(squeeze(logical_and((traces[idx_write_act,0] >= start_lba),(traces[idx_write_act,0] <= end_lba))))
        if (shape(idx)[1]>0):
            hit_type=1
            hit_d=squeeze(idx[0][0])
            idx_ac=idx_write_act[0,idx[0][0]]
            if (END_LBA[idx_ac] >= start_lba) and (END_LBA[idx_ac] <= end_lba):
                hit_type=2
                hit_size=traces[idx_ac,1]
                size_dist[hit_size-1,0]=size_dist[hit_size-1,0] + 1
                lba_idx=int(ceil(traces[idx_ac,0] / interval-1))            
                lba_dist[lba_idx,0]=lba_dist[lba_idx,0] + 1
            else:
                hit_size=end_lba - traces[idx_ac,0] + 1
                size_dist[traces[idx_ac,1]-1,1]=size_dist[traces[idx_ac,1]-1,1] + 1
                lba_idx=int(ceil(traces[idx_ac,0] / interval-1))
                lba_dist[lba_idx,1]=lba_dist[lba_idx,1] + 1
        else:
            # unnecessary to add "(traces(idx_write_act, 1)< start_lba) &"
        # idx2=find((traces(idx_write_act, 1)< start_lba) & (END_LBA(idx_write_act)>= start_lba)  & ( END_LBA(idx_write_act)<=end_lba),1,'first');
            idx2=nonzero(squeeze(logical_and((END_LBA[idx_write_act] >= start_lba),(END_LBA[idx_write_act] <= end_lba))))
            if (shape(idx2)[1]>0):
                hit_type=1
                idx_ac=idx_write_act[0,idx2[0][0]]
                hit_d=squeeze(idx2[0][0])
                hit_size=END_LBA[idx_ac] - start_lba + 1
                size_dist[traces[idx_ac,1]-1,1]=size_dist[traces[idx_ac,1]-1,1] + 1
                lba_idx=int(ceil(traces[idx_ac,0] / interval-1))
                lba_dist[lba_idx,1]=lba_dist[lba_idx,1] + 1
        if hit_type == 1:
            stack_dist_record_partial[hit_d,0]=stack_dist_record_partial[hit_d,0] + 1
            stack_dist_record_partial[hit_d,1]=stack_dist_record_partial[hit_d,1] + hit_size
        else:
            if hit_type == 2:
                stack_dist_record_full[hit_d,0]=stack_dist_record_full[hit_d,0] + 1
                stack_dist_record_full[hit_d,1]=stack_dist_record_full[hit_d,1] + hit_size
        if mod(cmd_id,5000) == 0:
            print((str(float(cmd_id) / total_cmd)+' processed'))
    print('Process completed')  
    idx_nonzero=nonzero(stack_dist_record_full[:,1] > 0)
    if shape(idx_nonzero)[1]>0:
        stack_dist_record_full=stack_dist_record_full[arange(0,idx_nonzero[0][-1]+1),:]
    else:
        stack_dist_record_full=stack_dist_record_full[:10,:]
    idx_nonzero=nonzero(stack_dist_record_partial[:,1] > 0)
    if shape(idx_nonzero)[1]>0:
        stack_dist_record_partial=stack_dist_record_partial[arange(0,idx_nonzero[0][-1]+1),:]
    else:
        stack_dist_record_partial=stack_dist_record_partial[:10,:]
    
    ## make nx3 array -->TBD
#    idx_nonzero=nonzero(stack_dist_record_full[:,1] > 0)
#    stack_dist_record_full=stack_dist_record_full[squeeze(idx_nonzero),:]
#    stack_dist_record_full[:,2]=idx_nonzero
#    idx_nonzero=nonzero(stack_dist_record_partial[:,1] > 0)
#    stack_dist_record_partial=stack_dist_record_partial[squeeze(idx_nonzero),:]
#    stack_dist_record_partial[:,2]=idx_nonzero
    return stack_dist_record_partial,stack_dist_record_full,size_dist,lba_dist