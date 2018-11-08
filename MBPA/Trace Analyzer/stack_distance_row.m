function [stack_dist_record_partial,stack_dist_record_full]=stack_distance_row(traces, access_type)
% access_type: decide if only consider read 1/write 0 or combine 2
% calcuate read on write

[total_cmd, b] = size(traces);
END_LBA=traces(:, 1) + traces(:, 2) - 1;

stack_dist_record_full=zeros(total_cmd,2); % 1/2: full hit frequency & total request size;
stack_dist_record_partial=zeros(total_cmd,2); % 1/2 partial hit frequency and overlapped size

hbar=waitbar(0,'Starting');

tic;
for cmd_id=1 : total_cmd
    
    %Get the trace information
    start_lba   = traces(cmd_id, 1);
    end_lba     = END_LBA(cmd_id); %traces(cmd_id, 1) + traces(cmd_id, 2) - 1;
    access_mode = traces(cmd_id, 3); %write_mode = 0, read_mode = 1
    
    
    if access_mode==1
        continue;
    end
    
    % we actually need to check each write command, and to see if the
    % subsequent read commands hit it; once we find a subsequent write hit,
    % stop it, as the changed command will be considered as a new one;
    
    hit_type=0; % 0 not hit; 1: partial hit; 2: full hit
    %     idx_write=find( (traces(cmd_id+1:total_cmd, 3)==0));
    %     idx_write_act=idx_write+cmd_id;
    hit_d_p=[];
    hit_d_f=[];
    idx=find( (traces(cmd_id+1:total_cmd, 1)>= start_lba)  & ( traces(cmd_id+1:total_cmd, 1)<=end_lba));
    if ~isempty(idx) % the consequent command falls into the LBA range of current command
        hit_type=1; % at least partial hit;
        
        idx_ac=cmd_id+idx;
        size_idx_ac=size(idx_ac,1);
        hit_d_p=[];
        hit_d_f=[];
        for j=1:size_idx_ac
            if traces(idx_ac(j),3)==1 % if the hit command is read
                % check if full hit; end_lba falls into the range
                hit_size_f=0;
                hit_size_p=0;
                if ((END_LBA(idx_ac(j))>= start_lba)  && ( END_LBA(idx_ac(j))<=end_lba)) %(traces(idx_ac, 1)<= end_lba)  && ( END_LBA(idx_ac)>=end_lba)
                    hit_type=2;
                    %hit_size=traces(cmd_id,2);
                    hit_size_f=hit_size_f+traces(idx_ac(j),2);
                    hit_d_f=[hit_d_f;idx_ac(j)-cmd_id+1];
                else
                    hit_size_p=hit_size_p+end_lba-traces(idx_ac(j), 1)+1;
                    hit_d_p=[hit_d_p;idx_ac(j)-cmd_id+1];
                end
            else
                break;
            end
        end
        
    else
        idx2=find( (END_LBA(cmd_id+1:total_cmd)>= start_lba)  & ( END_LBA(cmd_id+1:total_cmd)<=end_lba),1,'first');
        idx2_ac=cmd_id+idx2;
        if ~isempty(idx2) % the end_lba falls into the range
            size_idx2_ac=size(idx2_ac,1);
            hit_size_p=0;
            hit_d_p=[];
            for j=1:size_idx2_ac
                if traces(idx2_ac(j),3)==1 % if the hit command is read
                    hit_type=1; % partial hit only;
                    hit_d_p=[hit_d_p;idx2_ac(j)-cmd_id+1];
                    hit_size_p=hit_size_p+END_LBA(idx2_ac(j))-start_lba+1;
                else
                    break;
                end
            end
        end
    end
    
    if ~isempty(hit_d_p)
%         idx=find(hit_d_p<=0);
%         if ~isempty(idx)
%             'debug'
%         end
        stack_dist_record_partial(hit_d_p,1)=stack_dist_record_partial(hit_d_p,1)+1;
        stack_dist_record_partial(hit_d_p,2)=stack_dist_record_partial(hit_d_p,2)+hit_size_p;
    end
    
    if ~isempty(hit_d_f)
        stack_dist_record_full(hit_d_f,1)=stack_dist_record_full(hit_d_f,1)+1;
        stack_dist_record_full(hit_d_f,2)=stack_dist_record_full(hit_d_f,2)+hit_size_f;
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
toc