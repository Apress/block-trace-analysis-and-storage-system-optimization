function [seq_cmd_count, read_cmd_count, total_cmd, queued_lba_distance]=seek_distance_stack(q_len, traces, access_type,options)
% [seq_cmd_count, read_cmd_count, total_cmd, queued_lba_distance]=seek_distance_stack(q_len, traces, access_type,options)
% calculate the seek distance stack
%
% input parameters:
%   q_len: queue length used in queue
%   trace: nX3 matrix; 1 LBA, 2: size, 3: access type read 1/write 0 
%   access_type: decide if only consider read 1/write 0 or combined 2
%   options: 0: next; 1: closest (not implemented)
%
% output parameters:
%   seq_cmd_count: the number of sequential commands
%   read_cmd_count: the number of read commands
%   total_cmd: total number of commands
%   queued_lba_distance: used for calcuate the mode and its counts
%
% Author: jun.xu99@gmail.com


[total_cmd, b] = size(traces);

queue_index = 0; %At start, there is no commands inside the LRU queue
LRU_queue = -ones(q_len, 4); %1 for start, 2 for end, 3 for sequential or not, 4: number of requests
max_lba=max(traces(:,1));
seq_cmd_count = 0;
seq_stream_count = 0;
max_stream_length=1024;


max_size=max(traces(:, 2));
size_dist=zeros(max_size,1); % request size distribution for sequential commands
idx_read=find(traces(:,3)==1);
read_cmd_count = size(idx_read,1);

if access_type==0
    idx_write=find(traces(:,3)==0);
    size_idx=size(idx_write,1);
elseif access_type==1
    idx_read=find(traces(:,3)==1);
    size_idx=size(idx_read,1);
else
    size_idx=total_cmd;
end
queued_lba_distance=zeros(size_idx,1);

io_counter=0;

for cmd_id=1 : total_cmd
    
    %Get the trace information
    start_lba   = traces(cmd_id, 1);
    end_lba     = traces(cmd_id, 1) + traces(cmd_id, 2) - 1;
    access_mode = traces(cmd_id, 3); %write_mode = 0, read_mode = 1
    
    %Here, only read or write?
    if(access_type==0)
        if access_mode==1
            continue;
        end
    elseif access_type==1
        if access_mode==0
            continue;
        end
    end
    
    io_counter=io_counter+1;
    %We scan through the LRU queue to see whether this command can be connected
    %to sequential stream
    find_sequential = 0;
    sk_dist=zeros(queue_index,1);
    for q_i=1 : queue_index
        if start_lba == LRU_queue(q_i, 2) + 1 %start = last_end + 1
            queued_lba_distance(io_counter)=0;
            seq_cmd_count = seq_cmd_count + 1;
            break;
        else
            sk_dist(q_i)=abs(start_lba-LRU_queue(q_i, 2)-1);
        end
        [Y,I]=min(sk_dist);
        sk_disk_ac=start_lba-LRU_queue(I, 2);
        if sk_disk_ac>0
            queued_lba_distance(io_counter)=sk_disk_ac-1;
        else
            queued_lba_distance(io_counter)=sk_disk_ac+1;
        end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % if there is no sequential stream for attaching.
    
    queue_index = queue_index + 1;
    if queue_index > q_len
        queue_index = q_len;
        LRU_queue(1:queue_index-1, :) = LRU_queue(2:queue_index, :);
    end
    LRU_queue(queue_index, 1) = start_lba;
    LRU_queue(queue_index, 2) = end_lba;
    LRU_queue(queue_index, 3) = 0; %initialize for the sequential mode
    LRU_queue(queue_index, 4) = 0;
    
end


