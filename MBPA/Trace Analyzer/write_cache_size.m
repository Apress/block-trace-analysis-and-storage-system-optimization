% this program finds the total cache size required to hold write requests
%%JUN, see comments from read_cache_size.m file
%Input: 
%Output:
total_req=size(lists_cmd,1);

size_set=100000;
LBA_set=zeros(size_set,2);
post_fetch_size=0;

write_idx=find(lists_cmd(:,3)==0);
total_write_req=size(write_idx,1);
record=zeros(total_write_req,1);

total_request_size=0;
total_lba_size=0;
cur_idx=0;
hit_part_num=0;
hit_full_num=0;
write_count=0;
cache_size=0;
h=waitbar(0,'starting');
for j=1:total_write_req
    i=write_idx(j);
    first_lba=lists_cmd(i,1);
    last_lba=lists_cmd(i,1)+lists_cmd(i,2)-1;
    idx1=find((LBA_set(1:cur_idx,1)>=first_lba) &(LBA_set(1:cur_idx,1)<=last_lba));
    idx2=find((LBA_set(1:cur_idx,2)>=first_lba) &(LBA_set(1:cur_idx,2)<=last_lba));
    if isempty(idx1)
        if isempty(idx2)
            % add the new entry to LBA_set;
            cur_idx=cur_idx+1;
            LBA_set(cur_idx,:)=[first_lba last_lba+post_fetch_size];
            total_lba_size=total_lba_size+lists_cmd(i,2);
            cache_size=cache_size+lists_cmd(i,2)+post_fetch_size;
        else
            cache_size=cache_size+last_lba-LBA_set(idx2(1),2)+post_fetch_size;
            LBA_set(idx2(1),2)=last_lba+post_fetch_size;
        end
    else
        cache_size=cache_size+LBA_set(idx1(1),1)-first_lba;
        LBA_set(idx1(1),1)=first_lba;
    end
    
    record(j)=cache_size;    
    if mod(i,2000)==0
        waitbar(i/total_req);
    end
end

close(h);

plot(record'*512/1024^3,(1:total_write_req)/total_write_req);
xlabel('cache size (GB)');
ylabel('write command ratio')
