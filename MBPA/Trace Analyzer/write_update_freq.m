function [update_stat]=write_update_freq(traces, access_type,options)
% access_type: decide if only consider read 1/write 0 or combine 2
% options.drive_max_lba=2*1024^4/512;
% trace format: 1 LBA, 2 size, 3 operation type (1read 0 write)

[total_cmd, b] = size(traces);
idx_write=find( (traces(1:total_cmd, 3)==0));
idx_write_size=size(idx_write,1);
trace_write=traces(idx_write,:);

clear traces;

total_write_size=sum( trace_write(:, 2));
min_lba=min(trace_write(:,1));
trace_write(:,4)=trace_write(:,1)+trace_write(:,2)-1;
trace_write(:,[1,4])=trace_write(:,[1,4])-min_lba;
max_lba=max(trace_write(:,4))+1;

% the following variable "eats" a big amount of memory. the structure can
% be either a sparse matrix or a normal matrix
% due to the memory limitation, we have to set it as uint16 or uint8. If
% the trace is very long, it may exceed the max value.
hit_count=0; % command level hit count
[userview systemview] = memory;
if systemview.PhysicalMemory.Available>(max_lba)*8  % default is double
    LBA_count=zeros(max_lba,1);
elseif systemview.PhysicalMemory.Available>(max_lba)*4
    LBA_count=(zeros(max_lba,1,'uint32'));
elseif systemview.PhysicalMemory.Available>(max_lba)*2
    LBA_count=(zeros(max_lba,1,'uint16'));
elseif systemview.PhysicalMemory.Available>(max_lba)
    LBA_count=(zeros(max_lba,1,'uint8'));    
else
    % LBA_count=sparse(act_lba+1024,1);
    % LBA_count=sparse(1,act_lba+1024);
    LBA_count=spalloc(act_lba+1024,1,ceil(size(trace_write,1)*mean(trace_write(:,2))));
end
update_size=0;


max_freq=1024;
cmd_freq_record=zeros(max_freq,1);
write_cmd_hit=zeros(1000,1);

tic;
disp('Starting the pre-procssing: find the access frequency of each LBA')
pause(0.1);
hbar=waitbar(0,'Starting');
for cmd_id=1 : idx_write_size
    
    % the following step is time-consuming for sparse matrix
    LBA_count(trace_write(cmd_id,1)+1:trace_write(cmd_id,4)+1)=LBA_count(trace_write(cmd_id,1)+1:trace_write(cmd_id,4)+1)+1;  
    
    freq=max(LBA_count(trace_write(cmd_id,1)+1:trace_write(cmd_id,4)+1));
    if freq>max_freq
        cmd_freq_record=[cmd_freq_record; zeros(1024,1)];
        max_freq=max_freq+1024;
    end
    cmd_freq_record(freq)=cmd_freq_record(freq)+1;
    
    if mod(cmd_id,200)==0
        % toc;
        waitbar(cmd_id/idx_write_size,hbar,'Pre-Processing data...')
        % tic;
    end
end
close(hbar);

max_freq=max(LBA_count);
total_updated_blocks=sum(LBA_count);

if total_write_size~=total_updated_blocks
    disp('Warming!!! something wrong as the total block size is not matched')
end

if idx_write_size~=sum(cmd_freq_record)
    disp('Warming!!! something wrong as the total requrest number is not matched')
end

% reduce the size of LBA_count in order to enhance speed
tic
idx_0=find(LBA_count>0); % may use large size of memory; time consuming --> may change to small size 
toc;

% tic;
% idx_0=[];
% count0=0;
% range0=1e8;
% while count0<size(LBA_count,1)
%     counts=count0+1;
%     count0=count0+range0;
%     if count0>size(LBA_count,1)
%         count0=size(LBA_count,1);
%     end
%     idx=find(LBA_count(counts:count0)>0);
%     idx_0=[idx_0;idx];
% end
% toc;

LBA_count=LBA_count(idx_0);
clear idx_0;

disp('Starting the post-procssing: find the blocks for each access frequency')
pause(0.1);
tic
freq_hit=zeros(max_freq,1,'double');
hbar=waitbar(0,'Starting');
for i=1:max_freq
    if cmd_freq_record(i)==0
        continue;
    end
    idx_freq=find(LBA_count==i); % this step is very time-consuming
    freq_hit(i)=(size(idx_freq,1)*double(i));  % it is strange here, as i is not automatically converted into double
    
    pause(0.001)
    waitbar(i/max_freq,hbar,'Post-Processing...')
end
close(hbar);
toc

freq_cdf=zeros(1,max_freq);
for i=1:max_freq
    if i==1
        freq_cdf(i)=freq_hit(i);
    else
        freq_cdf(i)=freq_cdf(i-1)+freq_hit(i);
    end
end
freq_cdf=freq_cdf/total_write_size;
idx_acces_lba= find(LBA_count>0);
total_access_lba=size(idx_acces_lba,1);

update_stat.freq_hit=freq_hit;
update_stat.freq_cdf=freq_cdf;
update_stat.freq_idx=1:max_freq;
update_stat.total_access_lba=total_access_lba;

idx=find(cmd_freq_record>0,1,'last');
update_stat.cmd_freq_record=cmd_freq_record(1:idx);
c_freq_cdf=zeros(idx,1);
c_freq_cdf(1)=cmd_freq_record(1);
for i=2:idx
    c_freq_cdf(i)=c_freq_cdf(i-1)+cmd_freq_record(i);
    % c_freq_cdf(i)=c_freq_cdf(i-1)+cmd_freq_record(i)*i;
end
c_freq_cdf=c_freq_cdf/idx_write_size;
update_stat.c_freq_cdf=c_freq_cdf;
update_stat.c_freq_cdf_total=c_freq_cdf(idx);
update_stat.cmd_freq_record=cmd_freq_record;
