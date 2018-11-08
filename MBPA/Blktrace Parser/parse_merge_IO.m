%% this program merges the parsed results from "Per-IO Data file" and "--dump-blocknos" in order to obtain a commonly used trace list

function IO_list=parse_merge_IO(IO_time,IO_R, IO_W, options)

if nargin<4
    options.window=2000;
end


IO_num=size(IO_time,1);
IO_num_r=size(IO_R,1);
IO_num_w=size(IO_W,1);

if IO_num_r+IO_num_w~=IO_num
    disp(['WARMING: the total IO number does not match: IO_num-IO_num_r-IO_num_w=', int2str(IO_num-IO_num_r-IO_num_w)]);
end

IO_all=[IO_R ones(IO_num_r,1); IO_W zeros(IO_num_w,1)];
IO_all = sortrows(IO_all,1);
IO_list_idx=zeros(IO_num,1); % record the corresponding index in IO_all, and then link to IO_time

IO_time=sortrows(IO_time,2);

j=1; 

for i=1:IO_num
    
    if j+options.window>IO_num
        je=IO_num;
    else
        je=j+options.window;
    end
    
    IO_temp=IO_all(j:je,1);
    idx=find(abs(IO_time(i,2)-IO_temp)<1e-9);
    if ~isempty(idx)
        %find the corresponding idx in IO_all
        IO_list_idx(i)=idx+j-1;
        j=idx+j;
    end
end

idx0=find(IO_list_idx==0);
disp(['there are total ' int2str(size(idx0,1)), ' IOs in IO_time set not matched' ]);
idx1=find(IO_list_idx~=0);
IO_list=[IO_time(idx1,:) IO_all(IO_list_idx(idx1),:)];
