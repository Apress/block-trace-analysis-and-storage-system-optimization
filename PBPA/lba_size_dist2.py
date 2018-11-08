import numpy as np
from math import ceil, floor

class stat_record_class:
  def __init__(self, lba_size_dist, lba_size_idx):
     self.lba_size_dist = lba_size_dist
     self.lba_size_idx = lba_size_idx

def lba_size_dist2(traces, access_type, options=1):
    '''
    Local Variables: lba_idx, b, cmd_id, access_mode, max_lba, idx_write, access_type, interval, stat_record, size_dist, idx_read, lba_size_idx, total_cmd, lba_dist_set_size, lba_size_dist, hbar, traces, options
    Function calls: waitbar, max, ceil, zeros, close, lba_size_dist, mod, tic, find, size
    function [stat_record]=lba_size_dist(lists_cmd, access_type,options)
    --> calcuate the size distribution
    inputs
       traces=lists_cmd: n samples x 3 for LBA, size, flags
       access_type: 0 write, 1 read, 2 all
       options: control parameters
           lba_size_set: how many LBA range sets
    outputs
       stat_record: statistics 
    
    Author: jun.xu99@gmail.com 
   '''
   
    total_cmd=len(traces)
    # size_dist=np.zeros((1024,2))
    
    # lba_dist_set_size=options.lba_size_set
    lba_dist_set_size=50
    
    if access_type == 0:
        idx_write=np.nonzero(traces[:,2] == 0)
        max_lba=max(traces[idx_write,0].T)
    else:
        if access_type == 1:
            idx_read=np.nonzero(traces[:,2] == 1)
            max_lba=max(traces[idx_read,0].T)
        else:
            max_lba=max(traces[:,0].T)
    
    interval=int(ceil(max_lba / lba_dist_set_size))
    lba_size_dist=np.zeros((lba_dist_set_size,1024))
    #lba_size_dist(:,1024)=0:interval:max_lba; #
    
    
    for cmd_id in np.arange(0,total_cmd).reshape(-1):
        #Get the trace information
        access_mode=traces[cmd_id,2]
        #Here, only read or write?
        if (access_type == 0):
            if access_mode == 1:
                continue
        else:
            if access_type == 1:
                if access_mode == 0:
                    continue
        lba_idx=int(ceil(traces[cmd_id,0] / interval))
        if lba_idx>=lba_dist_set_size:
            lba_idx=lba_dist_set_size-1        
        lba_size_dist[lba_idx,traces[cmd_id,1]-1]=lba_size_dist[lba_idx,traces[cmd_id,1]-1] + 1
    
    # print('lba_size_dist length is '+str(len(lba_size_dist)))    
    # print('starting to create a class')
    stat_record=stat_record_class(lba_size_dist,0)
    # print('starting to assign class value')
    # stat_record.lba_size_dist = np.copy(lba_size_dist)
    stat_record.lba_size_idx = np.copy(np.arange(0,max_lba,interval))
    if len(stat_record.lba_size_idx) > lba_dist_set_size:
        stat_record.lba_size_idx = np.copy(stat_record.lba_size_idx[np.arange(0,lba_dist_set_size)])        
        
    # print('finish and return')
    return stat_record

# x=lba_size_dist2(lists_cmd, 0, options)