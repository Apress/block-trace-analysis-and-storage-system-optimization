function sub_sequence_queue(lists_cmd,options)
% sub_sequence_queue(lists_cmd,options)
% evaluate the sequence queue of given IO trace
%
% input:
%   lists_cmd:  n samples x 3 for LBA, size, flags
%   options: general options on figure, threshold and etc
% output: None
%
% Author: jun.xu99@gmail.com and junpeng.niu@wdc.com

if isfield(options, 'plot_fontsize')
    plot_fontsize=options.plot_fontsize;
else
    plot_fontsize=10;
end

if isfield(options, 'save_figure')
    save_figure=options.save_figure;
else
    save_figure=1;
end

if isfield(options, 'near_sequence')
    near_sequence=options.near_sequence;
else
    near_sequence=0;
end

if isfield(options, 'S2_threshold')
    S2_threshold=options.S2_threshold;
else
    S2_threshold=32;
end

if isfield(options, 'S2_threshold2')
    S2_threshold2=options.S2_threshold2;
else
    S2_threshold2=64;
end

if isfield(options, 'seq_size_threshold')
    seq_size_threshold=options.seq_size_threshold;
else
    seq_size_threshold=1024;
end

if isfield(options, 'max_stream_length')
    max_stream_length=options.max_stream_length;
else
    max_stream_length=1024;
end

if near_sequence==0
    options.section_name='Strict Sequence';
else
    options.section_name='Near Sequence';
end

if isfield(options, 'plot_figure')
    plot_figure=options.plot_figure;
else
    plot_figure=1;
end

queue_len_setting=2.^(0:1:7);
file_id=1;
num_queue_setting=size(queue_len_setting,2);
plot_flags={'r','k--','b-.','b:','y--','r:','y:','r-.'};

FREQUENCY_ARRAY_SIZE = 10000; % this value should be dynamic, as for a very long trace, it can be very large
MAX_FREQUENCY_NUMBER = 3;
total_trace_files=1;

% all the data array below should be dynamically changed based on
% FREQUENCY_ARRAY_SIZE --> code this later
stream_length_write_only = zeros(num_queue_setting, FREQUENCY_ARRAY_SIZE);
max_stream_length_write_only = zeros(total_trace_files, num_queue_setting, MAX_FREQUENCY_NUMBER);
max_length_write_only = zeros(total_trace_files, num_queue_setting, MAX_FREQUENCY_NUMBER);
stream_length_read_only = zeros(num_queue_setting, FREQUENCY_ARRAY_SIZE);
max_stream_length_read_only = zeros(total_trace_files, num_queue_setting, MAX_FREQUENCY_NUMBER);
max_length_read_only = zeros(total_trace_files, num_queue_setting, MAX_FREQUENCY_NUMBER);
stream_length_all = zeros(num_queue_setting, FREQUENCY_ARRAY_SIZE);
max_stream_length_all = zeros(total_trace_files, num_queue_setting, MAX_FREQUENCY_NUMBER);
max_length_all = zeros(total_trace_files, num_queue_setting, MAX_FREQUENCY_NUMBER);


for queue_id=1 : num_queue_setting
    queue_len = queue_len_setting(queue_id);
    disp(['queue size = ', int2str(queue_len)]);
    [stream_len_frequency_array, max_length_array, max_frequency_length] = sequential_stream_length_track(queue_len, lists_cmd, 1, FREQUENCY_ARRAY_SIZE, MAX_FREQUENCY_NUMBER);
    stream_length_read_only(queue_id, :) = stream_len_frequency_array;
    max_stream_length_read_only(file_id, queue_id, :) = max_frequency_length;
    max_length_read_only(file_id, queue_id, :) = max_length_array;
    
    [stream_len_frequency_array, max_length_array, max_frequency_length] = sequential_stream_length_track(queue_len, lists_cmd, 0, FREQUENCY_ARRAY_SIZE, MAX_FREQUENCY_NUMBER);
    stream_length_write_only(queue_id, :) = stream_len_frequency_array;
    max_stream_length_write_only(file_id, queue_id, :) = max_frequency_length;
    max_length_write_only(file_id, queue_id, :) = max_length_array;
    %
    %              fprintf(file_handle, '%d, %d, %d, %d, %d\n', file_id, queue_len_setting(queue_id), ...
    %              max_frequency_length(1), max_frequency_length(2), max_frequency_length(3));
    %              fprintf(file_handle1, '%d, %d, %d, %d, %d\n', file_id, queue_len_setting(queue_id), ...
    %              max_length_array(1), max_length_array(2), max_length_array(3));
    %
    [stream_len_frequency_array, max_length_array, max_frequency_length] = sequential_stream_length_track(queue_len, lists_cmd, 2, FREQUENCY_ARRAY_SIZE, MAX_FREQUENCY_NUMBER);
    stream_length_all(queue_id, :) = stream_len_frequency_array;
    max_stream_length_all(file_id, queue_id, :) = max_frequency_length;
    max_length_all(file_id, queue_id, :) = max_length_array;
end

if plot_figure
    f1 = figure;
    hold on;
    f2 = figure;
    hold on;
    f3 = figure;
    hold on;
    legend_str=[];
    for queue_id=1:num_queue_setting
        figure(f1);
        plot([1 : FREQUENCY_ARRAY_SIZE],stream_length_read_only(queue_id, :), plot_flags{queue_id});
        xlabel('Stream length ');
        ylabel('Frequency');
        title('Stream length read only');
        set(gca,'xscale','log')
        
        figure(f3);
        plot([1 : FREQUENCY_ARRAY_SIZE],stream_length_write_only(queue_id, :), plot_flags{queue_id});
        xlabel('Stream length ');
        ylabel('Frequency');
        title('Stream length write only');
        set(gca,'xscale','log')
        
        figure(f2);
        plot([1 : FREQUENCY_ARRAY_SIZE],stream_length_all(queue_id, :), plot_flags{queue_id});
        xlabel('Stream length ');
        ylabel('Frequency');
        title('Stream length combined');
        set(gca,'xscale','log')
    end
end
