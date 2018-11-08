function [lists_action,lists_cmd]=blktrace_parser(filename)
% 
% Due to the merge of the sequential requests, the block size of the first
% request may be changed. so if the LBA is found for "C" action, but the request size is
% different, we should check if the it belongs to a sequential stream; if
% so, we use it as the request completion time.
% this short version only parse C/D IO events to the disk. The full version
% shall contain all other events. However, we didn't do that. instead, we
% can use the "btt" tool.
% this file can be used as either a function or script. 
% 
% input:
% filename: the blkparse parsed txt file     
% output:
% lists_action: the event arrival time; we predefine 7 events in the array; however, only D/C at 6/7 columns are actually used.     
% Author: jun.xu99@gmail.com

[pathstr,name,ext] = fileparts(filename);
fid=fopen(filename);
tline=fgetl(fid);
lines=40000;
inc_con=20000;

% initialize lines events; when not enough, the whole array size will be increased another inc_con rows.
lists_action=zeros(lines,7); % A65 Q81  M77 G71 I73 D68 C67  % time value, must be double
% action follows either one: 1)  A65 --> Q81 --> M77 or 2)A65 --> Q81 -->
% G71 --> I73 --> D68 --> C67 or 2)A65 --> Q81 -->
% F70 --> D68 --> C67
lists_cmd=zeros(lines,3); % LBA + size+ action (0 write, 1 read)
% W87 R82 B66 S83
lists_merge=zeros(10000,4); % LBA, original size, merged size, index in lists_cmds; 
non_size_con=0;
list_non_size=zeros(1000,4);

con0=0; % total request number
cmd_line=0; % total lines/events in the file
complete_idx=0; % used to index the search range
actual_com_con=0; % actual completed request number
merge_con=0;
tic;

