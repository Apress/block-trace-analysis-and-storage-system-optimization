%% this program further parse the btt output "Per-IO Data file" via the parameter "-p"
%% here only Q,D,C information are extracted, as they are common for each requests; others, eg. M/G/I. do not appear in all requests, thus not included in the parser.
function IO_list=parse_per_IO_data(filename,options)

if nargin<2
    options.major_dev=8;
    options.minor_dev=0;
end

fid=fopen(filename);

if fid<0
    disp('error to open the file');
    return
end

if isfield(options, 'major_dev') && isfield(options, 'minor_dev')
    device_no=[int2str(options.major_dev),',',int2str(options.minor_dev)];
else
    device_no='8,0';
end

si=20000; % initial number of requests
si_inc=5000; % incremental number
IO_list=zeros(si,3); % first arrival time to the queue, request issued time to disk, request completion time from disk

i=0; j=1;
tline=fgetl(fid);
while ischar(tline)
    % each sub-IO starts with device no and end with a black line
    % each IO ends with "-----------------------------------------"
    % read each sub-IO in an IO group, and find the smallest arrival time
    % as the first arrival time.
    
    IO_end=0; arr_temp=[];   
    while ~IO_end
        
        if strfind(tline,device_no)
            idx=strfind(tline,':');
            x=sscanf(tline(idx+1:size(tline,2)),'%f %c %d+%d');
            if x(2)==81 %% Q
                arr_temp=[arr_temp,x(1)];
            end
        elseif strfind(tline,'-----')
            IO_end=1;
            i=i+1;
            if i>si
                IO_list=[IO_list;zeros(si_inc,3)];
                si=si+si_inc;
            end
            IO_list(i,:)=[min(arr_temp), d_t, c_t];   
        elseif size(tline,2)>2
            x=sscanf(tline,'%f %c %d+%d');
            if x(2)==68 %% D
                d_t=x(1);
            elseif x(2)==67
                c_t=x(1);
            end
        else
            % empty line; end of sub-IO
        end
        tline=fgetl(fid);j=j+1;
        
        
        
    end    
end

fclose(fid);
IO_list=IO_list(1:i,:);