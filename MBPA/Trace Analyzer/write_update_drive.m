function [update_stat]=write_update_drive(traces, access_type,options)
% this function is replaced by write_update_time

[total_cmd, b] = size(traces);
idx_write=find( (traces(1:total_cmd, 3)==0));
idx_write_size=size(idx_write,1);
%trace_write=zeros(idx_write_size,4);
trace_write=traces(idx_write,:);
total_write_size=sum( trace_write(:, 2));
trace_write(:,4)=trace_write(:,1)+trace_write(:,2)-1;
%min_lba=min(trace_write(:,1));
max_lba=max(trace_write(:,4));
%act_lba=max_lba-min_lba+1;


if isfield(options, 'freq_together')
    freq_together=options.freq_together;
else
    freq_together=0;
end

[userview systemview] = memory;
if systemview.PhysicalMemory.Available>(max_lba+1024)*8  % default is double
    LBA_count=zeros(max_lba+1024,1);
elseif systemview.PhysicalMemory.Available>(max_lba+1024)*4
    LBA_count=(zeros(max_lba+1024,1,'uint32'));
elseif systemview.PhysicalMemory.Available>(max_lba+1024)*2
    LBA_count=(zeros(max_lba+1024,1,'uint16'));
elseif systemview.PhysicalMemory.Available>(max_lba+1024)
    LBA_count=(zeros(max_lba+1024,1,'uint8'));       
else
    LBA_count=sparse(max_lba+1024,1);
end
%LBA_count=(zeros(act_lba,1,'uint8'));
% LBA_count=(zeros(max_lba+1,1,'uint8')); % need to count LBA 0;

write_size=0; % total write request size
update_size=0; % total update request size (at least write 2 times)
hit_count=0; % total update command numbers
write_count=0;

tic;
hbar=waitbar(0,'Starting');

disp('Starting the pre-procssing: find the access frequency of each LBA')
pause(0.1);

if options.access_type==0  % consider write only
    
    write_ratio=zeros(idx_write_size,1);
    update_ratio=zeros(idx_write_size,1);
    hit_ratio=zeros(idx_write_size,1);
    write_cmd_ratio=zeros(idx_write_size,1);
    
    for cmd_id=1 : idx_write_size
        LBA_count(trace_write(cmd_id,1)+1:trace_write(cmd_id,4)+1)=LBA_count(trace_write(cmd_id,1)+1:trace_write(cmd_id,4)+1)+1;
        % >=2 means at least the corresponding range has been written 2
        % times --> updated LBAs.
        idx_update=find(LBA_count(trace_write(cmd_id,1)+1:trace_write(cmd_id,4)+1)>=2);
        % this method is difficult to identify whether it is a full or partial
        % hit.
        write_size=write_size+trace_write(cmd_id,2);
        if ~isempty(idx_update)
            hit_count=hit_count+1;
            update_size=update_size+size(idx_update,1);
        end
        write_count=write_count+1;
        hit_ratio(cmd_id)=hit_count;
        write_ratio(cmd_id)=write_size;
        update_ratio(cmd_id)=update_size;
        
        if mod(cmd_id,2000)==0
            % toc;
            waitbar(cmd_id/idx_write_size,hbar,'Pre-Processing data...')
            % tic;
        end
    end
    write_cmd_ratio(cmd_id)=write_count;
    
elseif options.access_type==2 % put all togheter
    
    traces=[traces zeros(total_cmd,1)];
    traces(:,4)=traces(:,1)+traces(:,2)-1;
    write_ratio=zeros(total_cmd,1);
    update_ratio=zeros(total_cmd,1);
    hit_ratio=zeros(total_cmd,1);
    write_cmd_ratio=zeros(total_cmd,1);
    for cmd_id=1 : total_cmd
        
        if traces(cmd_id,3)==0
            LBA_count(traces(cmd_id,1)+1:traces(cmd_id,4)+1)=LBA_count(traces(cmd_id,1)+1:traces(cmd_id,4)+1)+1;
            idx_update=find(LBA_count(traces(cmd_id,1)+1:traces(cmd_id,4)+1)>=2);
            % this method is difficult to identify whether it is a full or partial
            % hit.
            write_size=write_size+traces(cmd_id,2);
            if ~isempty(idx_update)
                hit_count=hit_count+1;
                update_size=update_size+size(idx_update,1);
            end
            write_count=write_count+1;
        end
        hit_ratio(cmd_id)=hit_count;
        write_ratio(cmd_id)=write_size;
        update_ratio(cmd_id)=update_size;
        write_cmd_ratio(cmd_id)=write_count;
        
        if mod(cmd_id,2000)==0
            % toc;
            waitbar(cmd_id/total_cmd,hbar,'Pre-Processing data...')
            % tic;
        end
    end
    
end

close(hbar);

disp('Starting the post-procssing: find the blocks for each access frequency')
pause(0.1);

max_freq=max(LBA_count);

idx_update=find(LBA_count>1);
total_updated_blocks=sum(LBA_count(idx_update)); % the blocks at least write twice



if update_size~=total_updated_blocks-size(idx_update,1)  % total (actual) blocks - write once = updated size
    'something wrong as the update size is not matched'
end

all_access_lba=sum(traces(:,2));

update_stat.write_ratio=write_ratio/all_access_lba;
update_stat.update_ratio=update_ratio/all_access_lba;
if options.access_type==0
    update_stat.idx_size=idx_write_size;
elseif options.access_type==2
    update_stat.idx_size=total_cmd;
end
update_stat.update_average_size=update_size/hit_count;
update_stat.hit_ratio=hit_ratio/total_cmd;
update_stat.write_cmd_ratio=write_cmd_ratio/total_cmd;
update_stat.idx_write_size=idx_write_size;
update_stat.write_average_size=total_write_size/idx_write_size;


if freq_together==1
    % reduce the size of LBA_count in order to enhance speed
    idx_0=find(LBA_count>0); % may use large size of memory
    LBA_count=LBA_count(idx_0);
    clear idx_0;
    %%
    max_freq=max(LBA_count);
    total_updated_blocks=sum(LBA_count);
    
    freq_hit=zeros(max_freq,1,'double');
    hbar=waitbar(0,'Starting');
    for i=1:max_freq
        %tic
        idx_freq=find(LBA_count==i);
        freq_hit(i)=(size(idx_freq,1)*double(i));  % it is strange here, as i is not automatically converted into double
        %toc;
        pause(0.001)
        waitbar(i/max_freq,hbar,'Post-Processing...')
    end
    close(hbar);
    
    freq_cdf=zeros(max_freq,1);
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
    %%
    toc
end