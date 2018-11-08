function [n_seq_cmd, n_seq_stream, n_read_cmd, n_total_cmd,size_dist,seq_stream_length_count,seq_stream_length_count_limited,ex_record]=near_sequential_stream_track(q_len, traces, access_type,seq_size_threshold)
% [n_seq_cmd, n_seq_stream, n_read_cmd, n_total_cmd,size_dist,seq_stream_length_count,seq_stream_length_count_limited,ex_record]=near_sequential_stream_track(q_len, traces, access_type,seq_size_threshold)
% calculate the near sequential stream's stack
% 
% input: 
%   q_len: designed queue length 
%   traces: nx3 matrix for IO events (start_lba, size, access mode)
%   access_type: decide if only consider read 1/write 0 or combine 2
%   seq_size_threshold: the threshold to role in sequential stream, i.e., if
%   the stream size >=seq_size_threshold, the stream will be counted as a
%   sequential stream
% output: 
%   n_seq_cmd: number of sequential commands
%   n_seq_stream: number of sequential streams
%   n_read_cmd: number of read commands
%   n_total_cmd: number of total commands
%   size_dist: request size distribution for sequential commands
%   seq_stream_length_count: 1 value at array index i corresponding to the number/frequecy of commands with sequence command length =i; 2: total request size in this index; --> 2/1 average request size
%   seq_stream_length_count_limited: similar to above with constraint seq_size_threshold; only the stream request size is >= seq_size_threshold, it is counted. --> less than above
%   ex_record: exception record
%
% Author: jun.xu99@gmail.com

[total_cmd, b] = size(traces);

queue_index = 0; %At start, there is no commands inside the LRU queue
LRU_queue = -ones(q_len, 4); %1 for start, 2 for end, 3 for sequential or not, 4: number of requests

seq_cmd_count = 0;
seq_stream_count = 0;
max_stream_length=512;
seq_stream_length_count=zeros(max_stream_length,2); % 1 value at array index i corresponding to the number/frequecy of commands with sequence command length =i; 2: total request size in this index; --> 2/1 average request size
seq_stream_length_count_limited=zeros(max_stream_length,2); % similar to above with constraint seq_size_threshold: only the stream request size is >= seq_size_threshold, it is counted. --> less than above
if ~exist('seq_size_threshold','var')
    seq_size_threshold = 1024;
end

max_size=max(traces(:, 2));
size_dist=zeros(max_size,1); % request size distribution for sequential commands
idx_read=find(traces(:,3)==1);
read_cmd_count = size(idx_read,1);
near_distance=64;

