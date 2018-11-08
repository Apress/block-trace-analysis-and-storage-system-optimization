function [stat_record]=lba_size_dist(traces, access_type,options)
% function [stat_record]=lba_size_dist(lists_cmd, access_type,options)
% --> calcuate the size distribution
% inputs
%   traces=lists_cmd: n samples x 3 for LBA, size, flags
%   access_type: 0 write, 1 read, 2 all
%   options: control parameters
%       lba_size_set: how many LBA range sets; the smaller the set numbers,
%       the larger the frequency in each set; choose a reasonable value (too large value leads to too small frequency)
% outputs
%   stat_record: statistics
%
% Author jun.xu99@gmail.com

[total_cmd, b] = size(traces);

size_dist=zeros(1024,2); % 1: full; 2: partial
lba_dist_set_size=options.lba_size_set;
if access_type==0
    idx_write=find(traces(:,3)==0);
    max_lba=max(traces(idx_write,1));
    %max_lba=max(traces(idx_write,1)+traces(idx_write,2));
elseif access_type==1
    idx_read=find(traces(:,3)==1);
    max_lba=max(traces(idx_read,1));
    %max_lba=max(traces(idx_read,1)+traces(idx_read,2));
else
    max_lba=max(traces(:,1));
    %max_lba=max(traces(:,1)+traces(:,2));
end
interval=ceil(max_lba/lba_dist_set_size);
lba_size_dist=zeros(lba_dist_set_size,1024);
%lba_size_dist(:,1024)=0:interval:max_lba; %

hbar=waitbar(0,'Starting');

tic;
for cmd_id=1 : total_cmd
    
    %Get the trace information
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
    lba_idx=ceil(traces(cmd_id,1)/interval);
    lba_size_dist(lba_idx,traces(cmd_id,2))=lba_size_dist(lba_idx,traces(cmd_id,2))+1;
    
    if mod(cmd_id,2000)==0
        waitbar(cmd_id/total_cmd,hbar,'Processing...')
    end
end
close(hbar);

stat_record.lba_size_dist=lba_size_dist;
stat_record.lba_size_idx=0:interval:max_lba;
if size(stat_record.lba_size_idx,2)>lba_dist_set_size
    stat_record.lba_size_idx=stat_record.lba_size_idx(1:lba_dist_set_size);
end