from numpy import zeros, nonzero, shape, arange, transpose, dot, uint8, uint16, uint32, c_,sum,squeeze, ceil,logical_and,add,copy,mod


def stack_distance_row(traces=None,access_type=None):
    '''
    calculate the stack_distance of read on write
    stack_distance_row(traces=None,access_type=None)
    input parameters:
        traces: the trace array with first columne for LBA, second for size, and last for operation flags
    output parameters:
        stack_dist_record_partial: the array to record partial hit; hit frequency & hit requests' total size
        stack_dist_record_full: the array to record full hit
    Author: jun.xu99@gmail.com
    '''

    # access_type: decide if only consider read 1/write 0 or combine 2
    print('Processing ROW stack distance')
    total_cmd,b=shape(traces)
    END_LBA=traces[:,0] + traces[:,1] - 1
    stack_dist_record_full=zeros((total_cmd,2))
    
    stack_dist_record_partial=zeros((total_cmd,2))    
    
    for cmd_id in arange(0,total_cmd).reshape(-1):
        #Get the trace information
        start_lba=traces[cmd_id,0]
        end_lba=END_LBA[cmd_id]
        access_mode=traces[cmd_id,2]
        if access_mode == 1:
            continue
        # we actually need to check each write command, and to see if the
    # subsequent read commands hit it; once we find a subsequent write hit,
    # stop it, as the changed command will be considered as a new one;
        hit_type=0
        #     idx_write=find( (traces(cmd_id+1:total_cmd, 3)==0));
    #     idx_write_act=idx_write+cmd_id;
        hit_d_p=[]
        hit_d_f=[]
        idx=nonzero(squeeze(logical_and((traces[cmd_id + 1:-1,0] >= start_lba),(traces[cmd_id + 1:-1,0] <= end_lba))))
        if (shape(idx)[1]>0):
            hit_type=1
            idx_ac=add(idx,cmd_id)
            size_idx_ac=shape(idx_ac)[1]
            hit_d_p=[]
            hit_d_f=[]
            for j in arange(0,size_idx_ac).reshape(-1):
                if traces[idx_ac[0][j],2] == 1:
                    # check if full hit; end_lba falls into the range
                    hit_size_f=0
                    hit_size_p=0
                    if ((END_LBA[idx_ac[0][j]] >= start_lba) and (END_LBA[idx_ac[0][j]] <= end_lba)):
                        hit_type=2
                        hit_size_f=hit_size_f + traces[idx_ac[0][j],1]
                        #hit_d_f=(c_[[hit_d_f],[idx_ac[j] - cmd_id + 1]])
                        hit_d_f.append(idx_ac[0][j] - cmd_id + 1)
                    else:
                        hit_size_p=hit_size_p + end_lba - traces[idx_ac[0][j],0] + 1
                        #hit_d_p=(c_[[hit_d_p],[idx_ac[j] - cmd_id + 1]])
                        hit_d_p.append(idx_ac[0][j] - cmd_id + 1)
                else:
                    break
        else:
            idx2=nonzero(squeeze(logical_and((END_LBA[cmd_id + 1:total_cmd] >= start_lba),(END_LBA[cmd_id + 1:total_cmd] <= end_lba))))[0]
            idx2_ac=cmd_id + idx2
            if (shape(idx2)[0]>0):
                size_idx2_ac=shape(idx2_ac)[0]
                hit_size_p=0
                hit_d_p=[]
                for j in arange(0,size_idx2_ac).reshape(-1):
                    if traces[idx2_ac[j],2] == 1:
                        hit_type=1
                        #hit_d_p=(c_[[hit_d_p],[idx2_ac[j] - cmd_id + 1]])
                        hit_d_p.append(idx2_ac[j] - cmd_id + 1)
                        hit_size_p=hit_size_p + END_LBA[idx2_ac[j]] - start_lba + 1
                    else:
                        break
        if (shape(hit_d_p)[0]>0):

            stack_dist_record_partial[hit_d_p,0]=stack_dist_record_partial[hit_d_p,0] + 1
            stack_dist_record_partial[hit_d_p,1]=stack_dist_record_partial[hit_d_p,1] + hit_size_p
            
        if (shape(hit_d_f)[0]>0):
            stack_dist_record_full[hit_d_f,0]=stack_dist_record_full[hit_d_f,0] + 1
            stack_dist_record_full[hit_d_f,1]=stack_dist_record_full[hit_d_f,1] + hit_size_f
        if mod(cmd_id,5000) == 0:
            # toc;
            print('Processing '+str(float(cmd_id) / total_cmd))
            # tic;
    print('Process completed')       
    idx_nonzero=nonzero(stack_dist_record_full[:,0] > 0)
    if shape(idx_nonzero)[1]>0:
        idx_nonzero=idx_nonzero[0][-1]
        stack_dist_record_full=stack_dist_record_full[0:idx_nonzero,:]
    else:
        stack_dist_record_full=stack_dist_record_full[0:10,:]
    idx_nonzero=nonzero(stack_dist_record_partial[:,0] > 0)
    if shape(idx_nonzero)[1]>0:
        idx_nonzero=idx_nonzero[0][-1]
        stack_dist_record_partial=stack_dist_record_partial[0:idx_nonzero,:]
    else:
        stack_dist_record_partial=stack_dist_record_partial[0:10,:]
    
    return stack_dist_record_partial,stack_dist_record_full