ex_record.cmd_number=0;
ex_record.stream_number=0;

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
    
    %We scan through the LRU queue to see whether this command can be connected
    %to sequential stream
    find_sequential = 0;
    for q_i=1 : queue_index
        if (start_lba >= LRU_queue(q_i, 2) + 1) && (start_lba - LRU_queue(q_i, 2) <= near_distance) %start = last_end + 1
            if LRU_queue(q_i, 3) == 1
                seq_cmd_count = seq_cmd_count + 1;
                LRU_queue(q_i, 4) =LRU_queue(q_i, 4)+1;
                size_dist(traces(cmd_id, 2))=size_dist(traces(cmd_id, 2))+1; % statictics of request size distribution
            else
                LRU_queue(q_i, 3) = 1; %set this queue command as sequential one
                LRU_queue(q_i, 4) = 2;
                seq_stream_count = seq_stream_count + 1;
                seq_cmd_count=seq_cmd_count+2;  %<--new
                first_cmd_length=LRU_queue(q_i, 2)-LRU_queue(q_i, 1)+1;
                size_dist(first_cmd_length)=size_dist(first_cmd_length)+1; % the first cmd in this seq stream
                size_dist(traces(cmd_id, 2))=size_dist(traces(cmd_id, 2))+1;                    % the second cmd in this seq stream
            end
            
            find_sequential = 1;
            % LRU_queue(q_i, 2) = start_lba;
            LRU_queue(q_i, 2) = end_lba;
            break;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % if there is no sequential stream for attaching.
    if ~find_sequential
        queue_index = queue_index + 1;
        if queue_index > q_len
            queue_index = q_len;
            if LRU_queue(1,4)>max_stream_length % used to expand seq_stream_length_count
                seq_stream_length_count=[seq_stream_length_count; zeros(LRU_queue(1,4)-max_stream_length,2)];
                seq_stream_length_count_limited=[seq_stream_length_count_limited; zeros(LRU_queue(1,4)-max_stream_length,2)];
                max_stream_length=LRU_queue(1,4);
            end
            
            %             % used to record the exceptation over 1024
            %             if LRU_queue(1,4)>1024
            %                 ex_record.number=ex_record.number+1;
            %             end
            
            if LRU_queue(1,4)>0
                seq_stream_length_count(LRU_queue(1,4),1)=seq_stream_length_count(LRU_queue(1,4),1)+1;
                seq_stream_length_count(LRU_queue(1,4),2)=seq_stream_length_count(LRU_queue(1,4),2)+LRU_queue(1, 2)-LRU_queue(1, 1)+1;
            end
            
            if (LRU_queue(1,4)>0) && (LRU_queue(1, 2)-LRU_queue(1, 1)+1>=seq_size_threshold)
                seq_stream_length_count_limited(LRU_queue(1,4),1)=seq_stream_length_count_limited(LRU_queue(1,4),1)+1;
                seq_stream_length_count_limited(LRU_queue(1,4),2)=seq_stream_length_count_limited(LRU_queue(1,4),2)+LRU_queue(1, 2)-LRU_queue(1, 1)+1;
                ex_record.cmd_number=ex_record.cmd_number+LRU_queue(1,4);
            end
            
            LRU_queue(1:queue_index-1, :) = LRU_queue(2:queue_index, :);
        end
        LRU_queue(queue_index, 1) = start_lba;
        LRU_queue(queue_index, 2) = end_lba;
        LRU_queue(queue_index, 3) = 0; %initialize for the sequential mode
        LRU_queue(queue_index, 4) = 0;
    end
    
end

for j=1:q_len
    if LRU_queue(j,4)>max_stream_length
        seq_stream_length_count=[seq_stream_length_count; zeros(LRU_queue(j,4)-max_stream_length,2)];
        seq_stream_length_count_limited=[seq_stream_length_count_limited; zeros(LRU_queue(j,4)-max_stream_length,2)];
        max_stream_length=LRU_queue(j,4);
    end
    %     if LRU_queue(j,4)>0
    %         seq_stream_length_count(LRU_queue(j,4),1)=seq_stream_length_count(LRU_queue(j,4),1)+1;
    %         seq_stream_length_count(LRU_queue(j,4),2)=seq_stream_length_count(LRU_queue(j,4),2)+1+LRU_queue(q_i, 2)-LRU_queue(q_i, 1);
    %     end
    %
    %     if (LRU_queue(q_i,4)>0) && (LRU_queue(q_i, 2)-LRU_queue(q_i, 1)+1>=seq_size_threshold)
    %         seq_stream_length_count_limited(LRU_queue(q_i,4),1)=seq_stream_length_count_limited(LRU_queue(q_i,4),1)+1;
    %         seq_stream_length_count_limited(LRU_queue(q_i,4),2)=seq_stream_length_count_limited(LRU_queue(q_i,4),2)+1+LRU_queue(q_i, 2)-LRU_queue(q_i, 1);
    %         ex_record.cmd_number=ex_record.cmd_number+LRU_queue(q_i,4);
    %     end
end


n_seq_cmd = seq_cmd_count;
n_seq_stream = seq_stream_count;
n_read_cmd = read_cmd_count;
n_total_cmd = total_cmd;
ex_record.stream_number=sum(seq_stream_length_count_limited(:,1));

