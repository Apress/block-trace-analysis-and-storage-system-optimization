function [seq_len_frequency_array, length_array, max_indices]=sequential_stream_length_track(q_len, traces, access_type, frequency_array_size, num_max)
% [seq_len_frequency_array, length_array, max_indices]=sequential_stream_length_track(q_len, traces, access_type, frequency_array_size, num_max)
% 
% input: 
%   q_len: designed queue length 
%   traces: nx3 matrix for IO events (start_lba, size, access mode)
%   access_type: decide if only consider read 1/write 0 or combine 2
%   frequency_array_size:
%   num_max: 
% output: 
%     seq_len_frequency_array: the frequency record for different sequential stream length 
%     length_array: the length of sequential stream 
%     max_indices
%
% Author: jun.xu99@gmail.com and junpeng.niu@wdc.com

WRITE = 1;

[total_cmd, b] = size(traces);

queue_index = 0; %At start, there is no commands inside the LRU queue
LRU_queue = -ones(q_len, 4); %1 for start, 2 for end, 3 for sequential or not 4 for the length count

length_frequency_array = zeros(frequency_array_size, 1);
for cmd_id=1 : total_cmd
    
    %Get the trace information
    start_lba   = traces(cmd_id, 1);
    end_lba     = traces(cmd_id, 1) + traces(cmd_id, 2) - 1;
    access_mode = traces(cmd_id, 3); %write_mode = 0, read_mode = 1
    
    %Here, can the write command be processed in sequence with read
    %command?
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
        if start_lba == LRU_queue(q_i, 2) + 1 %start = last_end + 1
            if LRU_queue(q_i, 3) == 1
                LRU_queue(q_i, 4) = LRU_queue(q_i, 4) + 1;
            else
                LRU_queue(q_i, 3) = 1; %set this queue command as sequential one
                LRU_queue(q_i, 4) = 2; %first sequential is also counted
            end
            
            find_sequential = 1;
            LRU_queue(q_i, 2) = end_lba;
            break;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % if there is no sequential stream for attaching.
    if ~find_sequential
        queue_index = queue_index + 1;
        
        if queue_index > q_len
            %Here we need to consider the frequency count
            length = LRU_queue(1, 4);
            if length>frequency_array_size
                length_frequency_array=[length_frequency_array;zeros(length-frequency_array_size+100,1)];
            end
            if length > 1
                length_frequency_array(length) = length_frequency_array(length)+1;
            end
            queue_index = q_len;
            LRU_queue(1:queue_index-1, :) = LRU_queue(2:queue_index, :);
        end
        LRU_queue(queue_index, 1) = start_lba;
        LRU_queue(queue_index, 2) = end_lba;
        LRU_queue(queue_index, 3) = 0; %initialize for the sequential mode
        LRU_queue(queue_index, 4) = 0; %initialize for the sequential mode
    end
end

%At the end, the whole queue needs to be scaned
for i=1 : queue_index
    length = LRU_queue(i, 4);
    if length > 1
        length_frequency_array(length) = length_frequency_array(length)+1;
    end
end

[sortedValue , sortedIndex] = sort(length_frequency_array, 'descend');
max_indices = sortedIndex(1: num_max);
seq_len_frequency_array = length_frequency_array;

count = 0;
sorted_length = zeros(num_max, 1);
array_size = size(length_frequency_array, 1);
for i = 1 : array_size
    value = length_frequency_array(array_size - i + 1);
    if value > 0
        count = count + 1;
        sorted_length(count) = array_size - i + 1;
        if count == 3
            break;
        end
    end
end
length_array = sorted_length;

%     for i=1 : frequency_array_size
%         if length_frequency_array(i) >= 1
%             disp(['Length = ',int2str(i), ' Frequency = ', int2str(length_frequency_array(i))]);
%         end
%     end
end

