while ischar(tline)
    
    action=0;flag=-1;
    cmd_line=cmd_line+1;

    if strcmp(tline(2:6),'Reads')
        break
    end
    
    str_len=size(tline,2);
    if str_len<20
        break
    elseif str_len<50
        tline=fgets(fid);
        continue;
    end
    [scan_value,tmp1,tmp2,scan_con0]=sscanf(tline,'  %d,%d   %d        %d     %f     %d  %c   %s',[8,1]);
    if (abs(scan_value(8,1)-87)==0)
        flag=0;
    elseif(abs(scan_value(8,1)-82)<0.00001) % only consider Read and write commands
        flag=1;
    else
        tline=fgetl(fid);
        continue;
    end
    
    action=0;
    if flag>=0
        if abs(scan_value(7,1)-68)<0.00001
            action=6;
        elseif abs(scan_value(7,1)-67)<0.00001
            action=7;
        end
    end
    
    if (action>=6)
        %scan_value=sscanf(tline,'  %d,%d   %d        %d     %f     %d  %s   %s %d + %d %*s');
        %         lba=scan_value(row1-1);
        %         req_size=scan_value(row1);
        new_scan_value=sscanf(tline(scan_con0:str_len), '%ld + %d');
        % there are some cases that the request size is not included in the
        % stream (strange!),e.g., ' 8,16   5      324     3.832956675     0
        % C  WS 1950885322 [0]' & in the 804th line from 10.4.43.147 trace & ' 8,16   0  6432049 17698.171558523     4  C   R (12 00 00 00 24 00 ..) [0]'.
        % for this case, we simply record it as an exceptation, and
        % continue;
        if isempty(new_scan_value)
            tline=fgetl(fid);
            continue
        end
        
        if size(new_scan_value,1)<2
            non_size_con=non_size_con+1;
            list_non_size(non_size_con,1)=new_scan_value(1);
            % only process if action ==7
            % if action==7
            tline=fgetl(fid);
            continue;
        end
        %row1=size(new_scan_value,1);
        lba=new_scan_value(1);
        req_size=new_scan_value(2);
        
        % due to trunked trace, the first several events may be 'D,C'
        % events of the previous trunked trace.
        
        if action==6 % add a new IO request to lists_cmd
            con0=con0+1;
            if mod(con0,2000)==1
                %disp(['Total processed requests: ', int2str(con0)])
                disp(['Finished parsing ', int2str(con0), ' requests from ', int2str(cmd_line), ' lines/commands. '])
                disp(['The last processed timestamp is ', num2str(scan_value(5,1))])
            end
            lists_cmd(con0,1:3)=([lba, req_size, flag]);
            lists_action(con0,action)=scan_value(5,1);
        elseif con0>0 % action 7
            % find the index in lists_cmd first
            idx=find(lists_cmd(complete_idx+1:con0,1)==lba);            
           
            % in order to reduce the search range; this line costs the most
            % of the computing time; how to reduce it?
            if ~isempty(idx)
                % found the same LBA: there are many cases. 1) idex only one -->
                % just fill it. 2) idx more than one --> 2.1) if the action
                % =2/3/4, find the first corresponding action's  =0; 2.2)
                % if action =5/6/7, find the first corresponding action = 0
                % && the corresponding action 3's value =0 and action 4's
                % value ~=0
                
                idx2=find(lists_cmd((complete_idx)+idx,2)==req_size);
                if ~isempty(idx2) % assume find if lba and size are the same; don't compare flag here.
                    idx3=(complete_idx)+idx(idx2);
                    idx3_size=size(idx3,1);
                    % it is possible that two or more requests are close
                    % enough so that the first is not complete. so we
                    % cannot simply choose the last one to fill. need to
                    % check if the first is filled or the first one is a merge access.
                    if idx3_size>1
                        
                        act_idx=find((abs(lists_action(idx3,action))<0.0000001) & (abs(lists_action(idx3,7))<0.0000001),1,'first'); % as action 3 contradicts action 4, so we can skip one condition.
                        lists_action(idx3(act_idx),action)=scan_value(5,1);
                        
                    else
                        lists_action(idx3(1),action)=scan_value(5,1);
                    end
                    
                    
                    actual_com_con=actual_com_con+1;
                    
                else  % if ~isempty(idx2) % request size is different, may due to merge
                    
                    idx3=complete_idx+idx;
                    
                    act_idx=find((abs(lists_action(idx3,action))<0.0000001), 1,'first'); % as action 3 contradicts action 4, so we can skip one condition.
                    if isempty(act_idx)
                        tline=fgetl(fid);
                        continue
                    end
                    lists_action(idx3(act_idx),action)=scan_value(5,1);

                    actual_com_con=actual_com_con+1;
                    merge_con=merge_con+1;
                    idx4=idx3(act_idx);
                    lists_merge(merge_con,:)=[lba,lists_cmd(idx3(act_idx),2),req_size,idx4];
                    lists_cmd(idx3(act_idx),2)=req_size;
                    
                end %if ~isempty(idx2)
            end % if ~isempty(idx)
        end %if action==1
    else
        tline=fgetl(fid);
        continue;
    end %if action>=6
    
    tline=fgetl(fid);
    if con0>lines
        toc
        lists_action=[lists_action;zeros(inc_con,7)];
        lists_cmd=[lists_cmd;zeros(inc_con,3)];
        
        lines=lines+inc_con;
        tic
    end
    
    % try to reduce the "find" range by removing the completed
    % the first not completed non-merged commands in the list
    if con0-complete_idx>1000
        idx_non_merge=find(abs(lists_action(complete_idx+1:con0,3))<0.000001);
        idx_non_merge_ac=idx_non_merge+complete_idx; % actual index in lists_action
        idx_new_start=find(abs(lists_action(idx_non_merge_ac,7))<0.000001,1,'first');
        if ~isempty(idx_new_start)
            complete_idx=idx_non_merge_ac(idx_new_start)-1;
        end
    end
    
    
    
    lba=0;
end
fclose(fid)

lists_action=lists_action(1:con0,:);
lists_cmd=lists_cmd(1:con0,:);

idx_new=find(abs(lists_action(1:con0,7))>0.000000001);

var_name=['orignal_request',name,ext,'.mat'];
save(var_name);

lists_action=lists_action(idx_new,:);
lists_cmd=lists_cmd(idx_new,:);
con0=size(lists_cmd,1);
lists_merge=lists_merge(1:merge_con,:);

for i=1:6
    idx=find(abs(lists_action(:,i))<0.000000001);
    if ~isempty(idx)
        disp(['some requests is not parsed completely in ', int2str(i)]);
    end
end

var_name=['merged_request',name,ext,'.mat'];
save(var_name,'lists_cmd', 'lists_action', 'filename');
