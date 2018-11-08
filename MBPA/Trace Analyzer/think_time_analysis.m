function [Think_Time_Array,think_time_ave,Time_dist]=think_time_analysis(PcMark_trace,time_set, time_interval,options)
% this function is for pcmark trace
% Think_Time_Array: the distribution of think time interval
% Think_stat: large array of IOPS, size, throughput in each time interval;

time_set_interval=size(time_set,2)-1;
Think_Time_Array=zeros(1,time_set_interval);


%req_size=PcMark_trace(:,3);
%acc_code=PcMark_trace(:,2); % write 1; read 0
%time_ac=PcMark_trace(:,1);
[total_cmd,b]=size(PcMark_trace);
%write_cmd=sum(acc_code);
%Total_Cmd(:)=[total_cmd, write_cmd, total_cmd-write_cmd];
IOPS_array=total_cmd/(PcMark_trace(total_cmd,1)-PcMark_trace(1,1));
Think_Time_List=PcMark_trace(2:total_cmd,1)-PcMark_trace(1:total_cmd-1,1);
think_time_ave= [mean(Think_Time_List), std(Think_Time_List)];
total_run_time=PcMark_trace(total_cmd,1)-PcMark_trace(1,1);
total_time=24*60^2;
%start_from_0=1;
if options.start_from_0
    tot_dis=ceil(total_time/time_interval);
    %curr_time=0;
else
    tot_dis=ceil(total_run_time/time_interval);
    %curr_time=PcMark_trace(1,1);
end
Time_dist=zeros(tot_dis,9);
%PcMark_trace(1,1);

for j=1:time_set_interval
    index0= find((Think_Time_List>time_set(j)) & (Think_Time_List<=time_set(j+1)));
    Think_Time_Array(j)=size(index0,1);
end
Think_Time_Array=Think_Time_Array/total_cmd;

%%%
for i=1:tot_dis
    idx_all=find(PcMark_trace(:,1)>=(i-1)*time_interval & PcMark_trace(:,1)<(i)*time_interval);
    if ~isempty(idx_all)
        Time_dist(i,1)=size(idx_all,1)/time_interval;
        Time_dist(i,4)=mean(PcMark_trace(idx_all,3));
        %Time_dist(i,7)=Time_dist(i,1)*Time_dist(i,4);
        temp_trace=PcMark_trace(idx_all,:);
        idx_read=find(temp_trace(:,2)==0);
        idx_write=find(temp_trace(:,2)==1);
        if ~isempty(idx_read)
            Time_dist(i,2)=size(idx_read,1)/time_interval;
            Time_dist(i,5)=mean(temp_trace(idx_read,3));
        end
        if ~isempty(idx_write)
            Time_dist(i,3)=size(idx_write,1)/time_interval;
            Time_dist(i,6)=mean(temp_trace(idx_write,3));
        end
    end
end

Time_dist(:,7)=Time_dist(:,1).*Time_dist(:,4);
Time_dist(:,8)=Time_dist(:,2).*Time_dist(:,5);
Time_dist(:,9)=Time_dist(:,3).*Time_dist(:,6);



