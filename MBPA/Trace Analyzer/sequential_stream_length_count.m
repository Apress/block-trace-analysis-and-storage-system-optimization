function []= sequential_stream_length_count(trace_folder, total_trace_files, queue_len_setting, output_folder)
% this function is particular for PCMark trace
% parse and display results of PCMark trace
%
% input parameters:
%   trace_folder: Path to PCMark output
%   total_trace_files: Number of files in the folder
%   queue_len_setting: What was Qd for the PCMark trace
%   output_folder: Location to generate figures
% output parameters:
%   Generates analysis of frequency of stream length for PCMark in output_folder
%
% Author: jun.xu99@gmail.com

num_queue_setting = size(queue_len_setting, 2);

FREQUENCY_ARRAY_SIZE = 1000;
MAX_FREQUENCY_NUMBER = 3;

stream_length_read_only = zeros(num_queue_setting, FREQUENCY_ARRAY_SIZE);
max_stream_length_read_only = zeros(total_trace_files, num_queue_setting, MAX_FREQUENCY_NUMBER);
max_length_read_only = zeros(total_trace_files, num_queue_setting, MAX_FREQUENCY_NUMBER);
stream_length_all = zeros(num_queue_setting, FREQUENCY_ARRAY_SIZE);
max_stream_length_all = zeros(total_trace_files, num_queue_setting, MAX_FREQUENCY_NUMBER);
max_length_all = zeros(total_trace_files, num_queue_setting, MAX_FREQUENCY_NUMBER);


file_handle = fopen('frequency_length.csv', 'w');
fprintf(file_handle, 'File ID, Queue ID, 1st, 2nd, 3rd\n');

file_handle1 = fopen('max_length.csv', 'w');
fprintf(file_handle, 'File ID, Queue ID, 1st, 2nd, 3rd\n');

for file_id=1 : total_trace_files
    disp([int2str(file_id), '.csv']);
    % Here, we load the trace files, and pass the loading result
    % to the processor for processing
    filename = [trace_folder int2str(file_id), '.csv'];
    % before loading the trace file, we need to clear the temp first
    clear PcMark_trace;
    load_csv_file;
    
    
    for queue_id=1 : num_queue_setting
        queue_len = queue_len_setting(queue_id);
        disp(['queue size = ', int2str(queue_len)]);
        [stream_len_frequency_array, max_length_array, max_frequency_length] = sequential_stream_length_track(queue_len, PcMark_trace, 1, FREQUENCY_ARRAY_SIZE, MAX_FREQUENCY_NUMBER);
        stream_length_read_only(queue_id, :) = stream_len_frequency_array;
        max_stream_length_read_only(file_id, queue_id, :) = max_frequency_length;
        max_length_read_only(file_id, queue_id, :) = max_length_array;
        
        fprintf(file_handle, '%d, %d, %d, %d, %d\n', file_id, queue_len_setting(queue_id), ...
            max_frequency_length(1), max_frequency_length(2), max_frequency_length(3));
        fprintf(file_handle1, '%d, %d, %d, %d, %d\n', file_id, queue_len_setting(queue_id), ...
            max_length_array(1), max_length_array(2), max_length_array(3));
        
        [stream_len_frequency_array, max_length_array, max_frequency_length] = sequential_stream_length_track(queue_len, PcMark_trace, 0, FREQUENCY_ARRAY_SIZE, MAX_FREQUENCY_NUMBER);
        stream_length_all(queue_id, :) = stream_len_frequency_array;
        max_stream_length_all(file_id, queue_id, :) = max_frequency_length;
        max_length_all(file_id, queue_id, :) = max_length_array;
    end
    
    title_name = [int2str(file_id), '.csv ', 'stream length test'];
    app_title={'qlen =1','qlen =4', 'qlen =16','qlen =32','qlen =64','qlen =128', 'qlen =256'};
    plot_flags={'r','r-.','r:','k--','b','b-.','b:'};
    f1 = figure;
    hold on;
    f2 = figure;
    hold on;
    legend_str=[];
    for queue_id=1:num_queue_setting
        figure(f1);
        plot([1 : FREQUENCY_ARRAY_SIZE],stream_length_read_only(queue_id, :), plot_flags{queue_id});
        xlabel('Stream length read only');
        ylabel('Frequency');
        title(title_name);
        
        figure(f2);
        plot([1 : FREQUENCY_ARRAY_SIZE],stream_length_all(queue_id, :), plot_flags{queue_id});
        xlabel('Stream length all');
        ylabel('Frequency');
        title(title_name);
        
        if queue_id==num_queue_setting
            legend_str=[legend_str,'''',app_title{queue_id},''''];
        else
            legend_str=[legend_str,'''',app_title{queue_id},'''',','];
        end
    end
    figure(f1);
    set(gca,'xscale','log')
    eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEastOutside', '''',')']);
    
    filename = [output_folder,'\', int2str(file_id), '_frequency_read_only'];
    saveas(gcf, filename, 'fig');
    
    figure(f2);
    set(gca,'xscale','log')
    eval(['legend(', legend_str, ',', '''','Location','''', ',', '''','NorthEastOutside', '''',')']);
    
    filename = [ output_folder,'\', int2str(file_id), '_frequency_all'];
    saveas(gcf, filename, 'fig');
end
%save the most used frequency's length value

% 	file_handle = fopen('frequency_length.csv', 'w');
% 	fprintf(file_handle, 'File ID, Queue ID, 1st, 2nd, 3rd\n');
% 	for file_id=1 : total_trace_files
% 		for queue_id=1 :num_queue_setting
% 			a1 = max_stream_length_read_only(file_id, queue_id, 1);
% 			a2 = max_stream_length_read_only(file_id, queue_id, 2);
% 			a3 = max_stream_length_read_only(file_id, queue_id, 3);
% 			fprintf(file_handle, '%d, %d, %d, %d, %d\n', file_id, queue_len_setting(queue_id), a1, a2, a3);
% 		end
% 	end
% 	fclose(file_handle);
fclose(file_handle);
fclose(file_handle1);

%     file_handle = fopen('max_length.csv', 'w');
% 	fprintf(file_handle, 'File ID, Queue ID, 1st, 2nd, 3rd\n');
% 	for file_id=1 : total_trace_files
% 		for queue_id=1 :num_queue_setting
% 			a1 = max_length_read_only(file_id, queue_id, 1);
% 			a2 = max_length_read_only(file_id, queue_id, 2);
% 			a3 = max_length_read_only(file_id, queue_id, 3);
% 			fprintf(file_handle, '%d, %d, %d, %d, %d\n', file_id, queue_len_setting(queue_id), a1, a2, a3);
% 		end
% 	end
% 	fclose(file_handle);
end
