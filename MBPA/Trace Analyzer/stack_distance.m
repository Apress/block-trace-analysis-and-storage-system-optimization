function [stack_dist_record_partial,stack_dist_record_full,size_dist,lba_dist]=stack_distance(traces, access_type)
% [stack_dist_record_partial,stack_dist_record_full,size_dist,lba_dist]=stack_distance(traces, access_type)
% calculate the stack distance
%
% input:
%   trace: nX3 matrix; 1 LBA, 2: size, 3: access type read 1/write 0
%   access_type: decide if only consider read 1/write 0 or combined 2
%
% output:
%   stack_dist_record_partial: stack distance for partical hit
%   stack_dist_record_full: stack distance for full hit
%   size_dist: frequency for different hit size; 2 columns array ( 1: full; 2: partial)
%   lba_dist: LBA distribution, 1: full, 2: partial, 3: lba range
%
% Author: jun.xu99@gmail.com

[total_cmd, b] = size(traces);
END_LBA=traces(:, 1) + traces(:, 2) - 1;

stack_dist_record_full=zeros(total_cmd,2); % 1/2: full hit frequency & total request size;
stack_dist_record_partial=zeros(total_cmd,2); % 1/2 partial hit frequency and overlapped size
size_dist=zeros(1024,2); % 1: full; 2: partial

lba_dist_set_size=1000;
if access_type==0
    idx_write=find(traces(:,3)==0);
    max_lba=max(traces(idx_write,1)+traces(idx_write,2));
elseif access_type==1
    idx_read=find(traces(:,3)==1);
    max_lba=max(traces(idx_read,1)+traces(idx_read,2));
else
    max_lba=max(traces(:,1)+traces(:,2));
end

interval=ceil(max_lba/lba_dist_set_size);
lba_dist=zeros(lba_dist_set_size,3); % LBA distribution, 1: full, 2: partial, 3: lba range
lba_dist(:,3)=0:interval:(max_lba-1); %

hbar=waitbar(0,'Starting');

tic;
for cmd_id=1 : total_cmd
    
    %Get the trace information
    start_lba   = traces(cmd_id, 1);
    end_lba     = END_LBA(cmd_id); %traces(cmd_id, 1) + traces(cmd_id, 2) - 1;
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
    
    hit_type=0; % 0 not hit; 1: partial hit; 2: full hit
    idx_write=find( (traces(cmd_id+1:total_cmd, 3)==0));
    idx_write_act=idx_write+cmd_id;
    
    idx=find( (traces(idx_write_act, 1)>= start_lba)  & ( traces(idx_write_act, 1)<=end_lba),1,'first');
    if ~isempty(idx) % the consequent command falls into the LBA range of current command
        hit_type=1; % at least partial hit;
        hit_d=idx;
        idx_ac=idx_write_act(idx);
        % check if full hit; end_lba falls into the range
        if (END_LBA(idx_ac)>= start_lba)  && ( END_LBA(idx_ac)<=end_lba) %(traces(idx_ac, 1)<= end_lba)  && ( END_LBA(idx_ac)>=end_lba)
            hit_type=2;
            %hit_size=traces(cmd_id,2);
            hit_size=traces(idx_ac,2);
            size_dist(hit_size,1)=size_dist(hit_size,1)+1;
            lba_idx=ceil(traces(idx_ac,1)/interval);
            lba_dist(lba_idx,1)=lba_dist(lba_idx,1)+1;
        else
            hit_size=end_lba-traces(idx_ac, 1)+1;
            size_dist(traces(idx_ac, 2),2)=size_dist(traces(idx_ac, 2),2)+1;
            lba_idx=ceil(traces(idx_ac,1)/interval);
            lba_dist(lba_idx,2)=lba_dist(lba_idx,2)+1;
        end
        
    else
        % unnecessary to add "(traces(idx_write_act, 1)< start_lba) &"
        % idx2=find((traces(idx_write_act, 1)< start_lba) & (END_LBA(idx_write_act)>= start_lba)  & ( END_LBA(idx_write_act)<=end_lba),1,'first');
        idx2=find( (END_LBA(idx_write_act)>= start_lba)  & ( END_LBA(idx_write_act)<=end_lba),1,'first');
        if ~isempty(idx2) % the end_lba falls into the range
            hit_type=1; % partial hit only;
            idx_ac=idx_write_act(idx2);
            hit_d=idx2;
            hit_size=END_LBA(idx_ac)-start_lba+1;
            size_dist(traces(idx_ac, 2),2)=size_dist(traces(idx_ac, 2),2)+1;
            lba_idx=ceil(traces(idx_ac,1)/interval);
            lba_dist(lba_idx,2)=lba_dist(lba_idx,2)+1;
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
        waitbar(cmd_id/total_cmd,hbar,[num2str(cmd_id/total_cmd) ' processed'])
        % tic;
    end
    
end
close(hbar);

idx_nonzero=find(stack_dist_record_full(:,1)>0,1,'last');
stack_dist_record_full=stack_dist_record_full(1:idx_nonzero,:);

idx_nonzero=find(stack_dist_record_partial(:,1)>0,1,'last');
stack_dist_record_partial=stack_dist_record_partial(1:idx_nonzero,:);
toc