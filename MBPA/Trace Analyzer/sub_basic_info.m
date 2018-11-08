function basic_info=sub_basic_info(lists_action,lists_cmd,options)
% basic_info=sub_basic_info(lists_action,lists_cmd,options)
% get the very basic information of the trace
%
% input:
%   lists_action: nx2 event timing array (1: arrival time; 2: completion time)
%   lists_cmd: nx3 event array (1: first lba, 2: request size, 3: access mode)
%
% output:
%   basic_info: basic information contains some fields, e.g., read/write
%   numbers/total request sizes/average size/througput/iops, total/effective
%   trace time/length, and etc
%
% Author: jun.xu99@gmail.com

[a,b]=size(lists_action);
idx_read=find(lists_cmd(:,3)==1);
idx_write=find(lists_cmd(:,3)==0);

basic_info.cmd_num_read=size(idx_read,1);
basic_info.cmd_num_write=size(idx_write,1);

basic_info.max_time=lists_action(a,1);
basic_info.eff_time=lists_action(a,1)-lists_action(1,1);

basic_info.iops_read=basic_info.cmd_num_read/basic_info.eff_time;
basic_info.iops_write=basic_info.cmd_num_write/basic_info.eff_time;

basic_info.total_size_read=sum(lists_cmd(idx_read,2));
basic_info.total_size_write=sum(lists_cmd(idx_write,2));

basic_info.ave_size_read=basic_info.total_size_read/basic_info.cmd_num_read;
basic_info.ave_size_write=basic_info.total_size_write/basic_info.cmd_num_write;

basic_info.ave_tp_read=basic_info.total_size_read/basic_info.eff_time*512/1024^2;
basic_info.ave_tp_write=basic_info.total_size_write/basic_info.eff_time*512/1024^2;