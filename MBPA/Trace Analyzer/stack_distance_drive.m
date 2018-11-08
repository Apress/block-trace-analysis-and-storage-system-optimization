function [stack_dist_record_partial,stack_dist_record_full,update_stat]=stack_distance_drive(traces, access_type,options)
% access_type: decide if only consider read 1/write 0 or combine 2
%options.drive_max_lba=2*1024^4/512;
%%JUN, not clear from the description what the input data is supposed to look like for this function

[total_cmd, b] = size(traces);
END_LBA=traces(:, 1) + traces(:, 2) - 1;
stack_dist_record_full=zeros(total_cmd,2); % 1/2: full hit frequency & total request size;
stack_dist_record_partial=zeros(total_cmd,2); % 1/2 partial hit frequency and overlapped size
idx_write=find( (traces(1:total_cmd, 3)==0));
idx_write_size=size(idx_write,1);
min_lba=min(traces(idx_write, 1));
max_lba=max(END_LBA(idx_write));
act_lba=max_lba-min_lba+1;
LBA_count=(zeros(act_lba,1,'uint8'));
non_hit_size=0;
non_hit_freq=0;

tic;
hbar=waitbar(0,'Starting');
for cmd_id=1 : idx_write_size
    %Get the trace information
    start_lba   = traces(idx_write(cmd_id), 1);
    end_lba     = END_LBA(idx_write(cmd_id)); %traces(cmd_id, 1) + traces(cmd_id, 2) - 1;
    access_mode = traces(idx_write(cmd_id), 3); %write_mode = 0, read_mode = 1
    
    hit_type=0; % 0 not hit; 1: partial hit; 2: full hit
    idx_write_act=idx_write(cmd_id+1:idx_write_size);
    idx=find( (traces(idx_write_act, 1)>= start_lba)  & ( traces(idx_write_act, 1)<=end_lba),1,'first');
    if ~isempty(idx) % the consequent command falls into the LBA range of current command
        hit_type=1; % at least partial hit;
        hit_d=idx;
        idx_ac=idx_write_act(idx+cmd_id);
        % check if full hit; end_lba falls into the range
        if (END_LBA(idx_ac)>= start_lba)  && ( END_LBA(idx_ac)<=end_lba) %(traces(idx_ac, 1)<= end_lba)  && ( END_LBA(idx_ac)>=end_lba)
            hit_type=2;
            %hit_size=traces(cmd_id,2);
            hit_size=traces(idx_ac,2);
            LBA_count(traces(idx_ac,1)-min_lba+1:END_LBA(idx_ac)-min_lba+1)=LBA_count(traces(idx_ac,1):END_LBA(idx_ac))+1;
        else
            hit_size=end_lba-traces(idx_ac, 1)+1;
            LBA_count(traces(idx_ac,1)-min_lba+1:end_lba-min_lba+1)=LBA_count(traces(idx_ac,1):end_lba)+1;
            non_hit_size=non_hit_size+traces(idx_write(cmd_id), 1)-hit_size;
        end
    else
        idx2=find( (END_LBA(idx_write_act)>= start_lba)  & ( END_LBA(idx_write_act)<=end_lba),1,'first');
        if ~isempty(idx2) % the end_lba falls into the range
            hit_type=1; % partial hit only;
            idx_ac=idx_write_act(cmd_id+idx2);
            hit_d=idx2;
            hit_size=END_LBA(idx_ac)-start_lba+1;
            LBA_count(start_lba-min_lba+1:END_LBA(idx_ac)-min_lba+1)=LBA_count(start_lba:END_LBA(idx_ac))+1;
            non_hit_size=non_hit_size+traces(idx_write(cmd_id), 1)-hit_size;
        else
            non_hit_size=non_hit_size+traces(idx_write(cmd_id), 2);
            not_hit_freq=non_hit_freq+1;
        end
    end
    
    if hit_type==1
        stack_dist_record_partial(hit_d,1)=stack_dist_record_partial(hit_d,1)+1;
        stack_dist_record_partial(hit_d,2)=stack_dist_record_partial(hit_d,2)+hit_size;
    elseif hit_type==2
        stack_dist_record_full(hit_d,1)=stack_dist_record_full(hit_d,1)+1;
        stack_dist_record_full(hit_d,2)=stack_dist_record_full(hit_d,2)+hit_size;
        
    end
    if mod(cmd_id,2000)==0
        % toc;
        waitbar(cmd_id/total_cmd,hbar,'Processing...')
        % tic;
    end
    
end
close(hbar);

idx_nonzero=find(stack_dist_record_full(:,1)>0,1,'last');
stack_dist_record_full=stack_dist_record_full(1:idx_nonzero,:);
idx_nonzero=find(stack_dist_record_partial(:,1)>0,1,'last');
stack_dist_record_partial=stack_dist_record_partial(1:idx_nonzero,:);
Total_write_size=sum( traces(idx_write, 2));
max_freq=max(LBA_count);
total_updated_blocks=sum(LBA_count);

if total_updated_blocks+non_hit_size~=Total_write_size
    'Mismatched size'
end
freq_hit=zeros(max_freq+1,1);
for i=1:max_freq
    idx_freq=find(LBA_count==i);
    freq_hit(i+1)=size(idx_freq,1)*i;
end
freq_hit(1)=Total_write_size-sum(freq_hit(2:max_freq+1));
freq_cdf=zeros(max_freq+1,1);
for i=1:max_freq
    freq_cdf(i+1)=freq_cdf(i)+freq_hit(i+1);
end
freq_cdf=freq_cdf/options.drive_max_lba;
update_stat.freq_cdf=freq_cdf;

toc
